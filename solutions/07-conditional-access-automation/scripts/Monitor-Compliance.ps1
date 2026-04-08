#Requires -Version 7.0
<#
.SYNOPSIS
Monitors Conditional Access Policy compliance posture for Copilot.
.DESCRIPTION
Validates Conditional Access tier settings against the selected governance tier, detects drift from the approved baseline, checks for expired exceptions, and returns structured compliance findings for controls 2.3, 2.6, and 2.9.
.PARAMETER ConfigurationTier
Specifies the governance tier to validate. Valid values are baseline, recommended, and regulated.
.PARAMETER BaselinePath
Specifies the approved baseline JSON path to compare against the current expected policy state.
.PARAMETER ExceptionRegisterPath
Specifies the exception register JSON path that contains approved access overrides.
.PARAMETER OutputPath
Specifies where compliance output and drift summaries are written.
.PARAMETER AlertOnDrift
Emits a warning when baseline or drift findings are detected.
.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier recommended -BaselinePath .\artifacts\recommended\current-policy-baseline.json -ExceptionRegisterPath .\artifacts\recommended\access-exception-register.json -AlertOnDrift
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$BaselinePath = '',

    [Parameter()]
    [string]$ExceptionRegisterPath = '',

    [Parameter()]
    [string]$OutputPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts'),

    [Parameter()]
    [switch]$AlertOnDrift
)

Set-StrictMode -Version Latest

$solutionRoot = Split-Path $PSScriptRoot -Parent

# NOTE: Read-JsonFile, Write-JsonFile, Resolve-ConfiguredPath, Merge-Configuration, and
# New-PolicyTemplate are duplicated across Deploy-Solution.ps1, Monitor-Compliance.ps1,
# and Export-Evidence.ps1. Changes to shared logic must be applied to all three files.
# See docs\architecture.md for details on this acknowledged tech debt.
function Read-JsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw "Required file was not found: $Path"
    }

    return (Get-Content -Path $Path -Raw | ConvertFrom-Json -AsHashtable)
}

function Write-JsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [object]$InputObject
    )

    $directory = Split-Path -Path $Path -Parent
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        $null = New-Item -ItemType Directory -Path $directory -Force
    }

    $InputObject | ConvertTo-Json -Depth 12 | Set-Content -Path $Path -Encoding utf8
}

function Resolve-ConfiguredPath {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ConfiguredPath,

        [Parameter(Mandatory)]
        [string]$BasePath,

        [Parameter(Mandatory)]
        [string]$FallbackLeaf
    )

    if ([string]::IsNullOrWhiteSpace($ConfiguredPath)) {
        return (Join-Path $BasePath $FallbackLeaf)
    }

    if ([IO.Path]::IsPathRooted($ConfiguredPath)) {
        return $ConfiguredPath
    }

    $leaf = Split-Path -Path $ConfiguredPath -Leaf
    if ([string]::IsNullOrWhiteSpace($leaf)) {
        $leaf = $FallbackLeaf
    }

    return (Join-Path $BasePath $leaf)
}

function Test-KeyPresent {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Key
    )

    if ($null -eq $InputObject) {
        return $false
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        return $InputObject.Contains($Key)
    }

    return ($null -ne $InputObject.PSObject.Properties[$Key])
}

function Get-KeyValue {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Key
    )

    if (-not (Test-KeyPresent -InputObject $InputObject -Key $Key)) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        return $InputObject[$Key]
    }

    return $InputObject.$Key
}

