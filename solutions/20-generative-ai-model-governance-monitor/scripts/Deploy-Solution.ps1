<#
.SYNOPSIS
    Deploys the Generative AI Model Governance Monitor (GMG) documentation-first manifest.

.DESCRIPTION
    Documentation-first deployment script. Generates a tier-aware deployment manifest
    that records the model inventory review cadence, validation requirement, ongoing
    monitoring cadence, content safety and guardrail review expectation, and third-party
    review cadence for Microsoft 365 Copilot, Copilot agents, Microsoft Foundry projects,
    Azure OpenAI or Foundry deployments, and approved Foundry partner/community model
    sources under a generative AI model risk management program. The script does not
    connect to live Microsoft 365 or Azure services and uses representative sample
    configuration only.

    Applies SR 11-7 / OCC Bulletin 2011-12 model risk principles to generative AI during
    the period in which SR 26-2 / OCC Bulletin 2026-13 explicitly exclude generative AI.

.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.

.PARAMETER OutputPath
    Path for the deployment manifest output.

.PARAMETER WhatIf
    Preview deployment actions without writing files.

.EXAMPLE
    .\Deploy-Solution.ps1 -ConfigurationTier recommended -WhatIf -Verbose

.NOTES
    Solution: Generative AI Model Governance Monitor (GMG)
    Primary Controls: 3.8a, 3.8
    Supporting Controls: 3.1, 3.11, 3.12
    Regulations: SR 26-2 / OCC Bulletin 2026-13, SR 11-7 / OCC Bulletin 2011-12 (interim genAI principles), NIST AI RMF 1.0, ISO/IEC 42001
    Version: v0.1.1
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'GmgConfig.psm1') -Force

Write-Verbose ("Loading GMG configuration for tier [{0}]." -f $ConfigurationTier)
$configuration = Get-GmgConfiguration -Tier $ConfigurationTier
Test-GmgConfiguration -Configuration $configuration

$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$defaults = [System.Collections.IDictionary]$configuration.defaults
$trackedModelSources = if ($defaults.Contains('trackedModelSources')) { $defaults.trackedModelSources } else { @() }
$contentSafetyDefaults = if ($defaults.Contains('contentSafetyDefaults')) { $defaults.contentSafetyDefaults } else { [ordered]@{} }

$deploymentManifest = [pscustomobject]@{
    solution                            = $configuration.solution
    displayName                         = $configuration.displayName
    solutionCode                        = $configuration.solutionCode
    version                             = $configuration.version
    tier                                = $ConfigurationTier
    track                               = $configuration.track
    priority                            = $configuration.priority
    phase                               = $configuration.phase
    primaryControls                     = $configuration.primaryControls
    supportingControls                  = $configuration.supportingControls
    regulations                         = $configuration.regulations
    framework_ids                       = $configuration.framework_ids
    trackedModels                       = $configuration.defaults.trackedModels
    trackedModelSources                 = $trackedModelSources
    contentSafetyDefaults               = $contentSafetyDefaults
    modelProvider                       = $configuration.defaults.modelProvider
    modelRiskCommittee                  = $configuration.defaults.modelRiskCommittee
    model_inventory_review_cadence_days = $configuration.model_inventory_review_cadence_days
    monitoring_log_retention_days       = $configuration.monitoring_log_retention_days
    validation_assessment_required      = $configuration.validation_assessment_required
    third_party_review_cadence_days     = $configuration.third_party_review_cadence_days
    ongoingMonitoring                   = $configuration.ongoingMonitoring
    independentChallenge                = $configuration.independentChallenge
    evidenceImmutability                = $configuration.evidenceImmutability
    notificationMode                    = $configuration.notificationMode
    evidenceRetentionDays               = $configuration.evidenceRetentionDays
    runtimeMode                         = 'local-stub'
    warning                             = 'Documentation-first manifest. Scripts use representative sample data and do not connect to live Microsoft 365 or Azure services.'
    deploymentTimestamp                 = (Get-Date).ToString('o')
    outputPath                          = $resolvedOutputPath
}

$manifestPath = Join-Path $resolvedOutputPath ("20-generative-ai-model-governance-monitor-deployment-{0}.json" -f $ConfigurationTier)
if ($PSCmdlet.ShouldProcess($manifestPath, 'Write GMG deployment manifest')) {
    $null = New-Item -ItemType Directory -Path $resolvedOutputPath -Force
    $deploymentManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding utf8
    Write-Verbose ("Deployment manifest written to {0}." -f $manifestPath)
}
else {
    Write-Verbose ("WhatIf enabled. Manifest would be written to {0}." -f $manifestPath)
}

Write-Host (
    "Deployment summary: GMG tier [{0}] tracks {1} sample model source entries; inventory review every {2} days; third-party review every {3} days." -f
    $ConfigurationTier,
    @($trackedModelSources).Count,
    $configuration.model_inventory_review_cadence_days,
    $configuration.third_party_review_cadence_days
)

$deploymentManifest
