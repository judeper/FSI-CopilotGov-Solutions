<#
.SYNOPSIS
Monitors governance posture and evidence freshness for the Regulatory Compliance Dashboard.
.DESCRIPTION
Reads the latest control status snapshot staged for Dataverse, calculates the weighted governance
maturity score, identifies stale evidence, and returns a structured compliance object suitable for
Power BI validation, alerting, or operational review.
.PARAMETER ConfigurationTier
Governance tier to evaluate.
.PARAMETER FreshnessThresholdHours
Maximum acceptable evidence age in hours. If not explicitly supplied, the value from the selected
tier configuration is used.
.PARAMETER OutputPath
Directory used to read the latest control status snapshot and write the monitoring report.
.EXAMPLE
pwsh .\Monitor-Compliance.ps1 -ConfigurationTier recommended
.EXAMPLE
pwsh .\Monitor-Compliance.ps1 -ConfigurationTier regulated -FreshnessThresholdHours 25 -OutputPath 'C:\Temp\rcd'
.NOTES
If no snapshot exists, the script returns a conservative fallback dataset based on expected control states.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [int]$FreshnessThresholdHours = 25,

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:SolutionName = 'Regulatory Compliance Dashboard'
$script:SolutionCode = 'RCD'
$script:RuntimeMode = 'documentation-first-fallback'
$script:RuntimeWarning = 'Fallback control states are documentation-first defaults and do not confirm a live Dataverse aggregator or published Power BI dashboard.'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path

Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force

function Get-ControlStatusSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SnapshotPath,

        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    if (Test-Path -Path $SnapshotPath) {
        $snapshotDocument = Get-Content -Path $SnapshotPath -Raw | ConvertFrom-Json
        if ($snapshotDocument.controls) {
            return @($snapshotDocument.controls)
        }

        return @($snapshotDocument)
    }

        return @(
            [pscustomobject]@{
                controlId = '3.7'
                controlTitle = 'Compliance Posture Reporting and Executive Dashboards'
                status = 'partial'
                score = [int](Get-CopilotGovStatusScore -Status 'partial')
                lastEvidenceDate = (Get-Date).AddHours(-6).ToString('o')
                solutionSlug = $script:SolutionCode
                tier = $Tier
                notes = 'Fallback snapshot entry used when no Dataverse seed file is available; the repository does not expose a live dashboard aggregator by default.'
            }
        [pscustomobject]@{
            controlId = '3.8'
            controlTitle = 'Regulatory Examination Readiness Reporting'
            status = 'partial'
            score = [int](Get-CopilotGovStatusScore -Status 'partial')
            lastEvidenceDate = (Get-Date).AddHours(-28).ToString('o')
            solutionSlug = $script:SolutionCode
            tier = $Tier
            notes = 'Fallback snapshot entry used when no Dataverse seed file is available.'
        }
        [pscustomobject]@{
            controlId = '3.12'
            controlTitle = 'Evidence Collection and Audit Attestation'
            status = 'monitor-only'
            score = [int](Get-CopilotGovStatusScore -Status 'monitor-only')
            lastEvidenceDate = (Get-Date).AddHours(-31).ToString('o')
            solutionSlug = $script:SolutionCode
            tier = $Tier
            notes = 'Fallback snapshot entry used when no Dataverse seed file is available.'
        }
        [pscustomobject]@{
            controlId = '3.13'
            controlTitle = 'Third-Party Audit and Regulatory Reporting'
            status = 'monitor-only'
            score = [int](Get-CopilotGovStatusScore -Status 'monitor-only')
            lastEvidenceDate = (Get-Date).AddHours(-42).ToString('o')
            solutionSlug = $script:SolutionCode
            tier = $Tier
            notes = 'Fallback snapshot entry used when no Dataverse seed file is available.'
        }
        [pscustomobject]@{
            controlId = '4.5'
            controlTitle = 'Copilot Usage Analytics and Adoption Reporting'
            status = 'monitor-only'
            score = [int](Get-CopilotGovStatusScore -Status 'monitor-only')
            lastEvidenceDate = (Get-Date).AddHours(-14).ToString('o')
            solutionSlug = $script:SolutionCode
            tier = $Tier
            notes = 'Fallback snapshot entry used when no Dataverse seed file is available.'
        }
        [pscustomobject]@{
            controlId = '4.7'
            controlTitle = 'Governance Maturity Scoring and Benchmarking'
            status = 'monitor-only'
            score = [int](Get-CopilotGovStatusScore -Status 'monitor-only')
            lastEvidenceDate = (Get-Date).AddHours(-18).ToString('o')
            solutionSlug = $script:SolutionCode
            tier = $Tier
            notes = 'Fallback snapshot entry used when no Dataverse seed file is available.'
        }
    )
}

function Measure-GovernanceMaturity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Controls,

        [Parameter(Mandatory)]
        [hashtable]$WeightMap
    )

    if ($Controls.Count -eq 0) {
        return [pscustomobject]@{
            GovernanceMaturityScore = 0
            ControlsImplementedPct = 0
            RAGStatus = 'Red'
        }
    }

    $weightedScoreTotal = 0.0
    $weightTotal = 0.0

    foreach ($control in $Controls) {
        $weight = if ($WeightMap.ContainsKey($control.controlId)) { [double]$WeightMap[$control.controlId] } else { 1.0 }
        $weightTotal += $weight
        $weightedScoreTotal += ([double]$control.score * $weight)
    }

    $maturityScore = if ($weightTotal -gt 0) { [math]::Round(($weightedScoreTotal / $weightTotal), 2) } else { 0 }
    $implementedCount = @($Controls | Where-Object { $_.status -eq 'implemented' }).Count
    $implementedPct = [math]::Round((($implementedCount / $Controls.Count) * 100), 2)
    $ragStatus = if ($maturityScore -ge 80) { 'Green' } elseif ($maturityScore -ge 50) { 'Amber' } else { 'Red' }

    return [pscustomobject]@{
        GovernanceMaturityScore = $maturityScore
        ControlsImplementedPct = $implementedPct
        RAGStatus = $ragStatus
    }
}

