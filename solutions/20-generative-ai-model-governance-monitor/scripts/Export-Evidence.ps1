<#
.SYNOPSIS
    Exports the four GMG documentation-first evidence artifacts.

.DESCRIPTION
    Builds copilot-model-inventory, validation-summary, ongoing-monitoring-log, and
    third-party-due-diligence JSON artifacts using the monitoring snapshot from
    Monitor-Compliance.ps1. Each artifact is paired with a SHA-256 sidecar file. This
    script is documentation-first and uses representative sample data. The exported
    package supports compliance with SR 11-7 / OCC Bulletin 2011-12 model risk
    principles for generative AI as applied during the SR 26-2 / OCC Bulletin 2026-13
    generative AI exclusion period.

.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.

.PARAMETER OutputPath
    Path for exported evidence artifacts.

.PARAMETER PeriodStart
    Beginning of the evidence window.

.PARAMETER PeriodEnd
    End of the evidence window.

.PARAMETER PassThru
    Returns the evidence summary object after writing artifacts.

.EXAMPLE
    .\Export-Evidence.ps1 -ConfigurationTier recommended -Verbose

.NOTES
    Solution: Generative AI Model Governance Monitor (GMG)
    Version: v0.1.0
    Documentation-first: scripts use representative sample data.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts'),

    [Parameter()]
    [datetime]$PeriodStart = (Get-Date).Date.AddDays(-30),

    [Parameter()]
    [datetime]$PeriodEnd = (Get-Date),

    [Parameter()]
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'GmgConfig.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '..\..\..\scripts\common\IntegrationConfig.psm1') -Force

if ($PeriodEnd -lt $PeriodStart) {
    throw 'PeriodEnd must be greater than or equal to PeriodStart.'
}

function New-GmgArtifactFile {
    param([Parameter(Mandatory)] [string]$Path, [Parameter(Mandatory)] [object]$Content)
    $directory = Split-Path -Path $Path -Parent
    $null = New-Item -ItemType Directory -Path $directory -Force
    $Content | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding utf8
    $hashInfo = Write-GmgSha256File -Path $Path
    return [pscustomobject]@{ Path = $Path; Hash = $hashInfo.Hash }
}

Write-Verbose ("Loading GMG configuration for tier [{0}]." -f $ConfigurationTier)
$configuration = Get-GmgConfiguration -Tier $ConfigurationTier
Test-GmgConfiguration -Configuration $configuration

$resolvedOutputPath = (New-Item -ItemType Directory -Path $OutputPath -Force).FullName
$monitorScript = Join-Path $PSScriptRoot 'Monitor-Compliance.ps1'

Write-Verbose 'Collecting monitoring snapshot for evidence export.'
$snapshot = & $monitorScript -ConfigurationTier $ConfigurationTier -OutputPath $resolvedOutputPath -PassThru -Verbose:$($VerbosePreference -eq 'Continue')

$baseEnvelope = [ordered]@{
    solution    = $configuration.solution
    tier        = $ConfigurationTier
    periodStart = $PeriodStart.ToString('o')
    periodEnd   = $PeriodEnd.ToString('o')
    generatedAt = (Get-Date).ToString('o')
    runtimeMode = $snapshot.RuntimeMode
    warning     = $snapshot.StatusWarning
}

Write-Verbose 'Building copilot-model-inventory artifact.'
$inventoryArtifact = [ordered]@{} + $baseEnvelope
$inventoryArtifact['records'] = @($snapshot.InventoryRecords)
$inventoryFile = New-GmgArtifactFile -Path (Join-Path $resolvedOutputPath ("copilot-model-inventory-{0}.json" -f $ConfigurationTier)) -Content $inventoryArtifact

Write-Verbose 'Building validation-summary artifact.'
$validationArtifact = [ordered]@{} + $baseEnvelope
$validationArtifact['validationApproach'] = $configuration.validation_assessment_required
$validationArtifact['records'] = @($snapshot.ValidationRecords)
$validationFile = New-GmgArtifactFile -Path (Join-Path $resolvedOutputPath ("validation-summary-{0}.json" -f $ConfigurationTier)) -Content $validationArtifact

