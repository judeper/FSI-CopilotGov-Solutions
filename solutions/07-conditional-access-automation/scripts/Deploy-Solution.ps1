#Requires -Version 7.0
<#
.SYNOPSIS
Deploys Conditional Access policy configuration for Microsoft 365 Copilot.
.DESCRIPTION
Takes a baseline snapshot of Conditional Access policies targeting Copilot application IDs, generates policy templates for the selected tier, writes a deployment manifest, and outputs Graph API commands required to create the policies. Policy creation requires Microsoft Graph permissions and should be executed by a Conditional Access Administrator.
.PARAMETER ConfigurationTier
Specifies the governance tier to generate. Valid values are baseline, recommended, and regulated.
.PARAMETER OutputPath
Specifies where generated templates, manifests, and baseline artifacts are written.
.PARAMETER TenantId
Specifies the Entra ID tenant identifier used in generated Graph connection commands.
.PARAMETER SkipBaseline
Skips writing the baseline snapshot stub.
.PARAMETER Execute
Attempts to create Conditional Access policies through Microsoft Graph after templates are generated.
.EXAMPLE
.\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId contoso.onmicrosoft.com -OutputPath .\artifacts\recommended
.EXAMPLE
.\Deploy-Solution.ps1 -ConfigurationTier regulated -OutputPath .\artifacts\regulated -Execute
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

    $namedLocations = if ($TierConfig.ContainsKey('namedLocations')) {
        @($TierConfig.namedLocations)
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
        namedLocations           = $namedLocations
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

    $namedLocations = if ($RiskTierSettings.ContainsKey('namedLocations') -and $RiskTierSettings.namedLocations.Count -gt 0) {
        @($RiskTierSettings.namedLocations)
    }
    elseif ($Configuration.namedLocations.Count -gt 0) {
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
        signInRiskLevels = @($RiskTierName)
        locations = [ordered]@{
            includeLocations = if ($RiskTierSettings.namedLocationRequired) { $namedLocations } else { @('All') }
            excludeLocations = if ($RiskTierSettings.namedLocationRequired) { @('AllTrusted') } else { @() }
        }
    }

    if ($Configuration.blockUnknownDeviceStates -or $RiskTierSettings.compliantDevice) {
        $conditions.deviceStates = [ordered]@{
            includeStates = @('Compliant', 'HybridAzureADJoined')
            excludeStates = if ($Configuration.blockUnknownDeviceStates) { @('Unknown') } else { @() }
        }
    }

    return [ordered]@{
        displayName = $policyName
        tier = $Configuration.tier
        riskTier = $RiskTierName
        targetedAppIds = @($Configuration.copilotAppIds)
        grantControls = [ordered]@{
            operator = if ($grantControls.Count -gt 1) { 'AND' } else { 'OR' }
            builtInControls = @($grantControls)
        }
        conditions = $conditions
        sessionControls = [ordered]@{
            persistentBrowser = 'never'
            signInFrequencyHours = if ($Configuration.tier -eq 'regulated') { 4 } elseif ($RiskTierName -eq 'high') { 8 } else { 12 }
        }
        deploymentGuidance = 'Review named locations, excluded break-glass accounts, and service principals before enabling the policy.'
        regulatoryNote = 'Supports compliance with OCC 2011-12, FINRA 3110, and DORA Article 9 access control expectations.'
    }
}

function Get-PolicyRequestBody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PolicyTemplate
    )

    return [ordered]@{
        displayName = $PolicyTemplate.displayName
        state = 'enabled'
        conditions = $PolicyTemplate.conditions
        grantControls = $PolicyTemplate.grantControls
        sessionControls = $PolicyTemplate.sessionControls
    }
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
    if ([string]::IsNullOrWhiteSpace($TenantId)) {
        $null = $commands.Add("Connect-MgGraph -Scopes 'Policy.Read.All','Policy.ReadWrite.ConditionalAccess'")
    }
    else {
        $null = $commands.Add("Connect-MgGraph -TenantId '$TenantId' -Scopes 'Policy.Read.All','Policy.ReadWrite.ConditionalAccess'")
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

$policyTemplates = foreach ($riskTierName in @('low', 'medium', 'high')) {
    New-PolicyTemplate -RiskTierName $riskTierName -RiskTierSettings $config.riskTiers[$riskTierName] -Configuration $config
}

$requestBodies = foreach ($policyTemplate in $policyTemplates) {
    Get-PolicyRequestBody -PolicyTemplate $policyTemplate
}

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
    driftDetectionEnabled = $config.driftDetectionEnabled
    driftCheckFrequency = $config.driftCheckFrequency
    evidenceRetentionDays = $config.evidenceRetentionDays
    notificationMode = $config.notificationMode
    executeRequested = [bool]$Execute
    manualReviewRequired = $true
}
Write-JsonFile -Path $manifestPath -InputObject $manifest

if ($Execute) {
    if (-not (Get-Command -Name Connect-MgGraph -ErrorAction SilentlyContinue)) {
        throw 'Microsoft.Graph PowerShell SDK is required to use -Execute.'
    }

    if (-not (Get-Command -Name Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) {
        throw 'Microsoft.Graph PowerShell SDK is required to use -Execute.'
    }

    $graphScopes = @('Policy.Read.All', 'Policy.ReadWrite.ConditionalAccess')
    if ([string]::IsNullOrWhiteSpace($TenantId)) {
        Connect-MgGraph -Scopes $graphScopes | Out-Null
    }
    else {
        Connect-MgGraph -TenantId $TenantId -Scopes $graphScopes | Out-Null
    }

    foreach ($requestBody in $requestBodies) {
        Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies' -Body $requestBody | Out-Null
    }
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