function Test-EvidenceFreshness {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Controls,

        [Parameter(Mandatory)]
        [int]$ThresholdHours
    )

    $referenceTime = Get-Date
    $staleEvidence = foreach ($control in $Controls) {
        $parsedEvidenceDate = $null
        if (-not [string]::IsNullOrWhiteSpace([string]$control.lastEvidenceDate)) {
            $parsedEvidenceDate = [datetime]$control.lastEvidenceDate
        }

        $hoursSinceEvidence = if ($parsedEvidenceDate) {
            [math]::Round(($referenceTime.ToUniversalTime() - $parsedEvidenceDate.ToUniversalTime()).TotalHours, 2)
        }
        else {
            $null
        }

        $isFresh = $parsedEvidenceDate -and ($hoursSinceEvidence -le $ThresholdHours)
        if (-not $isFresh) {
            [pscustomobject]@{
                controlId = $control.controlId
                controlTitle = $control.controlTitle
                status = $control.status
                lastEvidenceDate = $control.lastEvidenceDate
                hoursSinceEvidence = $hoursSinceEvidence
                reason = if ($parsedEvidenceDate) { 'Evidence age exceeds the configured freshness threshold.' } else { 'No evidence export date is available for this control.' }
            }
        }
    }

    $staleIds = @($staleEvidence | ForEach-Object { $_.controlId })
    $freshnessPct = if ($Controls.Count -gt 0) {
        [math]::Round(((($Controls.Count - @($staleEvidence).Count) / $Controls.Count) * 100), 2)
    }
    else {
        0
    }

    $controlsAtRisk = @(
        $Controls |
            Where-Object { ($_.status -ne 'implemented') -or ($staleIds -contains $_.controlId) } |
            Select-Object controlId, controlTitle, status, lastEvidenceDate, notes
    )

    return [pscustomobject]@{
        EvidenceFreshnessPct = $freshnessPct
        StaleEvidence = @($staleEvidence)
        ControlsAtRisk = $controlsAtRisk
    }
}

try {
    $defaultConfigPath = Join-Path $PSScriptRoot '..\config\default-config.json'
    $tierConfigPath = Join-Path $PSScriptRoot ("..\config\{0}.json" -f $ConfigurationTier)

    $defaultConfig = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json
    $tierConfig = Get-Content -Path $tierConfigPath -Raw | ConvertFrom-Json

    $effectiveThresholdHours = $FreshnessThresholdHours
    if (-not $PSBoundParameters.ContainsKey('FreshnessThresholdHours') -and $tierConfig.freshnessThresholdHours) {
        $effectiveThresholdHours = [int]$tierConfig.freshnessThresholdHours
    }

    $weightMap = @{}
    foreach ($weightProperty in $defaultConfig.maturityScoreWeights.PSObject.Properties) {
        $weightMap[$weightProperty.Name] = [double]$weightProperty.Value
    }

    $snapshotPath = Join-Path $OutputPath 'rcd-control-status-snapshot.json'
    $snapshotExists = Test-Path -Path $snapshotPath
    $controls = @(Get-ControlStatusSnapshot -SnapshotPath $snapshotPath -Tier $ConfigurationTier)
    $maturity = Measure-GovernanceMaturity -Controls $controls -WeightMap $weightMap
    $freshness = Test-EvidenceFreshness -Controls $controls -ThresholdHours $effectiveThresholdHours

    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $reportPath = Join-Path $OutputPath 'rcd-monitoring-status.json'
    $report = [pscustomobject]@{
        Solution = $script:SolutionName
        SolutionCode = $script:SolutionCode
        Tier = $ConfigurationTier
        GeneratedAt = (Get-Date).ToString('o')
        SnapshotSource = if ($snapshotExists) { $snapshotPath } else { 'fallback-defaults' }
        RuntimeMode = if ($snapshotExists) { 'seeded-or-live-snapshot' } else { $script:RuntimeMode }
        StatusWarning = if ($snapshotExists) { 'Monitoring reflects the supplied snapshot; confirm Dataverse ingestion and Power BI bindings before treating the dashboard as live.' } else { $script:RuntimeWarning }
        FreshnessThresholdHours = $effectiveThresholdHours
        GovernanceMaturityScore = $maturity.GovernanceMaturityScore
        ControlsImplementedPct = $maturity.ControlsImplementedPct
        EvidenceFreshnessPct = $freshness.EvidenceFreshnessPct
        RAGStatus = $maturity.RAGStatus
        StaleEvidence = $freshness.StaleEvidence
        ControlsAtRisk = $freshness.ControlsAtRisk
        Controls = $controls
    }

    if (-not $snapshotExists) {
        Write-Warning $script:RuntimeWarning
    }
    $report | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath -Encoding utf8
    Write-Output $report
}
catch {
    Write-Error -Message ('Compliance monitoring failed: {0}' -f $_.Exception.Message)
    throw
}