function Merge-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$DefaultConfig,

        [Parameter(Mandatory)]
        [hashtable]$TierConfig
    )

    $copilotAppIds = if ($TierConfig.ContainsKey('copilotAppIds') -and @($TierConfig.copilotAppIds).Count -gt 0) {
        @($TierConfig.copilotAppIds)
    }
    else {
        @($DefaultConfig.defaults.copilotAppIds)
    }

    $baselineStoragePath = if ($TierConfig.ContainsKey('baselineStoragePath')) {
        [string]$TierConfig.baselineStoragePath
    }
    else {
        [string]$DefaultConfig.defaults.baselineStoragePath
    }

    $exceptionRegisterPath = if ($TierConfig.ContainsKey('exceptionRegisterPath')) {
        [string]$TierConfig.exceptionRegisterPath
    }
    else {
        [string]$DefaultConfig.defaults.exceptionRegisterPath
    }

    $namedLocations = if ($TierConfig.ContainsKey('namedLocations')) {
        @($TierConfig.namedLocations)
    }
    else {
        @()
    }

    return [ordered]@{
        solution = $DefaultConfig.solution
        displayName = $DefaultConfig.displayName
        solutionCode = $DefaultConfig.solutionCode
        controls = @($DefaultConfig.controls)
        tier = $TierConfig.tier
        copilotAppIds = $copilotAppIds
        riskTiers = $TierConfig.riskTiers
        driftDetectionEnabled = [bool]$TierConfig.driftDetectionEnabled
        driftCheckFrequency = [string]$TierConfig.driftCheckFrequency
        notificationMode = [string]$TierConfig.notificationMode
        evidenceRetentionDays = [int]$TierConfig.evidenceRetentionDays
        exceptionApproval = $TierConfig.exceptionApproval
        baselineStoragePath = $baselineStoragePath
        exceptionRegisterPath = $exceptionRegisterPath
        policyNamingConvention = [string]$DefaultConfig.defaults.policyNamingConvention
        namedLocations = $namedLocations
        blockLegacyAuth = if ($TierConfig.ContainsKey('blockLegacyAuth')) { [bool]$TierConfig.blockLegacyAuth } else { $false }
        blockUnknownDeviceStates = if ($TierConfig.ContainsKey('blockUnknownDeviceStates')) { [bool]$TierConfig.blockUnknownDeviceStates } else { $false }
    }
}

function New-PolicyTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RiskTierName,

        [Parameter(Mandatory)]
        [hashtable]$RiskTierSettings,

        [Parameter(Mandatory)]
        [hashtable]$Configuration
    )

    $displayTier = (Get-Culture).TextInfo.ToTitleCase($RiskTierName)
    $purpose = switch ($RiskTierName) {
        'low' { 'Access' }
        'medium' { 'Elevated' }
        'high' { 'Restricted' }
        default { 'Access' }
    }

    $policyName = $Configuration.policyNamingConvention -replace '\{Tier\}', $displayTier
    $policyName = $policyName -replace '\{Purpose\}', $purpose

    $grantControls = New-Object System.Collections.Generic.List[string]
    if ($RiskTierSettings.mfaRequired) {
        $null = $grantControls.Add('mfa')
    }

    if ($RiskTierSettings.compliantDevice) {
        $null = $grantControls.Add('compliantDevice')
    }

    $namedLocations = if ($RiskTierSettings.ContainsKey('namedLocations') -and @($RiskTierSettings.namedLocations).Count -gt 0) {
        @($RiskTierSettings.namedLocations)
    }
    elseif (@($Configuration.namedLocations).Count -gt 0) {
        @($Configuration.namedLocations)
    }
    else {
        @('NamedLocationReviewRequired')
    }

    $conditions = [ordered]@{
        users = [ordered]@{
            includeUsers = @('All')
            excludeUsers = @()
        }
        applications = [ordered]@{
            includeApplications = @($Configuration.copilotAppIds)
            excludeApplications = @()
        }
        clientAppTypes = if ($Configuration.blockLegacyAuth) {
            @('browser', 'mobileAppsAndDesktopClients')
        }
        else {
            @('all')
        }
        signInRiskLevels = @()
        locations = [ordered]@{
            includeLocations = if ($RiskTierSettings.namedLocationRequired) { $namedLocations } else { @('All') }
            excludeLocations = if ($RiskTierSettings.namedLocationRequired) { @('AllTrusted') } else { @() }
        }
    }

    if ($Configuration.blockUnknownDeviceStates -or $RiskTierSettings.compliantDevice) {
        $filterRule = if ($Configuration.blockUnknownDeviceStates) {
            'device.isCompliant -eq True -or device.trustType -eq "ServerAD"'
        } else {
            'device.isCompliant -eq True'
        }
        $conditions.devices = [ordered]@{
            deviceFilter = [ordered]@{
                mode = 'include'
                rule = $filterRule
            }
        }
    }

    return [ordered]@{
        displayName = $policyName
        tier = $Configuration.tier
        riskTier = $RiskTierName
        targetedAppIds = @($Configuration.copilotAppIds)
        grantControls = [ordered]@{
            operator = if (@($grantControls).Count -gt 1) { 'AND' } else { 'OR' }
            builtInControls = @($grantControls)
        }
        conditions = $conditions
        sessionControls = [ordered]@{
            persistentBrowser = [ordered]@{
                mode = 'never'
                isEnabled = $true
            }
            signInFrequency = [ordered]@{
                value = if ($Configuration.tier -eq 'regulated') { 4 } elseif ($RiskTierName -eq 'high') { 8 } else { 12 }
                type = 'hours'
                isEnabled = $true
            }
        }
    }
}

