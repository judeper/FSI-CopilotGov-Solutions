<#
.SYNOPSIS
    Generates a deployment manifest for the Cross-Tenant Agent Federation Auditor (CTAF).

.DESCRIPTION
    Documentation-first deployment script. Loads tier configuration, validates required
    fields, and writes a JSON deployment manifest describing the planned posture for
    cross-tenant Copilot agent federation, MCP server connection review, and
    Entra Agent ID identity governance. No live tenant calls are made.

.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.

.PARAMETER OutputPath
    Path for the deployment manifest output.

.PARAMETER TenantId
    Optional Entra ID tenant identifier recorded in the manifest. Defaults to AZURE_TENANT_ID.

.EXAMPLE
    .\Deploy-Solution.ps1 -ConfigurationTier recommended -Verbose

.NOTES
    Solution: Cross-Tenant Agent Federation Auditor (CTAF)
    Version:  v0.1.1
    Status:   Documentation-first scaffold
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

Import-Module (Join-Path $PSScriptRoot 'CtafConfig.psm1') -Force

Write-Verbose ("Loading CTAF configuration for tier [{0}]." -f $ConfigurationTier)
$configuration = Get-CtafConfiguration -Tier $ConfigurationTier
Test-CtafConfiguration -Configuration $configuration

$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)

$deploymentManifest = [pscustomobject]@{
    solution                          = $configuration.solution
    solutionCode                      = $configuration.solutionCode
    displayName                       = $configuration.displayName
    version                           = $configuration.version
    tier                              = $ConfigurationTier
    tenantId                          = if ([string]::IsNullOrWhiteSpace($TenantId)) { 'not-provided' } else { $TenantId }
    track                             = $configuration.track
    priority                          = $configuration.priority
    regulations                       = $configuration.regulations
    framework_ids                     = $configuration.framework_ids
    primaryControls                   = $configuration.primaryControls
    supportingControls                = $configuration.supportingControls
    federationReviewCadenceDays       = $configuration.federationReviewCadenceDays
    mcpTrustAttestationRequired       = $configuration.mcpTrustAttestationRequired
    agentIdSigningRequired            = $configuration.agentIdSigningRequired
    agentIdKeyRotationTrackingEnabled = $configuration.agentIdKeyRotationTrackingEnabled
    crossTenantAuditLogRetentionDays  = $configuration.crossTenantAuditLogRetentionDays
    evidenceRetentionDays             = $configuration.evidenceRetentionDays
    notificationMode                  = $configuration.notificationMode
    copilotStudioPublishing           = $configuration.copilotStudioPublishing
    mcpAttestation                    = $configuration.mcpAttestation
    agentIdRotation                   = $configuration.agentIdRotation
    auditAggregation                  = $configuration.auditAggregation
    runtimeMode                       = 'sample'
    documentationFirstNotice          = 'This deployment manifest is generated from documentation-first sample data and does not reflect live tenant state.'
    deploymentTimestamp               = (Get-Date).ToString('o')
    outputPath                        = $resolvedOutputPath
}

$manifestPath = Join-Path $resolvedOutputPath ("21-cross-tenant-agent-federation-auditor-deployment-{0}.json" -f $ConfigurationTier)
if ($PSCmdlet.ShouldProcess($manifestPath, 'Write CTAF deployment manifest')) {
    $null = New-Item -ItemType Directory -Path $resolvedOutputPath -Force
    $deploymentManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding utf8
    $null = Write-CtafSha256File -Path $manifestPath
    Write-Verbose ("Deployment manifest written to {0}." -f $manifestPath)
}
else {
    Write-Verbose ("WhatIf enabled. Manifest would be written to {0}." -f $manifestPath)
}

Write-Host (
    "CTAF deployment summary: tier [{0}] | review cadence {1}d | MCP connection review required: {2} | Agent ID governance review required: {3}." -f
    $ConfigurationTier,
    $configuration.federationReviewCadenceDays,
    [bool]$configuration.mcpTrustAttestationRequired,
    [bool]$configuration.agentIdSigningRequired
)

$deploymentManifest
