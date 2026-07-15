#Requires -Version 7.0
<#
.SYNOPSIS
Generates Conditional Access policy deployment artifacts for Microsoft 365 Copilot.
.DESCRIPTION
Generates baseline stubs, policy templates, deployment metadata, and Graph API command examples for Conditional Access policies targeting Copilot application IDs. Live policy creation is deferred to a tenant-bound executor that can enforce tenant proof, scoped targets, ownership, and cleanup.
.PARAMETER ConfigurationTier
Specifies the governance tier to generate. Valid values are baseline, recommended, and regulated.
.PARAMETER OutputPath
Specifies where generated templates, manifests, and baseline artifacts are written.
.PARAMETER TenantId
Specifies the Entra ID tenant identifier used in generated Graph connection commands.
.PARAMETER SkipBaseline
Skips writing the baseline snapshot stub.
.PARAMETER Execute
Compatibility switch retained to fail closed. Live execution is disabled in this documentation-first scaffold.
.EXAMPLE
.\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId contoso.onmicrosoft.com -OutputPath .\artifacts\recommended
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts'),

    [Parameter()]
    [string]$TenantId = '',

    [Parameter()]
    [switch]$SkipBaseline,

    [Parameter()]
    [switch]$Execute
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

function Merge-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$DefaultConfig,

        [Parameter(Mandatory)]
        [hashtable]$TierConfig
    )

    $copilotAppIds = if ($TierConfig.ContainsKey('copilotAppIds') -and $TierConfig.copilotAppIds.Count -gt 0) {
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

    $emergencyAccessExclusionGroupIds = if ($TierConfig.ContainsKey('emergencyAccessExclusionGroupIds')) {
        @($TierConfig.emergencyAccessExclusionGroupIds)
    }
    elseif ($DefaultConfig.defaults.ContainsKey('emergencyAccessExclusionGroupIds')) {
        @($DefaultConfig.defaults.emergencyAccessExclusionGroupIds)
    }
    else {
        @()
    }

    return [ordered]@{
        solution                 = $DefaultConfig.solution
        displayName              = $DefaultConfig.displayName
        solutionCode             = $DefaultConfig.solutionCode
        version                  = $DefaultConfig.version
        controls                 = @($DefaultConfig.controls)
        regulations              = @($DefaultConfig.regulations)
        evidenceOutputs          = @($DefaultConfig.evidenceOutputs)
        tier                     = $TierConfig.tier
        status                   = $TierConfig.status
        copilotAppIds            = $copilotAppIds
        riskTiers                = $TierConfig.riskTiers
        driftDetectionEnabled    = [bool]$TierConfig.driftDetectionEnabled
        driftCheckFrequency      = [string]$TierConfig.driftCheckFrequency
        notificationMode         = [string]$TierConfig.notificationMode
        evidenceRetentionDays    = [int]$TierConfig.evidenceRetentionDays
        exceptionApproval        = $TierConfig.exceptionApproval
        baselineStoragePath      = $baselineStoragePath
        exceptionRegisterPath    = $exceptionRegisterPath
        policyNamingConvention   = [string]$DefaultConfig.defaults.policyNamingConvention
        namedLocations = $namedLocationIds
        namedLocationIds = $namedLocationIds
        namedLocationLabels = $namedLocationLabels
        emergencyAccessExclusionGroupIds = $emergencyAccessExclusionGroupIds
        blockLegacyAuth          = if ($TierConfig.ContainsKey('blockLegacyAuth')) { [bool]$TierConfig.blockLegacyAuth } else { $false }
        blockUnknownDeviceStates = if ($TierConfig.ContainsKey('blockUnknownDeviceStates')) { [bool]$TierConfig.blockUnknownDeviceStates } else { $false }
        doraAlignmentDocumented  = if ($TierConfig.ContainsKey('doraAlignmentDocumented')) { [bool]$TierConfig.doraAlignmentDocumented } else { $false }
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
    $emergencyExclusionGroupIds = if ($Configuration.ContainsKey('emergencyAccessExclusionGroupIds')) {
        @($Configuration.emergencyAccessExclusionGroupIds)
    }
    else {
        @()
    }
    $requiresBreakGlassExclusion = @($emergencyExclusionGroupIds).Count -eq 0
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
            excludeGroups = @($emergencyExclusionGroupIds)
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
        emergencyAccessExclusionGroupIds = @($emergencyExclusionGroupIds)
        requiresTenantNamedLocationIds = $requiresTenantNamedLocationIds
        requiresBreakGlassExclusion = $requiresBreakGlassExclusion
        manualReviewRequired = ($requiresTenantNamedLocationIds -or $requiresBreakGlassExclusion)
        deploymentGuidance = if ($requiresTenantNamedLocationIds) { 'Record tenant namedLocationIds before generating executable Microsoft Graph commands for this policy.' } elseif ($requiresBreakGlassExclusion) { 'Populate emergencyAccessExclusionGroupIds so break-glass/emergency-access accounts are excluded before enabling this policy.' } else { 'Review excluded break-glass accounts and service principals before enabling the policy.' }
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

    $emergencyExclusionGroupIds = if ($Configuration.ContainsKey('emergencyAccessExclusionGroupIds')) {
        @($Configuration.emergencyAccessExclusionGroupIds)
    }
    else {
        @()
    }
    $requiresBreakGlassExclusion = @($emergencyExclusionGroupIds).Count -eq 0

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
                excludeGroups = @($emergencyExclusionGroupIds)
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
        emergencyAccessExclusionGroupIds = @($emergencyExclusionGroupIds)
        requiresTenantNamedLocationIds = $false
        requiresBreakGlassExclusion = $requiresBreakGlassExclusion
        manualReviewRequired = $requiresBreakGlassExclusion
        deploymentGuidance = if ($requiresBreakGlassExclusion) { 'Populate emergencyAccessExclusionGroupIds before enabling; this block policy targets all users and would otherwise block break-glass/emergency-access accounts.' } else { 'Blocks legacy authentication client app types for the selected Copilot target resources.' }
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

    $emergencyExclusionGroupIds = if ($Configuration.ContainsKey('emergencyAccessExclusionGroupIds')) {
        @($Configuration.emergencyAccessExclusionGroupIds)
    }
    else {
        @()
    }
    $requiresBreakGlassExclusion = @($emergencyExclusionGroupIds).Count -eq 0

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
                excludeGroups = @($emergencyExclusionGroupIds)
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
        emergencyAccessExclusionGroupIds = @($emergencyExclusionGroupIds)
        requiresTenantNamedLocationIds = $false
        requiresBreakGlassExclusion = $requiresBreakGlassExclusion
        manualReviewRequired = $requiresBreakGlassExclusion
        deploymentGuidance = if ($requiresBreakGlassExclusion) { 'Populate emergencyAccessExclusionGroupIds before enabling; this block policy targets all users and would otherwise block break-glass/emergency-access accounts.' } else { 'Blocks access for devices not excluded by the compliant-device filter, including unregistered devices with null device attributes.' }
        regulatoryNote = 'Supports compliance with OCC 2011-12, FINRA 3110, and DORA Article 9 access control expectations.'
    }
}

