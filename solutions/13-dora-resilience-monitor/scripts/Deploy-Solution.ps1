<#
.SYNOPSIS
    Deploys the DORA Operational Resilience Monitor for Microsoft 365 Copilot governance.

.DESCRIPTION
    Tier-aware deployment script that configures service health monitoring, incident
    classification settings, and resilience test tracking for DORA and OCC 2011-12
    operational-resilience governance. Supports baseline, recommended, and regulated
    governance postures and supports compliance with operational monitoring and
    evidence expectations for Copilot-dependent services.

    This script:
    - Validates prerequisites and configuration
    - Creates the deployment manifest
    - Registers service health monitoring endpoints
    - Configures incident severity thresholds per the selected tier
    - Outputs a deployment summary for evidence purposes

.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.
    - baseline: Service health polling + summary alerting
    - recommended: + Incident register + DORA classification
    - regulated: + Full DORA Art. 17-19 reporting package + Sentinel integration

.PARAMETER OutputPath
    Path for deployment artifacts and evidence output.

.PARAMETER TenantId
    Microsoft Entra ID tenant ID. Defaults to AZURE_TENANT_ID environment variable.

.PARAMETER WhatIf
    Preview deployment actions without creating or modifying artifacts.

.EXAMPLE
    .\Deploy-Solution.ps1 -ConfigurationTier recommended -Verbose

.EXAMPLE
    .\Deploy-Solution.ps1 -ConfigurationTier regulated -TenantId "00000000-0000-0000-0000-000000000000" -WhatIf

.NOTES
    Solution: DORA Operational Resilience Monitor (DRM)
    Controls:  2.7, 4.9, 4.10, 4.11
    Regulations: DORA, OCC 2011-12, FFIEC IT Handbook
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

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'DrmConfig.psm1') -Force

Write-Verbose ("Loading DRM configuration for tier [{0}]." -f $ConfigurationTier)
$configuration = Get-DrmConfiguration -Tier $ConfigurationTier
Test-DrmConfiguration -Configuration $configuration -AdditionalRequiredFields @('track', 'priority', 'regulations')

$tierDefinition = Get-CopilotGovTierDefinition -Tier $ConfigurationTier
$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$monitoredServices = @(
    'Exchange Online',
    'SharePoint Online',
    'Microsoft Teams',
    'Microsoft Graph',
    'Microsoft 365 Apps',
    'Microsoft Copilot'
)

$connectionReferences = @(
    'fsi_cr_dora_resilience_monitor_graph',
    'fsi_cr_dora_resilience_monitor_dataverse'
)
if ($configuration.sentinelIntegration.enabled) {
    $connectionReferences += 'fsi_cr_dora_resilience_monitor_sentinel'
}

$environmentVariables = @(
    'fsi_ev_dora_resilience_monitor_tenant_id',
    'fsi_ev_dora_resilience_monitor_client_id',
    'fsi_ev_dora_resilience_monitor_notification_channel'
)
if ($configuration.sentinelIntegration.Contains('workspaceIdEnvVar')) {
    $environmentVariables += 'fsi_ev_dora_resilience_monitor_sentinel_workspace_id'
}
if ($configuration.Contains('evidenceImmutability') -and $null -ne $configuration.evidenceImmutability) {
    $environmentVariables += 'fsi_ev_dora_resilience_monitor_immutable_storage_account'
}

$deploymentManifest = [pscustomobject]@{
    solution = $configuration.solution
    solutionCode = $configuration.solutionCode
    displayName = $configuration.displayName
    version = $configuration.version
    tier = $ConfigurationTier
    tierLabel = $tierDefinition.Label
    tierRank = $tierDefinition.Value
    tenantId = if ([string]::IsNullOrWhiteSpace($TenantId)) { 'not-provided' } else { $TenantId }
    track = $configuration.track
    priority = $configuration.priority
    regulations = $configuration.regulations
    controls = $configuration.controls
    dependencySolutions = @('12-regulatory-compliance-dashboard')
    monitoredServices = $monitoredServices
    configuredMonitoredServices = @($configuration.defaults.monitoredServices)
    serviceHealthPollingIntervalMinutes = $configuration.serviceHealthPollingIntervalMinutes
    notificationMode = $configuration.notificationMode
    evidenceRetentionDays = $configuration.evidenceRetentionDays
    incidentSeverityThresholds = $configuration.incidentClassification.severityThresholds
    dataverseTables = [ordered]@{
        baseline = 'fsi_cg_dora_resilience_monitor_baseline'
        finding = 'fsi_cg_dora_resilience_monitor_finding'
        evidence = 'fsi_cg_dora_resilience_monitor_evidence'
    }
    connectionReferences = $connectionReferences
    environmentVariables = $environmentVariables
    resilienceTestTracking = $configuration.resilienceTestTracking
    sentinelIntegration = $configuration.sentinelIntegration
    powerAutomateFlow = $configuration.powerAutomateFlow
    dataResidency = $configuration.dataResidency
    evidenceImmutability = $configuration.evidenceImmutability
    dashboardStatusReference = [ordered]@{
        implemented = Get-CopilotGovStatusScore -Status 'implemented'
        partial = Get-CopilotGovStatusScore -Status 'partial'
        'monitor-only' = Get-CopilotGovStatusScore -Status 'monitor-only'
        'playbook-only' = Get-CopilotGovStatusScore -Status 'playbook-only'
        'not-applicable' = Get-CopilotGovStatusScore -Status 'not-applicable'
    }
    deploymentTimestamp = (Get-Date).ToString('o')
    outputPath = $resolvedOutputPath
}

$manifestPath = Join-Path $resolvedOutputPath ("13-dora-resilience-monitor-deployment-{0}.json" -f $ConfigurationTier)
if ($PSCmdlet.ShouldProcess($manifestPath, 'Write DRM deployment manifest')) {
    $null = New-Item -ItemType Directory -Path $resolvedOutputPath -Force
    $deploymentManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding utf8
    Write-Verbose ("Deployment manifest written to {0}." -f $manifestPath)
}
else {
    Write-Verbose ("WhatIf enabled. Manifest would be written to {0}." -f $manifestPath)
}

Write-Host (
    "Deployment summary: DRM tier [{0}] monitors {1} services every {2} minutes. Incident register enabled: {3}. Sentinel enabled: {4}." -f
    $ConfigurationTier,
    $monitoredServices.Count,
    $configuration.serviceHealthPollingIntervalMinutes,
    [bool]$configuration.incidentClassification.enabled,
    [bool]$configuration.sentinelIntegration.enabled
)

$deploymentManifest
