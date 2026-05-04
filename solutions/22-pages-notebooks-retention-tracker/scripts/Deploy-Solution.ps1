<#
.SYNOPSIS
    Deploys the Pages and Notebooks Retention Tracker (PNRT) for Microsoft Copilot governance.

.DESCRIPTION
    Tier-aware deployment script that builds a PNRT deployment manifest covering Copilot
    Pages retention settings, OneNote section/folder retention coverage, internal sample
    lineage mode, and Loop component provenance expectations. Helps meet records retention and supervisory
    expectations under SEC Rule 17a-4 (where applicable to broker-dealer required records),
    FINRA Rule 4511(a), and Sarbanes-Oxley §§302/404 (where applicable to ICFR).

    This script does not modify tenant state. It produces a manifest artifact for review.

.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.

.PARAMETER OutputPath
    Path for deployment artifacts.

.PARAMETER TenantId
    Microsoft Entra ID tenant ID. Defaults to AZURE_TENANT_ID.

.PARAMETER WhatIf
    Preview deployment actions without writing artifacts.

.EXAMPLE
    .\Deploy-Solution.ps1 -ConfigurationTier recommended -Verbose

.EXAMPLE
    .\Deploy-Solution.ps1 -ConfigurationTier regulated -TenantId "00000000-0000-0000-0000-000000000000" -WhatIf

.NOTES
    Solution: Pages and Notebooks Retention Tracker (PNRT)
    Primary Controls: 3.14, 3.2
    Supporting Controls: 3.3, 3.11, 2.11
    Version: v0.1.1
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

Import-Module (Join-Path $PSScriptRoot 'PnrtConfig.psm1') -Force

Write-Verbose ("Loading PNRT configuration for tier [{0}]." -f $ConfigurationTier)
$configuration = Get-PnrtConfiguration -Tier $ConfigurationTier
Test-PnrtConfiguration -Configuration $configuration -AdditionalRequiredFields @('track', 'priority', 'regulations')

$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)

$connectionReferences = @(
    'fsi_cr_pnrt_graph',
    'fsi_cr_pnrt_purview'
)
if ($configuration.loopProvenanceRequired) {
    $connectionReferences += 'fsi_cr_pnrt_loop'
}

$environmentVariables = @(
    'fsi_ev_pnrt_tenant_id',
    'fsi_ev_pnrt_client_id'
)
if ($configuration.preservationLockRequired) {
    $environmentVariables += 'fsi_ev_pnrt_immutable_storage_account'
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
    controls = $configuration.controls
    primaryControls = $configuration.primaryControls
    supportingControls = $configuration.supportingControls
    monitoredArtifactTypes = @($configuration.defaults.monitoredArtifactTypes)
    pagesRetentionDays = $configuration.pagesRetentionDays
    notebookRetentionDays = $configuration.notebookRetentionDays
    internalSampleLineageMode = $configuration.branchingAuditMode
    documentedEvidenceSurfaces = @('SharePoint Embedded containers', 'Purview audit logs', 'Purview retention policies and limited labels', 'Graph DriveItem/export where documented')
    loopProvenanceRequired = [bool]$configuration.loopProvenanceRequired
    preservationLockRequired = [bool]$configuration.preservationLockRequired
    signedLineageRequired = [bool]$configuration.signedLineageRequired
    retentionLabelCoverage = $configuration.retentionLabelCoverage
    wormStorage = $configuration.wormStorage
    supervisoryReview = $configuration.supervisoryReview
    powerAutomateFlow = $configuration.powerAutomateFlow
    dataverseTables = [ordered]@{
        pageInventory = 'fsicgpnrtpageinventory'
        notebookInventory = 'fsicgpnrtnotebookinventory'
        loopComponent = 'fsicgpnrtloopcomponent'
        internalSampleLineageEvent = 'fsicgpnrtinternallineageevent'
    }
    connectionReferences = $connectionReferences
    environmentVariables = $environmentVariables
    deploymentTimestamp = (Get-Date).ToString('o')
    outputPath = $resolvedOutputPath
}

$manifestPath = Join-Path $resolvedOutputPath ("22-pages-notebooks-retention-tracker-deployment-{0}.json" -f $ConfigurationTier)
if ($PSCmdlet.ShouldProcess($manifestPath, 'Write PNRT deployment manifest')) {
    $null = New-Item -ItemType Directory -Path $resolvedOutputPath -Force
    $deploymentManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding utf8
    Write-Verbose ("Deployment manifest written to {0}." -f $manifestPath)
}
else {
    Write-Verbose ("WhatIf enabled. Manifest would be written to {0}." -f $manifestPath)
}

Write-Host (
    "Deployment summary: PNRT tier [{0}] - Pages retention {1} days, OneNote section retention {2} days, internal sample lineage mode [{3}], Loop provenance required: {4}." -f
    $ConfigurationTier,
    $configuration.pagesRetentionDays,
    $configuration.notebookRetentionDays,
    $configuration.branchingAuditMode,
    [bool]$configuration.loopProvenanceRequired
)

$deploymentManifest
