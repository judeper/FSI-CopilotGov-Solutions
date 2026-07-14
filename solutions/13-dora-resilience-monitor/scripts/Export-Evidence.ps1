<#
.SYNOPSIS
    Exports DORA operational-resilience evidence for regulatory examination support.

.DESCRIPTION
    Builds service-health, incident-register, and resilience-test artifacts for the DRM
    solution and packages them with the shared evidence export module. The exported
    package supports compliance with DORA operational-resilience evidence expectations
    while preserving honest control-state reporting for monitor-only and partial areas.

.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.

.PARAMETER OutputPath
    Path for exported evidence artifacts.

.PARAMETER PeriodStart
    Beginning of the evidence window.

.PARAMETER PeriodEnd
    End of the evidence window.

.PARAMETER PassThru
    Returns the evidence summary object after writing artifacts and the package.

.EXAMPLE
    .\Export-Evidence.ps1 -ConfigurationTier recommended -Verbose

.EXAMPLE
    .\Export-Evidence.ps1 -ConfigurationTier regulated -OutputPath .\artifacts -PeriodStart (Get-Date).AddDays(-30) -PeriodEnd (Get-Date)

.NOTES
    Solution: DORA Operational Resilience Monitor (DRM)
    Version:     v0.1.3
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

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'DrmConfig.psm1') -Force

function New-DrmArtifactFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [object]$Content
    )

    $directory = Split-Path -Path $Path -Parent
    $null = New-Item -ItemType Directory -Path $directory -Force
    $Content | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding utf8
    $hashInfo = Write-CopilotGovSha256File -Path $Path

    return [pscustomobject]@{
        Path = $Path
        Hash = $hashInfo.Hash
    }
}

function Get-DrmPackageArtifactPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactPath,

        [Parameter(Mandatory)]
        [string]$PackageRoot
    )

    $resolvedArtifact = Resolve-Path -Path $ArtifactPath -ErrorAction Stop
    $resolvedPackageRoot = Resolve-Path -Path $PackageRoot -ErrorAction Stop

    if ($resolvedArtifact.Provider.Name -eq 'FileSystem' -and $resolvedPackageRoot.Provider.Name -eq 'FileSystem') {
        return ([IO.Path]::GetRelativePath($resolvedPackageRoot.Path, $resolvedArtifact.Path) -replace '\\', '/')
    }

    return [IO.Path]::GetFileName($resolvedArtifact.Path)
}

function ConvertTo-DrmNullableDateTime {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return $null
    }

    $timestampText = [string]$Value
    if ([string]::IsNullOrWhiteSpace($timestampText)) {
        return $null
    }

    return ([datetime]$timestampText).ToUniversalTime()
}

function Test-DrmSeverityAtOrAbove {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Severity,

        [Parameter(Mandatory)]
        [string]$Threshold
    )

    $severityKey = $Severity.Trim().ToLowerInvariant()
    $thresholdKey = $Threshold.Trim().ToLowerInvariant()
    $severityRank = @{
        minor = 1
        significant = 2
        major = 3
    }

    if (-not $severityRank.ContainsKey($severityKey) -or -not $severityRank.ContainsKey($thresholdKey)) {
        return ($severityKey -eq $thresholdKey)
    }

    return ($severityRank[$severityKey] -ge $severityRank[$thresholdKey])
}

if ($PeriodEnd -lt $PeriodStart) {
    throw 'PeriodEnd must be greater than or equal to PeriodStart.'
}

Write-Verbose ("Loading DRM configuration for tier [{0}]." -f $ConfigurationTier)
$configuration = Get-DrmConfiguration -Tier $ConfigurationTier
Test-DrmConfiguration -Configuration $configuration

$resolvedOutputPath = (New-Item -ItemType Directory -Path $OutputPath -Force).FullName
$monitorScript = Join-Path $PSScriptRoot 'Monitor-Compliance.ps1'

Write-Verbose 'Collecting monitoring status for evidence export.'
$complianceStatus = & $monitorScript -ConfigurationTier $ConfigurationTier -OutputPath $resolvedOutputPath -PassThru -Verbose:$($VerbosePreference -eq 'Continue')