Write-Verbose 'Building ongoing-monitoring-log artifact.'
$monitoringArtifact = [ordered]@{} + $baseEnvelope
$monitoringArtifact['samplingCadence'] = $configuration.ongoingMonitoring.samplingCadence
$monitoringArtifact['retentionDays'] = $configuration.monitoring_log_retention_days
$monitoringArtifact['records'] = @($snapshot.MonitoringObservations)
$monitoringFile = New-GmgArtifactFile -Path (Join-Path $resolvedOutputPath ("ongoing-monitoring-log-{0}.json" -f $ConfigurationTier)) -Content $monitoringArtifact

Write-Verbose 'Building third-party-due-diligence artifact.'
$thirdPartyArtifact = [ordered]@{} + $baseEnvelope
$thirdPartyArtifact['reviewCadenceDays'] = $configuration.third_party_review_cadence_days
$thirdPartyArtifact['records'] = @($snapshot.ThirdPartyReview)
$thirdPartyFile = New-GmgArtifactFile -Path (Join-Path $resolvedOutputPath ("third-party-due-diligence-{0}.json" -f $ConfigurationTier)) -Content $thirdPartyArtifact

$controls = @(
    [pscustomobject]@{ controlId = '3.8a'; status = 'partial';      notes = 'Generative AI MRM scaffold present; live integration deferred. SR 11-7 / OCC 2011-12 interim principles applied to fill the SR 26-2 / OCC 2026-13 generative AI exclusion.' },
    [pscustomobject]@{ controlId = '3.8';  status = 'partial';      notes = 'AI model governance and risk assessment evidence captured from sample data; firm validation work still required.' },
    [pscustomobject]@{ controlId = '3.1';  status = 'monitor-only'; notes = 'Acceptable use linkage documented through inventory intended-use field.' },
    [pscustomobject]@{ controlId = '3.11'; status = 'partial';      notes = 'Third-party review cadence captured; vendor evidence references are sample placeholders.' },
    [pscustomobject]@{ controlId = '3.12'; status = 'monitor-only'; notes = 'Monitoring observations include escalation field; live AI incident response integration deferred.' }
)

$artifacts = @(
    [pscustomobject]@{ name = 'copilot-model-inventory';      type = 'json'; path = $inventoryFile.Path;   hash = $inventoryFile.Hash },
    [pscustomobject]@{ name = 'validation-summary';           type = 'json'; path = $validationFile.Path;  hash = $validationFile.Hash },
    [pscustomobject]@{ name = 'ongoing-monitoring-log';       type = 'json'; path = $monitoringFile.Path;  hash = $monitoringFile.Hash },
    [pscustomobject]@{ name = 'third-party-due-diligence';    type = 'json'; path = $thirdPartyFile.Path;  hash = $thirdPartyFile.Hash }
)

$packageSummary = [ordered]@{
    metadata  = [ordered]@{
        solution        = $configuration.solution
        solutionCode    = $configuration.solutionCode
        exportVersion   = (Get-CopilotGovEvidenceSchemaVersion)
        version         = $configuration.version
        tier            = $ConfigurationTier
        runtimeMode     = $snapshot.RuntimeMode
        warning         = $snapshot.StatusWarning
        exportedAt      = (Get-Date).ToString('o')
        periodStart     = $PeriodStart.ToString('yyyy-MM-dd')
        periodEnd       = $PeriodEnd.ToString('yyyy-MM-dd')
    }
    summary   = [ordered]@{
        overallStatus  = 'partial'
        recordCount    = (@($snapshot.InventoryRecords).Count + @($snapshot.ValidationRecords).Count + @($snapshot.MonitoringObservations).Count + 1)
        findingCount   = 0
        exceptionCount = ($controls | Where-Object { $_.status -ne 'implemented' }).Count
    }
    controls  = $controls
    artifacts = $artifacts
}

$packagePath = Join-Path $resolvedOutputPath ("20-generative-ai-model-governance-monitor-evidence-{0}.json" -f $ConfigurationTier)
$packageSummary | ConvertTo-Json -Depth 10 | Set-Content -Path $packagePath -Encoding utf8
$null = Write-GmgSha256File -Path $packagePath

Write-Host (
    "Evidence summary: GMG tier [{0}] wrote {1} artifacts to {2}." -f
    $ConfigurationTier,
    $artifacts.Count,
    $resolvedOutputPath
)

if ($PassThru) {
    return $packageSummary
}

$packageSummary
