<#
.SYNOPSIS
    Deploys the Copilot Studio Agent Lifecycle Tracker (CSLT) governance scaffold.

.DESCRIPTION
    Tier-aware deployment script that produces a deployment manifest describing
    publishing approval requirements, versioning retention, deprecation notice
    window, and lifecycle review cadence for governance of Microsoft Copilot
    Studio agents. Helps meet FFIEC IT Handbook (Operations Booklet) change-
    management expectations, FINRA Rule 3110 supervisory-systems and WSP
    expectations, OCC Bulletin 2023-17 third-party risk-management
    considerations, and Sarbanes-Oxley §§302/404 change-control documentation
    where applicable to ICFR.

    This script is documentation-first and does not connect to live Power
    Platform or Copilot Studio services.

.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.

.PARAMETER OutputPath
    Path for deployment artifacts and evidence output.

.PARAMETER TenantId
    Microsoft Entra ID tenant ID. Defaults to AZURE_TENANT_ID environment variable.

.EXAMPLE
    .\Deploy-Solution.ps1 -ConfigurationTier recommended -Verbose

.EXAMPLE
    .\Deploy-Solution.ps1 -ConfigurationTier regulated -TenantId "00000000-0000-0000-0000-000000000000" -WhatIf

.NOTES
    Solution: Copilot Studio Agent Lifecycle Tracker (CSLT)
    Primary Controls: 4.14, 4.13
    Supporting Controls: 1.10, 1.16, 4.5, 4.12
    Version: v0.1.0
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts'),

    [Parameter()]
    [string]$TenantId = $env:AZURE_TENANT_ID
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'CsltConfig.psm1') -Force

Write-Verbose ("Loading CSLT configuration for tier [{0}]." -f $ConfigurationTier)
$configuration = Get-CsltConfiguration -Tier $ConfigurationTier
Test-CsltConfiguration -Configuration $configuration

$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)

$connectionReferences = @(
    'fsi_cr_copilot_studio_lifecycle_powerplatform',
    'fsi_cr_copilot_studio_lifecycle_dataverse'
)

$environmentVariables = @(
    'fsi_ev_copilot_studio_lifecycle_tenant_id',
    'fsi_ev_copilot_studio_lifecycle_client_id'
)
if ($null -ne $configuration.evidenceImmutability) {
    $environmentVariables += 'fsi_ev_copilot_studio_lifecycle_immutable_storage_account'
}

$deploymentManifest = [pscustomobject]@{
    solution = $configuration.solution
    solutionCode = $configuration.solutionCode
    displayName = $configuration.displayName
    version = $configuration.version
    tier = $ConfigurationTier
    tenantId = if ([string]::IsNullOrWhiteSpace($TenantId)) { 'not-provided' } else { $TenantId }
    track = $configuration.track
    priority = $configuration.priority
    regulations = $configuration.regulations
    framework_ids = $configuration.framework_ids
    primaryControls = $configuration.primaryControls
    supportingControls = $configuration.supportingControls
    controls = $configuration.controls
    publishingApprovalRequired = $configuration.publishingApprovalRequired
    dualApproverRequired = $configuration.dualApproverRequired
    versioningRetentionDays = $configuration.versioningRetentionDays
    deprecationNoticeDays = $configuration.deprecationNoticeDays
    lifecycleReviewCadenceDays = $configuration.lifecycleReviewCadenceDays
    inventoryPollingIntervalHours = $configuration.inventoryPollingIntervalHours
    evidenceRetentionDays = $configuration.evidenceRetentionDays
    notificationMode = $configuration.notificationMode
    monitoredEnvironments = @($configuration.defaults.monitoredEnvironments)
    lifecycleStages = @($configuration.defaults.lifecycleStages)
    dataverseTables = [ordered]@{
        inventory = 'fsi_cg_copilot_studio_lifecycle_inventory'
        approval = 'fsi_cg_copilot_studio_lifecycle_approval'
        version = 'fsi_cg_copilot_studio_lifecycle_version'
        deprecation = 'fsi_cg_copilot_studio_lifecycle_deprecation'
    }
    connectionReferences = $connectionReferences
    environmentVariables = $environmentVariables
    publishingApprovalLog = $configuration.publishingApprovalLog
    deprecationEvidence = $configuration.deprecationEvidence
    lifecycleReview = $configuration.lifecycleReview
    evidenceImmutability = $configuration.evidenceImmutability
    deploymentTimestamp = (Get-Date).ToString('o')
    outputPath = $resolvedOutputPath
}

$manifestPath = Join-Path $resolvedOutputPath ("23-copilot-studio-lifecycle-tracker-deployment-{0}.json" -f $ConfigurationTier)
if ($PSCmdlet.ShouldProcess($manifestPath, 'Write CSLT deployment manifest')) {
    $null = New-Item -ItemType Directory -Path $resolvedOutputPath -Force
    $deploymentManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding utf8
    Write-Verbose ("Deployment manifest written to {0}." -f $manifestPath)
}
else {
    Write-Verbose ("WhatIf enabled. Manifest would be written to {0}." -f $manifestPath)
}

Write-Host (
    "Deployment summary: CSLT tier [{0}] inventories agents every {1} hours. Publishing approval required: {2}. Dual approver required: {3}. Lifecycle review cadence: {4} days." -f
    $ConfigurationTier,
    $configuration.inventoryPollingIntervalHours,
    [bool]$configuration.publishingApprovalRequired,
    [bool]$configuration.dualApproverRequired,
    $configuration.lifecycleReviewCadenceDays
)

$deploymentManifest