Write-Verbose 'Building service-health-log artifact.'
$serviceHealthRecords = @(
    foreach ($entry in @($complianceStatus.ServiceHealthSummary)) {
        [pscustomobject]@{
            service = $entry.Service
            status = $entry.Status
            collectedAt = $entry.CollectionTime
            checkedAt = $entry.CollectionTime
            sourceLastModified = $entry.SourceLastModified
            timestampProvenance = $entry.TimestampProvenance
            freshness = $entry.Freshness
            pollingIntervalMinutes = $configuration.serviceHealthPollingIntervalMinutes
            retentionDays = $configuration.evidenceRetentionDays
            sourceEndpoint = $entry.Source
            runtimeMode = $entry.RuntimeMode
            incidentId = $entry.IncidentId
            impactDescription = $entry.ImpactDescription
        }
    }
)
$serviceHealthArtifact = [ordered]@{
    solution = $configuration.solution
    tier = $ConfigurationTier
    reportingPeriod = [ordered]@{
        periodStart = $PeriodStart.ToUniversalTime().ToString('o')
        periodEnd = $PeriodEnd.ToUniversalTime().ToString('o')
    }
    periodStart = $PeriodStart.ToUniversalTime().ToString('o')
    periodEnd = $PeriodEnd.ToUniversalTime().ToString('o')
    collectionTime = $complianceStatus.CollectionTime
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    freshness = $complianceStatus.Freshness
    pollingIntervalMinutes = $configuration.serviceHealthPollingIntervalMinutes
    retentionDays = $configuration.evidenceRetentionDays
    runtimeMode = $complianceStatus.RuntimeMode
    warning = $complianceStatus.StatusWarning
    records = $serviceHealthRecords
}
$serviceHealthFile = New-DrmArtifactFile -Path (Join-Path $resolvedOutputPath ("service-health-log-{0}.json" -f $ConfigurationTier)) -Content $serviceHealthArtifact

