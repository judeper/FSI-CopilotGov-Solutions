#Requires -Version 7.0
<#
.SYNOPSIS
Exports Conditional Access Policy evidence package.
.DESCRIPTION
Assembles ca-policy-state, drift-alert-summary, and access-exception-register artifacts, writes SHA-256 companions, and publishes the shared evidence package by calling Export-SolutionEvidencePackage from the shared module.
.PARAMETER ConfigurationTier
Specifies the governance tier to export. Valid values are baseline, recommended, and regulated.
.PARAMETER OutputPath
Specifies where evidence artifacts and the shared evidence package are written.
.PARAMETER BaselinePath
Specifies the approved baseline JSON path to use when building the policy-state artifact.
.PARAMETER ExceptionRegisterPath
Specifies the exception register JSON path to use when building the exception artifact.
.PARAMETER PeriodStart
Optional reporting period start date written into the evidence package metadata.
.PARAMETER PeriodEnd
Optional reporting period end date written into the evidence package metadata.
.EXAMPLE
.\Export-Evidence.ps1 -ConfigurationTier regulated -OutputPath .\artifacts\regulated -BaselinePath .\artifacts\regulated\current-policy-baseline.json -ExceptionRegisterPath .\artifacts\regulated\access-exception-register.json
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts'),

    [Parameter()]
    [string]$BaselinePath = '',

    [Parameter()]
    [string]$ExceptionRegisterPath = '',

    [Parameter()]
    [datetime]$PeriodStart,

    [Parameter()]
    [datetime]$PeriodEnd
)

Set-StrictMode -Version Latest

if ($PSBoundParameters.ContainsKey('PeriodStart') -and $PSBoundParameters.ContainsKey('PeriodEnd') -and $PeriodEnd -lt $PeriodStart) {
    throw 'PeriodEnd must be greater than or equal to PeriodStart.'
}

$solutionRoot = Split-Path $PSScriptRoot -Parent
$repoRoot = Resolve-Path (Join-Path $solutionRoot '..\..')
# NOTE: The external module import below requires the parent repository structure to be
# intact. See docs\prerequisites.md for details on this dependency.
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

