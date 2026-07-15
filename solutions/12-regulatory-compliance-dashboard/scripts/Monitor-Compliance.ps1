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

function Resolve-OutputDirectoryPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

function Get-ControlStatusSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RcdSnapshotPath,

        [Parameter(Mandatory)]
        [string]$ExportSnapshotPath,

        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    $candidateSnapshots = @(
        [pscustomobject]@{
            source = 'rcd-control-status-snapshot'
            path = $RcdSnapshotPath
        },
        [pscustomobject]@{
            source = 'control-status-snapshot'
            path = $ExportSnapshotPath
        }
    )

    foreach ($candidate in $candidateSnapshots) {
        if (-not (Test-Path -Path $candidate.path -PathType Leaf)) {
            continue
        }

        $snapshotDocument = Get-Content -Path $candidate.path -Raw | ConvertFrom-Json
        $hasControlsProperty = ($snapshotDocument -isnot [System.Array]) -and ($snapshotDocument.PSObject.Properties.Name -contains 'controls')
        $controls = if ($hasControlsProperty -and $null -ne $snapshotDocument.controls) {
            @($snapshotDocument.controls)
        }
        else {
            @($snapshotDocument)
        }

        return [pscustomobject]@{
            Controls = $controls
            SnapshotSource = $candidate.source
            SnapshotPath = $candidate.path
            UsedFallback = $false
        }
    }

    return [pscustomobject]@{
        Controls = @(
            [pscustomobject]@{
                controlId = '3.7'
                controlTitle = 'Compliance Posture Reporting and Executive Dashboards'
                status = 'partial'
                score = [int](Get-CopilotGovStatusScore -Status 'partial')
                lastEvidenceDate = $null
                sourceLastModified = $null
                timestampProvenance = 'missing'
                freshnessState = 'unknown'
                hashState = 'unresolved'
                solutionSlug = $script:SolutionCode
                tier = $Tier
                notes = 'Fallback snapshot entry used when no Dataverse seed file is available; the repository does not expose a live dashboard aggregator by default.'
            }
        [pscustomobject]@{
            controlId = '3.8'
            controlTitle = 'Regulatory Examination Readiness Reporting'
            status = 'partial'
            score = [int](Get-CopilotGovStatusScore -Status 'partial')
            lastEvidenceDate = $null
            sourceLastModified = $null
            timestampProvenance = 'missing'
            freshnessState = 'unknown'
            hashState = 'unresolved'
            solutionSlug = $script:SolutionCode
            tier = $Tier
            notes = 'Fallback snapshot entry used when no Dataverse seed file is available.'
        }
        [pscustomobject]@{
            controlId = '3.12'
            controlTitle = 'Evidence Collection and Audit Attestation'
            status = 'monitor-only'
            score = [int](Get-CopilotGovStatusScore -Status 'monitor-only')
            lastEvidenceDate = $null
            sourceLastModified = $null
            timestampProvenance = 'missing'
            freshnessState = 'unknown'
            hashState = 'unresolved'
            solutionSlug = $script:SolutionCode
            tier = $Tier
            notes = 'Fallback snapshot entry used when no Dataverse seed file is available.'
        }
        [pscustomobject]@{
            controlId = '3.13'
            controlTitle = 'Third-Party Audit and Regulatory Reporting'
            status = 'monitor-only'
            score = [int](Get-CopilotGovStatusScore -Status 'monitor-only')
            lastEvidenceDate = $null
            sourceLastModified = $null
            timestampProvenance = 'missing'
            freshnessState = 'unknown'
            hashState = 'unresolved'
            solutionSlug = $script:SolutionCode
            tier = $Tier
            notes = 'Fallback snapshot entry used when no Dataverse seed file is available.'
        }
        [pscustomobject]@{
            controlId = '4.5'
            controlTitle = 'Copilot Usage Analytics and Adoption Reporting'
            status = 'monitor-only'
            score = [int](Get-CopilotGovStatusScore -Status 'monitor-only')
            lastEvidenceDate = $null
            sourceLastModified = $null
            timestampProvenance = 'missing'
            freshnessState = 'unknown'
            hashState = 'unresolved'
            solutionSlug = $script:SolutionCode
            tier = $Tier
            notes = 'Fallback snapshot entry used when no Dataverse seed file is available.'
        }
        [pscustomobject]@{
            controlId = '4.7'
            controlTitle = 'Governance Maturity Scoring and Benchmarking'
            status = 'monitor-only'
            score = [int](Get-CopilotGovStatusScore -Status 'monitor-only')
            lastEvidenceDate = $null
            sourceLastModified = $null
            timestampProvenance = 'missing'
            freshnessState = 'unknown'
            hashState = 'unresolved'
            solutionSlug = $script:SolutionCode
            tier = $Tier
            notes = 'Fallback snapshot entry used when no Dataverse seed file is available.'
        }
    )
        SnapshotSource = 'fallback-defaults'
        SnapshotPath = $null
        UsedFallback = $true
    }
}