function New-Finding {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [string]$Severity,

        [Parameter(Mandatory)]
        [string]$ControlId,

        [Parameter(Mandatory)]
        [string]$Category,

        [Parameter(Mandatory)]
        [string]$Description
    )

    return [pscustomobject]@{
        id = $Id
        severity = $Severity
        controlId = $ControlId
        category = $Category
        description = $Description
    }
}

function Get-ExpectedTierRules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    switch ($Tier) {
        'baseline' {
            return [ordered]@{
                riskTiers = [ordered]@{
                    low = @{ mfaRequired = $true; compliantDevice = $false; namedLocationRequired = $false }
                    medium = @{ mfaRequired = $true; compliantDevice = $false; namedLocationRequired = $false }
                    high = @{ mfaRequired = $true; compliantDevice = $false; namedLocationRequired = $false }
                }
                blockLegacyAuth = $false
                blockUnknownDeviceStates = $false
            }
        }
        'recommended' {
            return [ordered]@{
                riskTiers = [ordered]@{
                    low = @{ mfaRequired = $true; compliantDevice = $false; namedLocationRequired = $false }
                    medium = @{ mfaRequired = $true; compliantDevice = $true; namedLocationRequired = $true }
                    high = @{ mfaRequired = $true; compliantDevice = $true; namedLocationRequired = $true }
                }
                blockLegacyAuth = $false
                blockUnknownDeviceStates = $false
            }
        }
        'regulated' {
            return [ordered]@{
                riskTiers = [ordered]@{
                    low = @{ mfaRequired = $true; compliantDevice = $true; namedLocationRequired = $true }
                    medium = @{ mfaRequired = $true; compliantDevice = $true; namedLocationRequired = $true }
                    high = @{ mfaRequired = $true; compliantDevice = $true; namedLocationRequired = $true }
                }
                blockLegacyAuth = $true
                blockUnknownDeviceStates = $true
            }
        }
    }
}

function Test-TierConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,

        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$SelectedTier
    )

    $findings = New-Object System.Collections.Generic.List[object]
    $expectedRules = Get-ExpectedTierRules -Tier $SelectedTier

    foreach ($riskTierName in @('low', 'medium', 'high')) {
        $expected = $expectedRules.riskTiers[$riskTierName]
        $actual = $Configuration.riskTiers[$riskTierName]

        foreach ($propertyName in @('mfaRequired', 'compliantDevice', 'namedLocationRequired')) {
            if ([bool]$actual[$propertyName] -ne [bool]$expected[$propertyName]) {
                $controlId = if ($propertyName -eq 'compliantDevice') { '2.9' } else { '2.3' }
                $description = "Risk tier '$riskTierName' does not match the $SelectedTier requirement for $propertyName."
                $findings.Add((New-Finding -Id ("tier-{0}-{1}" -f $riskTierName, $propertyName) -Severity 'medium' -ControlId $controlId -Category 'Configuration' -Description $description))
            }
        }

        $namedLocations = @()
        if (Test-KeyPresent -InputObject $actual -Key 'namedLocations') {
            $namedLocations = @(Get-KeyValue -InputObject $actual -Key 'namedLocations')
        }
        if ($expected.namedLocationRequired -and @($namedLocations).Count -eq 0) {
            $findings.Add((New-Finding -Id ("tier-{0}-namedlocations" -f $riskTierName) -Severity 'medium' -ControlId '2.3' -Category 'Configuration' -Description ("Risk tier '{0}' requires named locations but none are defined." -f $riskTierName)))
        }
    }

    if ([bool]$Configuration.blockLegacyAuth -ne [bool]$expectedRules.blockLegacyAuth) {
        $findings.Add((New-Finding -Id 'legacy-auth-setting' -Severity 'medium' -ControlId '2.3' -Category 'Configuration' -Description 'Legacy authentication setting does not align to the selected tier.'))
    }

    if ([bool]$Configuration.blockUnknownDeviceStates -ne [bool]$expectedRules.blockUnknownDeviceStates) {
        $findings.Add((New-Finding -Id 'device-state-setting' -Severity 'medium' -ControlId '2.9' -Category 'Configuration' -Description 'Unknown device-state handling does not align to the selected tier.'))
    }

    return $findings
}