# NOTE: Read-JsonFile, Resolve-ConfiguredPath, Merge-Configuration, and New-PolicyTemplate
# are duplicated across Deploy-Solution.ps1, Monitor-Compliance.ps1, and Export-Evidence.ps1.
# Changes to shared logic must be applied to all three files.
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

    $namedLocationIds = if ($TierConfig.ContainsKey('namedLocationIds')) {
        @($TierConfig.namedLocationIds)
    }
    else {
        @()
    }

    $namedLocationLabels = if ($TierConfig.ContainsKey('namedLocationLabels')) {
        @($TierConfig.namedLocationLabels)
    }
    elseif ($TierConfig.ContainsKey('namedLocations')) {
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
        baselineStoragePath = $baselineStoragePath
        exceptionRegisterPath = $exceptionRegisterPath
        policyNamingConvention = [string]$DefaultConfig.defaults.policyNamingConvention
        namedLocations = $namedLocationIds
        namedLocationIds = $namedLocationIds
        namedLocationLabels = $namedLocationLabels
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

    $namedLocationIds = if ($RiskTierSettings.ContainsKey('namedLocationIds') -and @($RiskTierSettings.namedLocationIds).Count -gt 0) {
        @($RiskTierSettings.namedLocationIds)
    }
    elseif ($Configuration.ContainsKey('namedLocationIds') -and @($Configuration.namedLocationIds).Count -gt 0) {
        @($Configuration.namedLocationIds)
    }
    else {
        @()
    }

    $namedLocationLabels = if ($RiskTierSettings.ContainsKey('namedLocationLabels') -and @($RiskTierSettings.namedLocationLabels).Count -gt 0) {
        @($RiskTierSettings.namedLocationLabels)
    }
    elseif ($Configuration.ContainsKey('namedLocationLabels') -and @($Configuration.namedLocationLabels).Count -gt 0) {
        @($Configuration.namedLocationLabels)
    }
    else {
        @()
    }

    $requiresTenantNamedLocationIds = [bool]$RiskTierSettings.namedLocationRequired -and @($namedLocationIds).Count -eq 0
    $includeLocations = if ($RiskTierSettings.namedLocationRequired) {
        if (@($namedLocationIds).Count -gt 0) { @($namedLocationIds) } else { @() }
    }
    else {
        @('All')
    }

    $excludeLocations = if ($RiskTierSettings.namedLocationRequired -and @($namedLocationIds).Count -gt 0) {
        @('AllTrusted')
    }
    else {
        @()
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
        clientAppTypes = @('all')
        signInRiskLevels = @()
        locations = [ordered]@{
            includeLocations = @($includeLocations)
            excludeLocations = @($excludeLocations)
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
        namedLocationIds = @($namedLocationIds)
        namedLocationLabels = @($namedLocationLabels)
        requiresTenantNamedLocationIds = $requiresTenantNamedLocationIds
        manualReviewRequired = $requiresTenantNamedLocationIds
        deploymentGuidance = if ($requiresTenantNamedLocationIds) { 'Record tenant namedLocationIds before generating executable Microsoft Graph commands for this policy.' } else { 'Review excluded break-glass accounts and service principals before enabling the policy.' }
        regulatoryNote = 'Supports compliance with OCC 2011-12, FINRA 3110, and DORA Article 9 access control expectations.'
    }
}

function New-LegacyAuthenticationBlockPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration
    )

    $policyName = $Configuration.policyNamingConvention -replace '\{Tier\}', 'LegacyAuth'
    $policyName = $policyName -replace '\{Purpose\}', 'Block'

    return [ordered]@{
        displayName = $policyName
        tier = $Configuration.tier
        riskTier = 'legacy-auth'
        targetedAppIds = @($Configuration.copilotAppIds)
        grantControls = [ordered]@{
            operator = 'OR'
            builtInControls = @('block')
        }
        conditions = [ordered]@{
            users = [ordered]@{
                includeUsers = @('All')
                excludeUsers = @()
            }
            applications = [ordered]@{
                includeApplications = @($Configuration.copilotAppIds)
                excludeApplications = @()
            }
            clientAppTypes = @('exchangeActiveSync', 'other')
            signInRiskLevels = @()
            locations = [ordered]@{
                includeLocations = @('All')
                excludeLocations = @()
            }
        }
        sessionControls = [ordered]@{}
        requiresTenantNamedLocationIds = $false
        manualReviewRequired = $false
        deploymentGuidance = 'Blocks legacy authentication client app types for the selected Copilot target resources.'
        regulatoryNote = 'Supports compliance with OCC 2011-12, FINRA 3110, and DORA Article 9 access control expectations.'
    }
}

function New-UnknownDeviceStateBlockPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration
    )

    $policyName = $Configuration.policyNamingConvention -replace '\{Tier\}', 'UnknownDeviceState'
    $policyName = $policyName -replace '\{Purpose\}', 'Block'

    return [ordered]@{
        displayName = $policyName
        tier = $Configuration.tier
        riskTier = 'unknown-device-state'
        targetedAppIds = @($Configuration.copilotAppIds)
        grantControls = [ordered]@{
            operator = 'OR'
            builtInControls = @('block')
        }
        conditions = [ordered]@{
            users = [ordered]@{
                includeUsers = @('All')
                excludeUsers = @()
            }
            applications = [ordered]@{
                includeApplications = @($Configuration.copilotAppIds)
                excludeApplications = @()
            }
            clientAppTypes = @('all')
            signInRiskLevels = @()
            locations = [ordered]@{
                includeLocations = @('All')
                excludeLocations = @()
            }
            devices = [ordered]@{
                deviceFilter = [ordered]@{
                    mode = 'exclude'
                    rule = 'device.isCompliant -eq "True"'
                }
            }
        }
        sessionControls = [ordered]@{}
        requiresTenantNamedLocationIds = $false
        manualReviewRequired = $false
        deploymentGuidance = 'Blocks access for devices not excluded by the compliant-device filter, including unregistered devices with null device attributes.'
        regulatoryNote = 'Supports compliance with OCC 2011-12, FINRA 3110, and DORA Article 9 access control expectations.'
    }
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

    if ($Register -is [hashtable] -and $Register.ContainsKey('exceptions')) {
        return @($Register.exceptions)
    }

    if ($Register -is [System.Collections.IEnumerable] -and $Register -isnot [string]) {
        return @($Register)
    }

    return @()
}