Write-Verbose 'Building incident-register artifact.'
$regulatoryNotificationThreshold = if ($configuration.incidentClassification.Contains('regulatoryNotificationThreshold')) {
    $configuration.incidentClassification.regulatoryNotificationThreshold
} else {
    'major'
}
$notificationWindowHours = if ($configuration.incidentClassification.Contains('notificationWindowHours')) { [int]$configuration.incidentClassification.notificationWindowHours } else { $null }
$awarenessBoundHours = if ($configuration.incidentClassification.Contains('initialNotificationLatestFromAwarenessHours')) { [int]$configuration.incidentClassification.initialNotificationLatestFromAwarenessHours } else { $null }
$intermediateReportWindowHours = if ($configuration.incidentClassification.Contains('intermediateReportWindowHours')) { [int]$configuration.incidentClassification.intermediateReportWindowHours } else { $null }
$finalReportWindowDays = if ($configuration.incidentClassification.Contains('finalReportWindowDays')) { [int]$configuration.incidentClassification.finalReportWindowDays } else { $null }
$requiresRootCauseAnalysis = if ($configuration.incidentClassification.Contains('requireRootCauseAnalysis')) { [bool]$configuration.incidentClassification.requireRootCauseAnalysis } else { $false }
$rcaWindowDays = if ($configuration.incidentClassification.Contains('rcaWindowDays')) { [int]$configuration.incidentClassification.rcaWindowDays } else { $null }
$incidentRecords = @(
    foreach ($incident in @($complianceStatus.IncidentFindings)) {
        $detectedAt = ConvertTo-DrmNullableDateTime -Value $incident.detectedAt
        # DORA (Commission Delegated Regulation (EU) 2025/301, Art. 5) anchors each stage to a distinct
        # event: the initial notification to classification-as-major, the intermediate report to the
        # initial notification, and the final report to the intermediate report. This scaffold uses the
        # detection timestamp as a representative-sample proxy and chains subsequent stages from the prior
        # stage's due date so the arithmetic honors the official anchor order. Operators must recompute
        # against actual classification and submission timestamps.
        $initialNotificationDue = if ($null -ne $detectedAt -and $null -ne $notificationWindowHours) { $detectedAt.AddHours($notificationWindowHours) } else { $null }
        $initialNotificationLatest = if ($null -ne $detectedAt -and $null -ne $awarenessBoundHours) { $detectedAt.AddHours($awarenessBoundHours) } else { $null }
        $intermediateAnchor = if ($null -ne $initialNotificationDue) { $initialNotificationDue } else { $detectedAt }
        $intermediateReportDue = if ($null -ne $intermediateAnchor -and $null -ne $intermediateReportWindowHours) { $intermediateAnchor.AddHours($intermediateReportWindowHours) } else { $null }
        $finalAnchor = if ($null -ne $intermediateReportDue) { $intermediateReportDue } else { $detectedAt }
        $finalReportDue = if ($null -ne $finalAnchor -and $null -ne $finalReportWindowDays) { $finalAnchor.AddDays($finalReportWindowDays) } else { $null }
        $rootCauseAnalysisDue = if ($null -ne $detectedAt -and $null -ne $rcaWindowDays) { $detectedAt.AddDays($rcaWindowDays) } else { $null }
        $timelineGap = ($null -eq $detectedAt)

        [pscustomobject]@{
            incidentId = $incident.incidentId
            severity = $incident.severity
            affectedService = $incident.affectedService
            detectedAt = $incident.detectedAt
            reportedAt = $incident.reportedAt
            status = $incident.status
            rtoActual = if ($null -ne $incident.downtimeMinutes) { [math]::Round(([double]$incident.downtimeMinutes / 60), 2) } else { $null }
            rpoActual = $null
            affectedUserPct = $incident.affectedUserPct
            impactDescription = $incident.impactDescription
            regulatoryNotificationThreshold = $regulatoryNotificationThreshold
            regulatoryNotificationRequired = Test-DrmSeverityAtOrAbove -Severity ([string]$incident.severity) -Threshold $regulatoryNotificationThreshold
            notificationWindowHours = $notificationWindowHours
            initialNotificationDueAt = if ($null -ne $initialNotificationDue) { $initialNotificationDue.ToString('o') } else { $null }
            initialNotificationLatestFromAwarenessHours = $awarenessBoundHours
            initialNotificationLatestFromAwarenessAt = if ($null -ne $initialNotificationLatest) { $initialNotificationLatest.ToString('o') } else { $null }
            intermediateReportWindowHours = $intermediateReportWindowHours
            intermediateReportDueAt = if ($null -ne $intermediateReportDue) { $intermediateReportDue.ToString('o') } else { $null }
            finalReportWindowDays = $finalReportWindowDays
            finalReportDueAt = if ($null -ne $finalReportDue) { $finalReportDue.ToString('o') } else { $null }
            reportingTimelineGap = $timelineGap
            rootCauseAnalysisStatus = if ($requiresRootCauseAnalysis) { 'pending' } else { 'not-required' }
            rcaWindowDays = $rcaWindowDays
            rootCauseAnalysisDueAt = if ($null -ne $rootCauseAnalysisDue) { $rootCauseAnalysisDue.ToString('o') } else { $null }
            notes = $incident.classificationNote
        }
    }
)
$incidentRegisterArtifact = [ordered]@{
    solution = $configuration.solution
    tier = $ConfigurationTier
    reportingPeriod = [ordered]@{
        periodStart = $PeriodStart.ToUniversalTime().ToString('o')
        periodEnd = $PeriodEnd.ToUniversalTime().ToString('o')
    }
    periodStart = $PeriodStart.ToUniversalTime().ToString('o')
    periodEnd = $PeriodEnd.ToUniversalTime().ToString('o')
    collectionTime = $complianceStatus.CollectionTime
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    freshness = $complianceStatus.Freshness
    runtimeMode = $complianceStatus.RuntimeMode
    warning = $complianceStatus.StatusWarning
    reportingTimeline = [ordered]@{
        initialNotificationWindowHours = $notificationWindowHours
        initialNotificationLatestFromAwarenessHours = $awarenessBoundHours
        intermediateReportWindowHours = $intermediateReportWindowHours
        finalReportWindowDays = $finalReportWindowDays
        rootCauseAnalysisWindowDays = $rcaWindowDays
        regulatorySource = 'Regulation (EU) 2022/2554 (DORA), Art. 19; Commission Delegated Regulation (EU) 2025/301, Art. 5 (reporting time limits); Commission Implementing Regulation (EU) 2025/302 (reporting templates); Commission Delegated Regulation (EU) 2024/1772 (major-incident classification thresholds).'
        anchorSemantics = 'Official DORA time limits anchor the initial notification to classification as a major incident (no later than 24 hours from awareness), the intermediate report to submission of the initial notification, and the final report (one month) to submission of the intermediate report. This scaffold derives indicative due dates from the detection timestamp as a representative-sample simplification and chains later stages from the prior stage due date.'
        automationScope = 'Reference due-date metadata only; this scaffold does not classify incidents as major for regulatory purposes and does not submit regulatory notices automatically.'
        disclaimer = 'Indicative reference values only. Not legal advice and not proof of DORA compliance. Confirm obligations and exact timings with EU legal counsel and the competent authority.'
    }
    records = $incidentRecords
}
$incidentRegisterFile = New-DrmArtifactFile -Path (Join-Path $resolvedOutputPath ("incident-register-{0}.json" -f $ConfigurationTier)) -Content $incidentRegisterArtifact