function ConvertTo-PolicyFingerprint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Policy
    )

    $grantControlObject = Get-KeyValue -InputObject $Policy -Key 'grantControls'
    $grantControls = if (Test-KeyPresent -InputObject $grantControlObject -Key 'builtInControls') {
        @(Get-KeyValue -InputObject $grantControlObject -Key 'builtInControls')
    }
    else {
        @()
    }

    $conditionsObject = Get-KeyValue -InputObject $Policy -Key 'conditions'
    $locationObject = Get-KeyValue -InputObject $conditionsObject -Key 'locations'
    $includeLocations = if (Test-KeyPresent -InputObject $locationObject -Key 'includeLocations') {
        @(Get-KeyValue -InputObject $locationObject -Key 'includeLocations')
    }
    else {
        @()
    }

    $devicesObject = Get-KeyValue -InputObject $conditionsObject -Key 'devices'
    $deviceFilterObject = Get-KeyValue -InputObject $devicesObject -Key 'deviceFilter'
    $deviceFilterRule = if (Test-KeyPresent -InputObject $deviceFilterObject -Key 'rule') {
        [string](Get-KeyValue -InputObject $deviceFilterObject -Key 'rule')
    }
    else {
        ''
    }

    return [ordered]@{
        riskTier = [string]$Policy.riskTier
        targetedAppIds = @($Policy.targetedAppIds | Sort-Object)
        grantControls = @($grantControls | Sort-Object)
        includeLocations = @($includeLocations | Sort-Object)
        blockUnknownDeviceStates = ($deviceFilterRule -match 'ServerAD')
    }
}

function Compare-BaselinePolicies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$ExpectedPolicies,

        [Parameter()]
        [object]$BaselineDocument
    )

    $findings = New-Object System.Collections.Generic.List[object]

    if ($null -eq $BaselineDocument) {
        $findings.Add((New-Finding -Id 'baseline-missing' -Severity 'medium' -ControlId '2.6' -Category 'Baseline' -Description 'Baseline snapshot not found. Capture a new approved Copilot Conditional Access baseline.'))
        return $findings
    }

    $baselinePolicies = @()
    if (Test-KeyPresent -InputObject $BaselineDocument -Key 'policies') {
        $baselinePolicies = @(Get-KeyValue -InputObject $BaselineDocument -Key 'policies')
    }
    elseif (Test-KeyPresent -InputObject $BaselineDocument -Key 'policyTemplates') {
        $baselinePolicies = @(Get-KeyValue -InputObject $BaselineDocument -Key 'policyTemplates')
    }
    elseif ($BaselineDocument -is [System.Collections.IEnumerable] -and $BaselineDocument -isnot [string]) {
        $baselinePolicies = @($BaselineDocument)
    }

    if (@($baselinePolicies).Count -eq 0) {
        $findings.Add((New-Finding -Id 'baseline-empty' -Severity 'medium' -ControlId '2.6' -Category 'Baseline' -Description 'Baseline snapshot does not contain Copilot Conditional Access policies.'))
        return $findings
    }

    if (@($baselinePolicies).Count -ne @($ExpectedPolicies).Count) {
        $findings.Add((New-Finding -Id 'drift-policy-count' -Severity 'medium' -ControlId '2.3' -Category 'Drift' -Description 'Baseline policy count does not match the expected Copilot policy count.'))
    }

    foreach ($expectedPolicy in $ExpectedPolicies) {
        $match = $baselinePolicies | Where-Object { [string]$_['riskTier'] -eq [string]$expectedPolicy.riskTier } | Select-Object -First 1
        if ($null -eq $match) {
            $findings.Add((New-Finding -Id ("drift-missing-{0}" -f $expectedPolicy.riskTier) -Severity 'high' -ControlId '2.3' -Category 'Drift' -Description ("Baseline is missing the '{0}' Copilot policy tier." -f $expectedPolicy.riskTier)))
            continue
        }

        $expectedFingerprint = ConvertTo-PolicyFingerprint -Policy $expectedPolicy | ConvertTo-Json -Depth 12 -Compress
        $baselineFingerprint = ConvertTo-PolicyFingerprint -Policy $match | ConvertTo-Json -Depth 12 -Compress
        if ($expectedFingerprint -ne $baselineFingerprint) {
            $findings.Add((New-Finding -Id ("drift-{0}" -f $expectedPolicy.riskTier) -Severity 'high' -ControlId '2.3' -Category 'Drift' -Description ("Baseline mismatch detected for the '{0}' risk-tier Copilot policy." -f $expectedPolicy.riskTier)))
        }
    }

    return $findings
}

