<#
.SYNOPSIS
    Monitors the Microsoft Purview Communication Compliance Configurator deployment state.

.DESCRIPTION
    Evaluates tier configuration, expected policy coverage, reviewer queue
    collection readiness, and lexicon status for the Microsoft Purview Communication Compliance
    Configurator solution.

.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.

.PARAMETER OutputPath
    Path for monitoring artifacts.

.PARAMETER TenantId
    Microsoft Entra ID tenant ID used for future API-based queue collection.

.PARAMETER ClientId
    Client ID used for future API-based queue collection.

.PARAMETER ClientSecret
    Client secret used for future API-based queue collection.

.PARAMETER PassThru
    Returns the full monitoring object in addition to writing the JSON artifact.

.EXAMPLE
    .\Monitor-Compliance.ps1 -ConfigurationTier recommended -PassThru

    Produces a monitoring summary and writes a monitoring artifact.

.OUTPUTS
    PSCustomObject. Monitoring summary for the selected governance tier.

.NOTES
    Queue metrics collection currently uses a documentation-first stub because a
    supported Purview Communication Compliance API path is not generally
    available for automation.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\monitoring'),

    [Parameter()]
    [AllowEmptyString()]
    [string]$TenantId,

    [Parameter()]
    [AllowEmptyString()]
    [string]$ClientId,

    [Parameter()]
    [System.Security.SecureString]$ClientSecret,

    [Parameter()]
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$deploymentRoot = Join-Path $solutionRoot 'artifacts\deployment'

Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'CCC-Common.psm1') -Force

function Get-ReviewerQueueMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter()]
        [AllowEmptyString()]
        [string]$TenantId,

        [Parameter()]
        [AllowEmptyString()]
        [string]$ClientId,

        [Parameter()]
        [System.Security.SecureString]$ClientSecret
    )

    # Requires Purview compliance portal API or Graph Beta support.
    return [pscustomobject]@{
        snapshotDate = (Get-Date).ToString('o')
        totalPending = 0
        avgAgeHours = 0
        p90AgeHours = 0
        dispositionBreakdown = @()
        escalatedCount = 0
        overdueCount = 0
        reviewerSlaHours = [int]$Config['reviewerSlaHours']
        queueHealthy = $false
        collectionMethod = 'manual-portal-export'
        tenantId = if ([string]::IsNullOrWhiteSpace($TenantId)) { 'not-provided' } else { $TenantId }
        clientId = if ([string]::IsNullOrWhiteSpace($ClientId)) { 'not-provided' } else { $ClientId }
        credentialSupplied = [bool]($TenantId -or $ClientId -or $ClientSecret)
        notes = 'Queue metrics require Purview compliance portal API or Graph Beta support; manual export is currently required.'
    }
}

function Test-PolicyCoverage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [string]$DeploymentRoot
    )

    $manifestPath = Join-Path $DeploymentRoot 'communication-compliance-config-deployment-manifest.json'
    $activationPath = Join-Path $DeploymentRoot 'manual-activation-status.json'
    $manifest = $null
    $activationLookup = @{}

    if (Test-Path -Path $manifestPath) {
        $manifest = ConvertTo-Hashtable -InputObject ((Get-Content -Path $manifestPath -Raw) | ConvertFrom-Json)
    }

    if (Test-Path -Path $activationPath) {
        $activationStatus = ConvertTo-Hashtable -InputObject ((Get-Content -Path $activationPath -Raw) | ConvertFrom-Json)
        foreach ($policy in @($activationStatus['policies'])) {
            $activationLookup[$policy['templateId']] = [bool]$policy['isActive']
        }
    }

    $details = @()
    foreach ($policyId in $Config['policyTemplates']) {
        $manifestPolicy = $null
        if ($null -ne $manifest) {
            $manifestPolicy = @($manifest['policyTemplates'] | Where-Object { $_['templateId'] -eq $policyId }) | Select-Object -First 1
        }

        $exists = $null -ne $manifestPolicy
        $activationRecorded = $activationLookup.ContainsKey($policyId)
        $isActive = if ($activationRecorded) { $activationLookup[$policyId] } else { $exists }

        $details += [pscustomobject]@{
            policyId = $policyId
            exists = $exists
            isActive = $isActive
            activationRecorded = $activationRecorded
            verificationSource = if ($activationRecorded) { 'manual-activation-status' } elseif ($exists) { 'deployment-manifest' } else { 'not-found' }
            gap = if (-not $exists) { 'Deployment manifest missing policy template.' } elseif ($activationRecorded -and -not $isActive) { 'Policy is not marked active in manual activation status.' } else { $null }
        }
    }

    $missingPolicies = @($details | Where-Object { -not $_.exists } | ForEach-Object { $_.policyId })
    $inactivePolicies = @($details | Where-Object { $_.exists -and -not $_.isActive } | ForEach-Object { $_.policyId })

    return [pscustomobject]@{
        manifestPath = $manifestPath
        activationStatusPath = if (Test-Path -Path $activationPath) { $activationPath } else { $null }
        expectedPolicies = $Config['policyTemplates']
        details = $details
        missingPolicies = $missingPolicies
        inactivePolicies = $inactivePolicies
        allExpectedPoliciesPresent = ($missingPolicies.Count -eq 0)
        allExpectedPoliciesActive = ($inactivePolicies.Count -eq 0) -and ($details.Count -gt 0)
    }
}