Write-Verbose 'Building resilience-test-results artifact.'
$resilienceOutcome = if (-not $complianceStatus.ResilienceTestStatus.Enabled) {
    'tracking-disabled'
}
elseif ($complianceStatus.ResilienceTestStatus.Status -eq 'overdue') {
    'overdue'
}
elseif ($complianceStatus.ResilienceTestStatus.Status -eq 'missing') {
    'scheduled'
}
elseif ($complianceStatus.ResilienceTestStatus.LastTestDate) {
    'recorded'
}
else {
    'scheduled'
}

$resilienceRecords = @(
    [pscustomobject]@{
        testType = if ($ConfigurationTier -eq 'regulated') { 'Annual Copilot dependency resilience exercise and DORA reporting drill' } else { 'Annual Copilot dependency resilience exercise' }
        scheduledDate = if ($complianceStatus.ResilienceTestStatus.NextDueDate) { $complianceStatus.ResilienceTestStatus.NextDueDate } else { $PeriodEnd.ToString('o') }
        completedDate = $complianceStatus.ResilienceTestStatus.LastTestDate
        outcome = $resilienceOutcome
        rtoTargetHours = $complianceStatus.ResilienceTestStatus.RtoTargetHours
        rtoActual = $null
        rpoTargetHours = $complianceStatus.ResilienceTestStatus.RpoTargetHours
        rpoActual = $null
        notes = $complianceStatus.ResilienceTestStatus.Notes
    }
)
$resilienceArtifact = [ordered]@{
    solution = $configuration.solution
    tier = $ConfigurationTier
    reportingPeriod = [ordered]@{
        periodStart = $PeriodStart.ToUniversalTime().ToString('o')
        periodEnd = $PeriodEnd.ToUniversalTime().ToString('o')
    }
    periodStart = $PeriodStart.ToUniversalTime().ToString('o')
    periodEnd = $PeriodEnd.ToUniversalTime().ToString('o')
    collectionTime = $complianceStatus.CollectionTime
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    freshness = $complianceStatus.Freshness
    runtimeMode = $complianceStatus.RuntimeMode
    warning = $complianceStatus.StatusWarning
    records = $resilienceRecords
}
$resilienceFile = New-DrmArtifactFile -Path (Join-Path $resolvedOutputPath ("resilience-test-results-{0}.json" -f $ConfigurationTier)) -Content $resilienceArtifact