function Get-ExceptionEntries {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object]$Register
    )

    if ($null -eq $Register) {
        return @()
    }

    if (Test-KeyPresent -InputObject $Register -Key 'exceptions') {
        return @(Get-KeyValue -InputObject $Register -Key 'exceptions')
    }

    if ($Register -is [System.Collections.IEnumerable] -and $Register -isnot [string]) {
        return @($Register)
    }

    return @()
}

$defaultConfigPath = Join-Path $solutionRoot 'config\default-config.json'
$tierConfigPath = Join-Path $solutionRoot ("config\{0}.json" -f $ConfigurationTier)

$defaultConfig = Read-JsonFile -Path $defaultConfigPath
$tierConfig = Read-JsonFile -Path $tierConfigPath
$config = Merge-Configuration -DefaultConfig $defaultConfig -TierConfig $tierConfig

$resolvedBaselinePath = if ([string]::IsNullOrWhiteSpace($BaselinePath)) {
    Resolve-ConfiguredPath -ConfiguredPath $config.baselineStoragePath -BasePath $OutputPath -FallbackLeaf 'current-policy-baseline.json'
}
else {
    Resolve-ConfiguredPath -ConfiguredPath $BaselinePath -BasePath $OutputPath -FallbackLeaf 'current-policy-baseline.json'
}

$resolvedExceptionRegisterPath = if ([string]::IsNullOrWhiteSpace($ExceptionRegisterPath)) {
    Resolve-ConfiguredPath -ConfiguredPath $config.exceptionRegisterPath -BasePath $OutputPath -FallbackLeaf 'access-exception-register.json'
}
else {
    Resolve-ConfiguredPath -ConfiguredPath $ExceptionRegisterPath -BasePath $OutputPath -FallbackLeaf 'access-exception-register.json'
}

$expectedPolicies = foreach ($riskTierName in @('low', 'medium', 'high')) {
    New-PolicyTemplate -RiskTierName $riskTierName -RiskTierSettings $config.riskTiers[$riskTierName] -Configuration $config
}

$findings = New-Object System.Collections.Generic.List[object]

$requiredAppIds = @(
    'fb8d773d-7ef8-4ec0-a117-179f88add510',
    '7df0a125-d3be-4c96-aa54-591f83ff541c'
)
foreach ($requiredAppId in $requiredAppIds) {
    if (@($config.copilotAppIds) -notcontains $requiredAppId) {
        $findings.Add((New-Finding -Id ("app-{0}" -f $requiredAppId) -Severity 'high' -ControlId '2.6' -Category 'Configuration' -Description ("Required Copilot application ID {0} is missing from configuration." -f $requiredAppId)))
    }
}

foreach ($tierFinding in (Test-TierConfiguration -Configuration $config -SelectedTier $ConfigurationTier)) {
    $findings.Add($tierFinding)
}

$baselineDocument = if (Test-Path -Path $resolvedBaselinePath) {
    Read-JsonFile -Path $resolvedBaselinePath
}
else {
    $null
}
foreach ($baselineFinding in (Compare-BaselinePolicies -ExpectedPolicies $expectedPolicies -BaselineDocument $baselineDocument)) {
    $findings.Add($baselineFinding)
}

$exceptionRegisterExists = Test-Path -Path $resolvedExceptionRegisterPath
$exceptionRegisterDocument = if ($exceptionRegisterExists) {
    Read-JsonFile -Path $resolvedExceptionRegisterPath
}
else {
    $null
}

if (-not $exceptionRegisterExists) {
    $findings.Add((New-Finding -Id 'exception-register-missing' -Severity 'medium' -ControlId '2.6' -Category 'Exception' -Description 'Exception register not found. Initialize the approved access-exception register before production use.'))
}