function Get-TimestampState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control,

        [Parameter(Mandatory)]
        [datetimeoffset]$ReferenceTimeUtc
    )

    $sourceTimestamp = if (-not [string]::IsNullOrWhiteSpace([string]$Control.sourceLastModified)) {
        [string]$Control.sourceLastModified
    }
    elseif (-not [string]::IsNullOrWhiteSpace([string]$Control.lastEvidenceDate)) {
        [string]$Control.lastEvidenceDate
    }
    else {
        $null
    }

    if ([string]::IsNullOrWhiteSpace($sourceTimestamp)) {
        return [pscustomobject]@{
            timestamp = $null
            sourceTimestamp = $null
            timestampProvenance = 'missing'
            timestampState = 'missing'
            freshnessState = 'unknown'
            hoursSinceEvidence = $null
            reason = 'No source evidence timestamp is available for this control.'
            isTimestampGap = $true
        }
    }

    $styles = [System.Globalization.DateTimeStyles]::AssumeUniversal -bor [System.Globalization.DateTimeStyles]::AdjustToUniversal
    $parsedTimestamp = [datetimeoffset]::MinValue
    $isParsed = [datetimeoffset]::TryParse($sourceTimestamp, [System.Globalization.CultureInfo]::InvariantCulture, $styles, [ref]$parsedTimestamp)
    if (-not $isParsed) {
        return [pscustomobject]@{
            timestamp = $null
            sourceTimestamp = $sourceTimestamp
            timestampProvenance = 'invalid'
            timestampState = 'invalid-format'
            freshnessState = 'unknown'
            hoursSinceEvidence = $null
            reason = 'The source evidence timestamp is malformed and could not be parsed as UTC.'
            isTimestampGap = $true
        }
    }

    if ($parsedTimestamp -gt $ReferenceTimeUtc) {
        return [pscustomobject]@{
            timestamp = $null
            sourceTimestamp = $sourceTimestamp
            timestampProvenance = 'invalid'
            timestampState = 'future'
            freshnessState = 'unknown'
            hoursSinceEvidence = $null
            reason = 'The source evidence timestamp is in the future and cannot be treated as current evidence.'
            isTimestampGap = $true
        }
    }

    $hoursSinceEvidence = [math]::Round(($ReferenceTimeUtc - $parsedTimestamp).TotalHours, 2)
    return [pscustomobject]@{
        timestamp = $parsedTimestamp
        sourceTimestamp = $sourceTimestamp
        timestampProvenance = 'source-provided'
        timestampState = 'valid'
        freshnessState = 'fresh'
        hoursSinceEvidence = $hoursSinceEvidence
        reason = 'Source evidence timestamp was parsed successfully.'
        isTimestampGap = $false
    }
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

    $referenceTime = [datetimeoffset]::UtcNow
    $staleEvidence = foreach ($control in $Controls) {
        $timestampState = Get-TimestampState -Control $control -ReferenceTimeUtc $referenceTime
        $isFresh = ($timestampState.timestampProvenance -eq 'source-provided') -and ($timestampState.hoursSinceEvidence -le $ThresholdHours)
        if (-not $isFresh) {
            $freshnessState = if ($timestampState.timestampProvenance -eq 'source-provided') { 'stale' } else { 'unknown' }
            $reason = if ($timestampState.timestampProvenance -eq 'source-provided') {
                'Evidence age exceeds the configured freshness threshold.'
            }
            else {
                $timestampState.reason
            }

            [pscustomobject]@{
                controlId = $control.controlId
                controlTitle = $control.controlTitle
                status = $control.status
                lastEvidenceDate = $control.lastEvidenceDate
                sourceLastModified = $control.sourceLastModified
                sourceTimestamp = $timestampState.sourceTimestamp
                hoursSinceEvidence = $timestampState.hoursSinceEvidence
                timestampProvenance = $timestampState.timestampProvenance
                timestampState = $timestampState.timestampState
                freshnessState = $freshnessState
                reason = $reason
            }
        }
    }

    $staleIds = @($staleEvidence | ForEach-Object { $_.controlId })
    $timestampGapCount = @($staleEvidence | Where-Object { $_.timestampProvenance -in @('missing', 'invalid') }).Count
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
        TimestampGapCount = $timestampGapCount
        HasTimestampGap = ($timestampGapCount -gt 0)
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

    $resolvedOutputPath = Resolve-OutputDirectoryPath -Path $OutputPath
    $rcdSnapshotPath = Join-Path $resolvedOutputPath 'rcd-control-status-snapshot.json'
    $exportSnapshotPath = Join-Path $resolvedOutputPath 'control-status-snapshot.json'
    $snapshotResult = Get-ControlStatusSnapshot -RcdSnapshotPath $rcdSnapshotPath -ExportSnapshotPath $exportSnapshotPath -Tier $ConfigurationTier
    $controls = @($snapshotResult.Controls)
    $maturity = Measure-GovernanceMaturity -Controls $controls -WeightMap $weightMap
    $freshness = Test-EvidenceFreshness -Controls $controls -ThresholdHours $effectiveThresholdHours

    $null = New-Item -ItemType Directory -Path $resolvedOutputPath -Force
    $reportPath = Join-Path $resolvedOutputPath 'rcd-monitoring-status.json'
    $report = [pscustomobject]@{
        Solution = $script:SolutionName
        SolutionCode = $script:SolutionCode
        Tier = $ConfigurationTier
        GeneratedAt = (Get-Date).ToString('o')
        SnapshotSource = $snapshotResult.SnapshotSource
        SnapshotSourcePath = if ($snapshotResult.UsedFallback) { $null } else { $snapshotResult.SnapshotPath }
        RuntimeMode = if ($snapshotResult.UsedFallback) { $script:RuntimeMode } else { 'seeded-or-live-snapshot' }
        StatusWarning = if ($snapshotResult.UsedFallback) { $script:RuntimeWarning } else { ('Monitoring reflects snapshot source "{0}"; confirm Dataverse ingestion and Power BI bindings before treating the dashboard as live.' -f $snapshotResult.SnapshotSource) }
        FreshnessThresholdHours = $effectiveThresholdHours
        GovernanceMaturityScore = $maturity.GovernanceMaturityScore
        ControlsImplementedPct = $maturity.ControlsImplementedPct
        EvidenceFreshnessPct = $freshness.EvidenceFreshnessPct
        RAGStatus = $maturity.RAGStatus
        DataQualityGap = [bool]$freshness.HasTimestampGap
        TimestampGapControlCount = [int]$freshness.TimestampGapCount
        StaleEvidence = $freshness.StaleEvidence
        ControlsAtRisk = $freshness.ControlsAtRisk
        Controls = $controls
    }

    if ($snapshotResult.UsedFallback) {
        Write-Warning $script:RuntimeWarning
    }
    else {
        Write-Verbose ('Snapshot source used: {0} ({1})' -f $snapshotResult.SnapshotSource, $snapshotResult.SnapshotPath)
    }
    if ($freshness.HasTimestampGap) {
        Write-Warning ('Evidence freshness data-quality gap: {0} control(s) have missing or invalid source evidence timestamps and are reported as unknown, not current.' -f $freshness.TimestampGapCount)
    }
    $report | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath -Encoding utf8
    Write-Output $report
}
catch {
    Write-Error -Message ('Compliance monitoring failed: {0}' -f $_.Exception.Message)
    throw
}