function Get-LexiconStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [string]$DeploymentRoot
    )

    $lexiconStatusPath = Join-Path $DeploymentRoot 'lexicon-status.json'
    if (Test-Path -Path $lexiconStatusPath) {
        $lexiconStatus = ConvertTo-Hashtable -InputObject ((Get-Content -Path $lexiconStatusPath -Raw) | ConvertFrom-Json)
        return [pscustomobject]@{
            version = $lexiconStatus['version']
            lastUpdateDate = $lexiconStatus['lastUpdateDate']
            wordCount = $lexiconStatus['wordCount']
            source = $lexiconStatusPath
        }
    }

    return [pscustomobject]@{
        version = $Config['lexiconVersion']
        lastUpdateDate = $Config['lexiconLastUpdated']
        wordCount = @($Config['lexiconWords']).Count
        source = 'tier-config'
    }
}

$configRoot = Join-Path $solutionRoot 'config'
$config = Get-SolutionConfiguration -ConfigRoot $configRoot -Tier $ConfigurationTier
$tierDefinition = Get-CopilotGovTierDefinition -Tier $ConfigurationTier
$queueMetrics = Get-ReviewerQueueMetrics -Config $config -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
$policyCoverage = Test-PolicyCoverage -Config $config -DeploymentRoot $deploymentRoot
$lexiconStatus = Get-LexiconStatus -Config $config -DeploymentRoot $deploymentRoot

$overallStatus = if (-not $policyCoverage.allExpectedPoliciesPresent -or -not $policyCoverage.allExpectedPoliciesActive) {
    'partial'
}
elseif ($queueMetrics.collectionMethod -eq 'manual-portal-export') {
    'monitor-only'
}
elseif ($queueMetrics.queueHealthy) {
    'implemented'
}
else {
    'partial'
}

$statusPayload = [pscustomobject]@{
    solution = $config['solution']
    solutionCode = $config['solutionCode']
    displayName = $config['displayName']
    tier = $ConfigurationTier
    tierLabel = $tierDefinition.Label
    generatedAt = (Get-Date).ToString('o')
    overallStatus = $overallStatus
    statusScore = Get-CopilotGovStatusScore -Status $overallStatus
    queueMetrics = $queueMetrics
    policyCoverage = $policyCoverage
    lexiconStatus = $lexiconStatus
}

$null = New-Item -ItemType Directory -Path $OutputPath -Force
$statusPath = Join-Path $OutputPath 'communication-compliance-status.json'
$statusPayload | ConvertTo-Json -Depth 8 | Set-Content -Path $statusPath -Encoding utf8

if ($PassThru) {
    $statusPayload
}
else {
    [pscustomobject]@{
        Solution = $config['displayName']
        Tier = $ConfigurationTier
        OverallStatus = $overallStatus
        StatusScore = Get-CopilotGovStatusScore -Status $overallStatus
        OutputPath = $statusPath
    }
}