$exceptionEntries = Get-ExceptionEntries -Register $exceptionRegisterDocument
$expiredExceptions = New-Object System.Collections.Generic.List[object]
$today = (Get-Date).Date
foreach ($exceptionEntry in $exceptionEntries) {
    $expiryValue = if (Test-KeyPresent -InputObject $exceptionEntry -Key 'expiryDate') {
        [string](Get-KeyValue -InputObject $exceptionEntry -Key 'expiryDate')
    }
    else {
        ''
    }

    if ([string]::IsNullOrWhiteSpace($expiryValue)) {
        continue
    }

    try {
        $expiryDate = [datetime]$expiryValue
        if ($expiryDate.Date -lt $today) {
            $exceptionId = if (Test-KeyPresent -InputObject $exceptionEntry -Key 'id') { [string](Get-KeyValue -InputObject $exceptionEntry -Key 'id') } else { 'unidentified-exception' }
            $expiredExceptions.Add([pscustomobject]@{
                id = $exceptionId
                approver = if (Test-KeyPresent -InputObject $exceptionEntry -Key 'approver') { [string](Get-KeyValue -InputObject $exceptionEntry -Key 'approver') } else { 'unknown' }
                expiryDate = $expiryDate.ToString('o')
                businessJustification = if (Test-KeyPresent -InputObject $exceptionEntry -Key 'businessJustification') { [string](Get-KeyValue -InputObject $exceptionEntry -Key 'businessJustification') } else { '' }
            })
            $findings.Add((New-Finding -Id ("expired-{0}" -f $exceptionId) -Severity 'medium' -ControlId '2.6' -Category 'Exception' -Description ("Exception '{0}' is expired and should be reviewed or closed." -f $exceptionId)))
        }
    }
    catch {
        $findings.Add((New-Finding -Id 'exception-expiry-invalid' -Severity 'low' -ControlId '2.6' -Category 'Exception' -Description 'One or more exception entries contain an invalid expiryDate value.'))
    }
}

$driftFindings = @($findings | Where-Object { $_.category -in @('Baseline', 'Drift') })

$control23Status = if ((@($findings | Where-Object { $_.controlId -eq '2.3' }).Count) -gt 0) { 'partial' } else { 'implemented' }
$control26Status = if ((@($findings | Where-Object { $_.controlId -eq '2.6' }).Count) -gt 0) { 'partial' } else { 'implemented' }
$control29Status = if ($ConfigurationTier -eq 'baseline') { 'partial' } elseif ((@($findings | Where-Object { $_.controlId -eq '2.9' }).Count) -gt 0) { 'partial' } else { 'implemented' }

$controls = @(
    [pscustomobject]@{ controlId = '2.3'; status = $control23Status; notes = 'Copilot access controls, MFA requirements, named locations, and baseline drift review.' },
    [pscustomobject]@{ controlId = '2.6'; status = $control26Status; notes = 'Policy change monitoring, exception governance, and approved override tracking.' },
    [pscustomobject]@{ controlId = '2.9'; status = $control29Status; notes = 'Compliant-device and device-state enforcement for Copilot sessions.' }
)

$overallStatus = if (@($controls | Where-Object { $_.status -ne 'implemented' }).Count -gt 0) { 'partial' } else { 'implemented' }
$controlsArray = @($controls | ForEach-Object { $_ })
$findingsArray = @($findings | ForEach-Object { $_ })

$null = New-Item -ItemType Directory -Path $OutputPath -Force
$driftSummaryPath = Join-Path $OutputPath 'drift-alert-summary.json'
$compliancePath = Join-Path $OutputPath 'compliance-status.json'

$driftSummary = [ordered]@{
    solution = $config.solution
    solutionCode = $config.solutionCode
    configurationTier = $ConfigurationTier
    generatedAt = (Get-Date).ToString('o')
    driftDetected = (@($driftFindings).Count -gt 0)
    changeCount = @($driftFindings).Count
    changes = @(
        foreach ($finding in $driftFindings) {
            [pscustomobject]@{
                id = $finding.id
                severity = $finding.severity
                controlId = $finding.controlId
                changeDescription = $finding.description
            }
        }
    )
}
Write-JsonFile -Path $driftSummaryPath -InputObject $driftSummary

$result = [ordered]@{}
$result['Solution'] = $config.displayName
$result['SolutionCode'] = $config.solutionCode
$result['ConfigurationTier'] = $ConfigurationTier
$result['CheckedAt'] = (Get-Date).ToString('o')
$result['OverallStatus'] = $overallStatus
$result['FindingCount'] = [int]$findings.Count
$result['ExpiredExceptionCount'] = [int]$expiredExceptions.Count
$result['DriftFindingCount'] = [int]$driftFindings.Count
$result['BaselinePath'] = $resolvedBaselinePath
$result['ExceptionRegisterPath'] = $resolvedExceptionRegisterPath
$result['Controls'] = $controlsArray
$result['Findings'] = $findingsArray
Write-JsonFile -Path $compliancePath -InputObject $result

if ($AlertOnDrift -and @($driftFindings).Count -gt 0) {
    Write-Warning ("{0} drift-related findings detected for Copilot Conditional Access." -f @($driftFindings).Count)
}

[pscustomobject]$result