function Write-ArtifactFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [object]$Content
    )

    $directory = Split-Path -Path $Path -Parent
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        $null = New-Item -ItemType Directory -Path $directory -Force
    }

    $Content | ConvertTo-Json -Depth 12 | Set-Content -Path $Path -Encoding utf8
    $hash = Get-CopilotGovSha256 -Path $Path
    Set-Content -Path ($Path + '.sha256') -Value ("{0}  {1}" -f $hash, [IO.Path]::GetFileName($Path)) -Encoding utf8

    return [ordered]@{
        name = $Name
        type = $Name
        path = $Path
        hash = $hash
    }
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

$null = New-Item -ItemType Directory -Path $OutputPath -Force

$monitorResult = & (Join-Path $PSScriptRoot 'Monitor-Compliance.ps1') `
    -ConfigurationTier $ConfigurationTier `
    -BaselinePath $resolvedBaselinePath `
    -ExceptionRegisterPath $resolvedExceptionRegisterPath `
    -OutputPath $OutputPath

$baselineDocument = if (Test-Path -Path $resolvedBaselinePath) {
    Read-JsonFile -Path $resolvedBaselinePath
}
else {
    $null
}

$exceptionRegisterDocument = if (Test-Path -Path $resolvedExceptionRegisterPath) {
    Read-JsonFile -Path $resolvedExceptionRegisterPath
}
else {
    [ordered]@{
        solution = $config.solution
        solutionCode = $config.solutionCode
        tier = $ConfigurationTier
        exceptions = @()
        note = 'Approved exceptions not yet recorded.'
    }
}

$policyTemplates = if ($baselineDocument -is [hashtable] -and $baselineDocument.ContainsKey('policies') -and @($baselineDocument.policies).Count -gt 0) {
    @($baselineDocument.policies)
}
elseif ($baselineDocument -is [hashtable] -and $baselineDocument.ContainsKey('policyTemplates') -and @($baselineDocument.policyTemplates).Count -gt 0) {
    @($baselineDocument.policyTemplates)
}
else {
    $templates = @(foreach ($riskTierName in @('low', 'medium', 'high')) {
        New-PolicyTemplate -RiskTierName $riskTierName -RiskTierSettings $config.riskTiers[$riskTierName] -Configuration $config
    })
    if ($config.blockLegacyAuth) {
        $templates += New-LegacyAuthenticationBlockPolicy -Configuration $config
    }
    if ($config.blockUnknownDeviceStates) {
        $templates += New-UnknownDeviceStateBlockPolicy -Configuration $config
    }
    $templates
}

$exceptionEntries = Get-ExceptionEntries -Register $exceptionRegisterDocument
$driftSummaryPath = Join-Path $OutputPath 'drift-alert-summary.json'
$driftSummaryDocument = if (Test-Path -Path $driftSummaryPath) {
    Read-JsonFile -Path $driftSummaryPath
}
else {
    [ordered]@{
        solution = $config.solution
        solutionCode = $config.solutionCode
        configurationTier = $ConfigurationTier
        generatedAt = (Get-Date).ToString('o')
        driftDetected = $false
        changeCount = 0
        changes = @()
    }
}