$controls = @(
    [pscustomobject]@{
        controlId = '2.7'
        status = 'monitor-only'
        notes = 'Data residency monitoring requires tenant geo configuration and approved-region review to complete the control evidence set.'
    },
    [pscustomobject]@{
        controlId = '4.9'
        status = 'partial'
        notes = 'Incident reporting and DORA-aligned severity classification are included in the exported incident register, but repository monitoring still relies on stub or sample service-health input.'
    },
    [pscustomobject]@{
        controlId = '4.10'
        status = 'partial'
        notes = 'Resilience test tracking and recovery objectives are documented; automated failover validation requires additional tenant-specific engineering.'
    },
    [pscustomobject]@{
        controlId = '4.11'
        status = 'monitor-only'
        notes = 'Sentinel enrichment requires a separately provisioned workspace and customer-defined analytics rules. Microsoft does not publish a native Sentinel data connector for Microsoft 365 service health or Copilot interaction events; ingestion relies on the Microsoft 365 (Office 365) connector for supported audit workloads and/or a customer-built path from the Office 365 Management API. Sentinel is managed in the Microsoft Defender portal.'
    }
)

$recordCount = $serviceHealthRecords.Count + $incidentRecords.Count + $resilienceRecords.Count
$findingCount = $incidentRecords.Count
if ($complianceStatus.ResilienceTestStatus.Status -in @('missing', 'overdue')) {
    $findingCount++
}
$exceptionCount = ($controls | Where-Object { $_.status -ne 'implemented' }).Count

$resultArtifacts = @(
    [pscustomobject]@{ name = 'service-health-log'; type = 'json'; path = $serviceHealthFile.Path; hash = $serviceHealthFile.Hash },
    [pscustomobject]@{ name = 'incident-register'; type = 'json'; path = $incidentRegisterFile.Path; hash = $incidentRegisterFile.Hash },
    [pscustomobject]@{ name = 'resilience-test-results'; type = 'json'; path = $resilienceFile.Path; hash = $resilienceFile.Hash }
)

$packageArtifacts = @(
    [pscustomobject]@{
        name = 'service-health-log'
        type = 'json'
        path = Get-DrmPackageArtifactPath -ArtifactPath $serviceHealthFile.Path -PackageRoot $resolvedOutputPath
        hash = $serviceHealthFile.Hash
    },
    [pscustomobject]@{
        name = 'incident-register'
        type = 'json'
        path = Get-DrmPackageArtifactPath -ArtifactPath $incidentRegisterFile.Path -PackageRoot $resolvedOutputPath
        hash = $incidentRegisterFile.Hash
    },
    [pscustomobject]@{
        name = 'resilience-test-results'
        type = 'json'
        path = Get-DrmPackageArtifactPath -ArtifactPath $resilienceFile.Path -PackageRoot $resolvedOutputPath
        hash = $resilienceFile.Hash
    }
)

$summary = @{
    overallStatus = 'partial'
    recordCount = $recordCount
    findingCount = $findingCount
    exceptionCount = $exceptionCount
}

Write-Verbose 'Creating DRM evidence package.'
$package = Export-SolutionEvidencePackage `
    -Solution $configuration.solution `
    -SolutionCode $configuration.solutionCode `
    -Tier $ConfigurationTier `
    -OutputPath $resolvedOutputPath `
    -Summary $summary `
    -Controls $controls `
    -Artifacts $packageArtifacts `
    -ExpectedArtifacts @($configuration.evidenceOutputs) `
    -AdditionalMetadata @{
        runtimeMode = $complianceStatus.RuntimeMode
        warning = $complianceStatus.StatusWarning
        dataSourceMode = $complianceStatus.DataSourceMode
        collectionTime = $complianceStatus.CollectionTime
        freshness = $complianceStatus.Freshness
    }

$result = [pscustomobject]@{
    Summary = $summary
    Controls = $controls
    Artifacts = $resultArtifacts
    Package = $package
    RuntimeMode = $complianceStatus.RuntimeMode
}

if ($PassThru) {
    return $result
}

$result