function Get-PolicyRequestBody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PolicyTemplate
    )

    if ($PolicyTemplate.ContainsKey('requiresTenantNamedLocationIds') -and [bool]$PolicyTemplate.requiresTenantNamedLocationIds) {
        return $null
    }

    $requestBody = [ordered]@{
        displayName = $PolicyTemplate.displayName
        state = 'enabledForReportingButNotEnforced'
        conditions = $PolicyTemplate.conditions
        grantControls = $PolicyTemplate.grantControls
    }

    if ($PolicyTemplate.ContainsKey('sessionControls') -and @($PolicyTemplate.sessionControls.Keys).Count -gt 0) {
        $requestBody['sessionControls'] = $PolicyTemplate.sessionControls
    }

    return $requestBody
}

function Get-GraphCommandText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$RequestBodies,

        [Parameter()]
        [string]$TenantId
    )

    $commands = New-Object System.Collections.Generic.List[string]
    $null = $commands.Add('# Review each request body before executing it against Microsoft Graph.')
    $null = $commands.Add('# Required scopes: Policy.Read.All, Policy.ReadWrite.ConditionalAccess')
    $null = $commands.Add("# Policies are created in report-only state ('enabledForReportingButNotEnforced').")
    $null = $commands.Add('# WARNING: Exclude break-glass/emergency-access accounts (populate emergencyAccessExclusionGroupIds')
    $null = $commands.Add("#          in config so conditions.users.excludeGroups is set) before switching any policy state to 'enabled'.")
    if ([string]::IsNullOrWhiteSpace($TenantId)) {
        $null = $commands.Add("Connect-MgGraph -Scopes 'Policy.Read.All','Policy.ReadWrite.ConditionalAccess'")
    }
    else {
        $escapedTenantId = $TenantId -replace "'", "''"
        $null = $commands.Add("Connect-MgGraph -TenantId '$escapedTenantId' -Scopes 'Policy.Read.All','Policy.ReadWrite.ConditionalAccess'")
    }

    foreach ($requestBody in $RequestBodies) {
        $jsonBody = $requestBody | ConvertTo-Json -Depth 12
        $null = $commands.Add('')
        $null = $commands.Add('$policyBody = @''')
        $null = $commands.Add($jsonBody)
        $null = $commands.Add('''@ | ConvertFrom-Json -AsHashtable')
        $null = $commands.Add("Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies' -Body `$policyBody")
    }

    return $commands
}

$defaultConfigPath = Join-Path $solutionRoot 'config\default-config.json'
$tierConfigPath = Join-Path $solutionRoot ("config\{0}.json" -f $ConfigurationTier)

$defaultConfig = Read-JsonFile -Path $defaultConfigPath
$tierConfig = Read-JsonFile -Path $tierConfigPath
$config = Merge-Configuration -DefaultConfig $defaultConfig -TierConfig $tierConfig

$policyTemplates = @(foreach ($riskTierName in @('low', 'medium', 'high')) {
    New-PolicyTemplate -RiskTierName $riskTierName -RiskTierSettings $config.riskTiers[$riskTierName] -Configuration $config
})
if ($config.blockLegacyAuth) {
    $policyTemplates += New-LegacyAuthenticationBlockPolicy -Configuration $config
}
if ($config.blockUnknownDeviceStates) {
    $policyTemplates += New-UnknownDeviceStateBlockPolicy -Configuration $config
}

$requestBodies = @(foreach ($policyTemplate in $policyTemplates) {
    $requestBody = Get-PolicyRequestBody -PolicyTemplate $policyTemplate
    if ($null -ne $requestBody) {
        $requestBody
    }
})
$skippedGraphPolicies = @($policyTemplates | Where-Object { $_.Contains('requiresTenantNamedLocationIds') -and [bool]$_.requiresTenantNamedLocationIds })

$policyTemplatePath = Join-Path $OutputPath 'ca-policy-templates.json'
$graphCommandPath = Join-Path $OutputPath 'graph-api-commands.ps1'
$manifestPath = Join-Path $OutputPath 'deployment-manifest.json'
$baselinePath = Resolve-ConfiguredPath -ConfiguredPath $config.baselineStoragePath -BasePath $OutputPath -FallbackLeaf 'current-policy-baseline.json'
$exceptionRegisterPath = Resolve-ConfiguredPath -ConfiguredPath $config.exceptionRegisterPath -BasePath $OutputPath -FallbackLeaf 'access-exception-register.json'

if (-not $PSCmdlet.ShouldProcess($config.displayName, "Generate deployment assets for the $ConfigurationTier tier")) {
    return
}

$null = New-Item -ItemType Directory -Path $OutputPath -Force

Write-JsonFile -Path $policyTemplatePath -InputObject $policyTemplates

if (-not $SkipBaseline) {
    $baselineStub = [ordered]@{
        solution = $config.solution
        solutionCode = $config.solutionCode
        tier = $ConfigurationTier
        capturedAt = (Get-Date).ToString('o')
        captureMode = 'stub'
        tenantId = $TenantId
        targetedAppIds = @($config.copilotAppIds)
        policies = $policyTemplates
        note = 'Replace this stub with a live Microsoft Graph export after production Conditional Access policies are approved.'
    }
    Write-JsonFile -Path $baselinePath -InputObject $baselineStub
}

$exceptionRegister = [ordered]@{
    solution = $config.solution
    solutionCode = $config.solutionCode
    tier = $ConfigurationTier
    initializedAt = (Get-Date).ToString('o')
    exceptions = @()
    note = 'Record approved Copilot Conditional Access policy overrides with approver, approval date, business justification, and expiry.'
}
Write-JsonFile -Path $exceptionRegisterPath -InputObject $exceptionRegister

$graphCommands = Get-GraphCommandText -RequestBodies $requestBodies -TenantId $TenantId
if (@($skippedGraphPolicies).Count -gt 0) {
    $graphCommands += ''
    $graphCommands += '# Skipped Microsoft Graph command generation for policies requiring tenant namedLocationIds:'
    foreach ($skippedPolicy in $skippedGraphPolicies) {
        $graphCommands += ('# - {0}' -f $skippedPolicy.displayName)
    }
}
Set-Content -Path $graphCommandPath -Value ($graphCommands -join [Environment]::NewLine) -Encoding utf8

$manifest = [ordered]@{
    solution = $config.solution
    solutionCode = $config.solutionCode
    displayName = $config.displayName
    tier = $ConfigurationTier
    generatedAt = (Get-Date).ToString('o')
    tenantId = $TenantId
    policyTemplatePath = $policyTemplatePath
    baselinePath = if ($SkipBaseline) { $null } else { $baselinePath }
    exceptionRegisterPath = $exceptionRegisterPath
    graphApiCommandsPath = $graphCommandPath
    policyCount = $policyTemplates.Count
    graphReadyPolicyCount = $requestBodies.Count
    skippedGraphPolicyCount = @($skippedGraphPolicies).Count
    skippedGraphPolicyNames = @($skippedGraphPolicies | ForEach-Object { $_.displayName })
    emergencyAccessExclusionGroupCount = @($config.emergencyAccessExclusionGroupIds).Count
    breakGlassExclusionConfigured = (@($config.emergencyAccessExclusionGroupIds).Count -gt 0)
    breakGlassGapPolicyCount = @($policyTemplates | Where-Object { $_.Contains('requiresBreakGlassExclusion') -and [bool]$_.requiresBreakGlassExclusion }).Count
    driftDetectionEnabled = $config.driftDetectionEnabled
    driftCheckFrequency = $config.driftCheckFrequency
    evidenceRetentionDays = $config.evidenceRetentionDays
    notificationMode = $config.notificationMode
    executeRequested = [bool]$Execute
    manualReviewRequired = $true
}
Write-JsonFile -Path $manifestPath -InputObject $manifest

if ($Execute) {
    throw 'Live -Execute is disabled in this documentation-first scaffold. Use the generated report-only templates only after a tenant-bound executor enforces positive tenant proof, disposable scoped targets, emergency and automation identity exclusions, run ownership, read-back, and fail-on-orphan cleanup.'
}

[pscustomobject]@{
    Solution = $config.displayName
    Tier = $ConfigurationTier
    PolicyTemplatePath = $policyTemplatePath
    BaselinePath = if ($SkipBaseline) { 'Skipped' } else { $baselinePath }
    ExceptionRegisterPath = $exceptionRegisterPath
    DeploymentManifestPath = $manifestPath
    GraphApiCommandsPath = $graphCommandPath
    GraphExecutionRequested = [bool]$Execute
}