$policyStateDocument = [ordered]@{
    solution = $config.solution
    solutionCode = $config.solutionCode
    configurationTier = $ConfigurationTier
    exportedAt = (Get-Date).ToString('o')
    targetedAppIds = @($config.copilotAppIds)
    controls = @('2.3', '2.6', '2.9')
    policies = $policyTemplates
    baselinePath = $resolvedBaselinePath
    note = 'Snapshot of Conditional Access policies targeting Copilot applications.'
}

$exceptionArtifactDocument = if ($exceptionRegisterDocument -is [hashtable] -and $exceptionRegisterDocument.ContainsKey('exceptions')) {
    $exceptionRegisterDocument
}
else {
    [ordered]@{
        solution = $config.solution
        solutionCode = $config.solutionCode
        tier = $ConfigurationTier
        exceptions = @($exceptionEntries)
    }
}

$policyArtifact = Write-ArtifactFile -Path (Join-Path $OutputPath 'ca-policy-state.json') -Name 'ca-policy-state' -Content $policyStateDocument
$driftArtifact = Write-ArtifactFile -Path (Join-Path $OutputPath 'drift-alert-summary.json') -Name 'drift-alert-summary' -Content $driftSummaryDocument
$exceptionArtifact = Write-ArtifactFile -Path (Join-Path $OutputPath 'access-exception-register.json') -Name 'access-exception-register' -Content $exceptionArtifactDocument

$controlStatusMap = @{}
foreach ($control in $monitorResult.Controls) {
    $controlStatusMap[[string]$control.controlId] = [string]$control.status
}
foreach ($controlId in @('2.3', '2.6', '2.9')) {
    if (-not $controlStatusMap.ContainsKey($controlId)) {
        $controlStatusMap[$controlId] = 'partial'
    }
}

$controls = @(
    [ordered]@{ controlId = '2.3'; status = $controlStatusMap['2.3']; notes = 'Supports compliance with OCC 2011-12 and FINRA 3110 by documenting Copilot access-control enforcement and drift review.' },
    [ordered]@{ controlId = '2.6'; status = $controlStatusMap['2.6']; notes = 'Supports compliance with OCC 2011-12 and FINRA 3110 by preserving exception oversight and policy-change evidence.' },
    [ordered]@{ controlId = '2.9'; status = $controlStatusMap['2.9']; notes = 'Supports compliance with OCC 2011-12 and DORA Article 9 by documenting compliant-device expectations for Copilot access.' }
)

$policyCount = @($policyTemplates).Count
$driftChangeCount = @($driftSummaryDocument.changes).Count
$exceptionCount = @($exceptionEntries).Count

$summary = [ordered]@{
    overallStatus = [string]$monitorResult.OverallStatus
    recordCount = ($policyCount + $driftChangeCount + $exceptionCount)
    findingCount = [int]$monitorResult.FindingCount
    exceptionCount = $exceptionCount
}

$additionalMetadata = [ordered]@{}
if ($PSBoundParameters.ContainsKey('PeriodStart')) {
    $additionalMetadata['periodStart'] = $PeriodStart.ToString('yyyy-MM-dd')
}

if ($PSBoundParameters.ContainsKey('PeriodEnd')) {
    $additionalMetadata['periodEnd'] = $PeriodEnd.ToString('yyyy-MM-dd')
}

$packageResult = Export-SolutionEvidencePackage `
    -Solution $config.solution `
    -SolutionCode $config.solutionCode `
    -Tier $ConfigurationTier `
    -OutputPath $OutputPath `
    -Summary $summary `
    -Controls $controls `
    -Artifacts @($policyArtifact, $driftArtifact, $exceptionArtifact) `
    -AdditionalMetadata $additionalMetadata

[pscustomobject]@{
    Solution = $config.displayName
    SolutionCode = $config.solutionCode
    ConfigurationTier = $ConfigurationTier
    EvidencePackagePath = $packageResult.Path
    EvidencePackageHash = $packageResult.Hash
    ArtifactCount = 3
    Artifacts = @($policyArtifact, $driftArtifact, $exceptionArtifact)
}


