<#
.SYNOPSIS
    Monitors M365 service health and classifies incidents for DORA operational-resilience support.

.DESCRIPTION
    Collects Microsoft 365 Copilot dependency health observations, applies a DORA Art. 17
    severity model, evaluates resilience-test currency, and emits a structured compliance
    status object for dashboard and evidence workflows. The repository implementation uses
    a local stub data source and returns representative sample results; Microsoft Graph
    integration is required for live tenant polling. The script remains testable without
    external connectivity.

.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.

.PARAMETER OutputPath
    Path for compliance snapshots and monitoring artifacts.

.PARAMETER TenantId
    Microsoft Entra ID tenant ID. Defaults to AZURE_TENANT_ID.

.PARAMETER ClientId
    Microsoft Entra ID application ID. Defaults to AZURE_CLIENT_ID.

.PARAMETER ClientSecret
    SecureString client secret used for Graph authentication when a live implementation is added.

.PARAMETER PassThru
    Returns the compliance status object after writing the monitoring snapshot.

.EXAMPLE
    .\Monitor-Compliance.ps1 -ConfigurationTier recommended -Verbose

.EXAMPLE
    .\Monitor-Compliance.ps1 -ConfigurationTier regulated -TenantId $env:AZURE_TENANT_ID -ClientId $env:AZURE_CLIENT_ID -ClientSecret (Read-Host -AsSecureString)

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
    [string]$TenantId = $env:AZURE_TENANT_ID,

    [Parameter()]
    [string]$ClientId = $env:AZURE_CLIENT_ID,

    [Parameter()]
    [System.Security.SecureString]$ClientSecret,

    [Parameter()]
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'DrmConfig.psm1') -Force
$script:StubWarning = 'Service health output came from the local Graph stub and does not confirm live Microsoft 365 polling.'
$script:SampleWarning = 'Service health output came from DRM_SERVICE_HEALTH_SAMPLE_JSON and does not confirm live Microsoft Graph polling.'

function Get-DrmUtcTimestamp {
    [CmdletBinding()]
    param()

    return [datetime]::UtcNow.ToString('o')
}

function Resolve-DrmStalenessThreshold {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)]
        [int]$PollingIntervalMinutes
    )

    if (-not [string]::IsNullOrWhiteSpace($env:DRM_FRESHNESS_THRESHOLD_MINUTES)) {
        $parsed = 0
        if ([int]::TryParse($env:DRM_FRESHNESS_THRESHOLD_MINUTES, [ref]$parsed) -and $parsed -gt 0) {
            return $parsed
        }
    }

    # Default: a source record is stale when older than three polling cycles, with a 60-minute floor.
    return [math]::Max(($PollingIntervalMinutes * 3), 60)
}

function Get-DrmFreshness {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CollectionTime,

        [Parameter()]
        [AllowNull()]
        [string]$SourceLastModified,

        [Parameter(Mandatory)]
        [int]$StalenessThresholdMinutes,

        [Parameter(Mandatory)]
        [string]$RuntimeMode,

        [Parameter()]
        [ValidateSet('source-provided', 'detected-only', 'missing', 'synthetic-stub')]
        [string]$Provenance = 'source-provided'
    )

    $collectionDt = $null
    try {
        $collectionDt = [datetime]::Parse($CollectionTime, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
    }
    catch {
        $collectionDt = $null
    }

    $base = [ordered]@{
        collectionTime = $CollectionTime
        sourceLastModified = $null
        ageMinutes = $null
        stalenessThresholdMinutes = $StalenessThresholdMinutes
        status = 'unknown'
        isStale = $false
        hasTimestampGap = $true
        provenance = $Provenance
        runtimeMode = $RuntimeMode
        note = 'Source last-modified timestamp is missing or invalid; freshness could not be evaluated and is surfaced as an explicit gap.'
    }

    if ($Provenance -eq 'synthetic-stub') {
        $base.status = 'not-applicable'
        $base.hasTimestampGap = $false
        $base.note = 'Synthetic local-stub record; no external source last-modified time exists, so freshness is not applicable.'
        return [pscustomobject]$base
    }

    if ([string]::IsNullOrWhiteSpace($SourceLastModified)) {
        return [pscustomobject]$base
    }

    $sourceDt = $null
    try {
        $sourceDt = [datetime]::Parse($SourceLastModified, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
    }
    catch {
        $base.note = 'Source last-modified timestamp is not a valid ISO 8601 value; freshness is surfaced as an explicit gap.'
        return [pscustomobject]$base
    }

    if ($null -eq $collectionDt) {
        $base.sourceLastModified = $SourceLastModified
        $base.note = 'Collection timestamp is missing or invalid; freshness could not be evaluated.'
        return [pscustomobject]$base
    }

    $ageMinutes = [math]::Round((($collectionDt.ToUniversalTime()) - ($sourceDt.ToUniversalTime())).TotalMinutes, 2)
    $status = if ($ageMinutes -lt 0) {
        'invalid-future'
    }
    elseif ($ageMinutes -gt $StalenessThresholdMinutes) {
        'stale'
    }
    else {
        'current'
    }

    $note = switch ($status) {
        'current' { 'Source last-modified time is within the staleness threshold.' }
        'stale' { 'Source last-modified time exceeds the staleness threshold; downstream evidence must not be treated as current.' }
        'invalid-future' { 'Source last-modified time is after the collection time; timestamp is invalid and must be reviewed.' }
        default { 'Freshness evaluated.' }
    }

    return [pscustomobject]@{
        collectionTime = $CollectionTime
        sourceLastModified = $SourceLastModified
        ageMinutes = $ageMinutes
        stalenessThresholdMinutes = $StalenessThresholdMinutes
        status = $status
        isStale = ($status -ne 'current')
        hasTimestampGap = $false
        provenance = $Provenance
        runtimeMode = $RuntimeMode
        note = $note
    }
}

function Resolve-DrmClientSecret {
    [CmdletBinding()]
    param(
        [Parameter()]
        [System.Security.SecureString]$Secret
    )

    if ($null -ne $Secret) {
        return $Secret
    }

    if (-not [string]::IsNullOrWhiteSpace($env:AZURE_CLIENT_SECRET)) {
        # IDENTITY-STANDARD: legacy-client-secret -- TODO: migrate to managed identity (see docs/security/managed-identity-standard.md)
        # Use AppendChar loop so the plaintext secret is never materialized as a single .NET string;
        # ConvertTo-SecureString -AsPlainText is flagged by PSScriptAnalyzer (PSAvoidUsingConvertToSecureStringWithPlainText).
        $secureSecret = New-Object System.Security.SecureString
        foreach ($char in $env:AZURE_CLIENT_SECRET.ToCharArray()) {
            $secureSecret.AppendChar($char)
        }
        $secureSecret.MakeReadOnly()
        return $secureSecret
    }

    return $null
}

function Get-DrmServiceHealthStatusProfile {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [string]$Status
    )

    $statusText = if ([string]::IsNullOrWhiteSpace($Status)) { 'unknown' } else { $Status.Trim() }
    $statusKey = $statusText.ToLowerInvariant()
    $healthyStatuses = @('healthy', 'serviceoperational')
    $closedStatuses = @('servicerestored', 'restored', 'resolved', 'verifyingservice', 'falsepositive', 'postincidentreviewpublished', 'mitigated', 'mitigatedexternal', 'resolvedexternal')
    $activeIssueStatuses = @('degraded', 'advisory', 'interruption', 'investigating', 'servicedegradation', 'serviceinterruption', 'restoringservice', 'extendedrecovery', 'investigationsuspended', 'confirmed', 'reported')

    if ($healthyStatuses -contains $statusKey) {
        return [pscustomobject]@{
            NormalizedStatus = 'Healthy'
            IsClassifiable = $false
            IsOpenIncident = $false
            EscalatesMinorThreshold = $false
        }
    }

    if ($closedStatuses -contains $statusKey) {
        return [pscustomobject]@{
            NormalizedStatus = 'Resolved'
            IsClassifiable = $false
            IsOpenIncident = $false
            EscalatesMinorThreshold = $false
        }
    }

    if ($activeIssueStatuses -contains $statusKey) {
        return [pscustomobject]@{
            NormalizedStatus = 'ActiveIssue'
            IsClassifiable = $true
            IsOpenIncident = $true
            EscalatesMinorThreshold = $true
        }
    }

    return [pscustomobject]@{
        NormalizedStatus = $statusText
        IsClassifiable = $true
        IsOpenIncident = $true
        EscalatesMinorThreshold = $false
    }
}

function Get-ServiceHealthStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$MonitoredServices,

        [Parameter()]
        [string]$TenantId,

        [Parameter()]
        [string]$ClientId,

        [Parameter()]
        [System.Security.SecureString]$ClientSecret,

        [Parameter(Mandatory)]
        [int]$StalenessThresholdMinutes
    )

    $criticalServices = @('Exchange Online', 'SharePoint Online', 'Microsoft Teams', 'Microsoft Graph', 'Microsoft 365 Copilot')
    $samplePayload = $env:DRM_SERVICE_HEALTH_SAMPLE_JSON

    if (-not [string]::IsNullOrWhiteSpace($samplePayload)) {
        Write-Verbose 'Using DRM_SERVICE_HEALTH_SAMPLE_JSON to simulate Graph service-health output.'
        $sampleEntries = @($samplePayload | ConvertFrom-Json -AsHashtable)

        return @(
            foreach ($entry in $sampleEntries) {
                $collectionTime = Get-DrmUtcTimestamp
                $serviceName = if ($entry.Contains('service')) { [string]$entry.service } else { 'Unknown Service' }
                $detectedProvided = $entry.Contains('detectedAt') -and -not [string]::IsNullOrWhiteSpace([string]$entry.detectedAt)
                $lastUpdatedProvided = $entry.Contains('lastUpdated') -and -not [string]::IsNullOrWhiteSpace([string]$entry.lastUpdated)
                # Source timestamps are only trusted when supplied; missing values become an explicit
                # null so freshness surfaces a gap instead of silently defaulting to the collection time.
                $detectedAt = if ($detectedProvided) { ([datetime]$entry.detectedAt).ToUniversalTime().ToString('o') } else { $null }
                $sourceLastModified = if ($lastUpdatedProvided) {
                    ([datetime]$entry.lastUpdated).ToUniversalTime().ToString('o')
                }
                elseif ($detectedProvided) {
                    $detectedAt
                }
                else {
                    $null
                }
                $provenance = if ($lastUpdatedProvided) { 'source-provided' } elseif ($detectedProvided) { 'detected-only' } else { 'missing' }
                $downtimeMinutes = if ($entry.Contains('downtimeMinutes')) { [double]$entry.downtimeMinutes } else { 0 }
                $affectedUserPct = if ($entry.Contains('affectedUserPct')) { [double]$entry.affectedUserPct } else { 0 }
                $impactDescription = if ($entry.Contains('impactDescription')) { [string]$entry.impactDescription } else { 'Sample service-health event.' }
                $isCritical = if ($entry.Contains('isCritical')) { [bool]$entry.isCritical } else { $serviceName -in $criticalServices }
                $status = if ($entry.Contains('status')) {
                    [string]$entry.status
                }
                elseif ($entry.Contains('serviceHealthStatus')) {
                    [string]$entry.serviceHealthStatus
                }
                else {
                    'Degraded'
                }

                $freshness = Get-DrmFreshness -CollectionTime $collectionTime -SourceLastModified $sourceLastModified -StalenessThresholdMinutes $StalenessThresholdMinutes -RuntimeMode 'sample-json' -Provenance $provenance

                [pscustomobject]@{
                    Service = $serviceName
                    Status = $status
                    IncidentId = if ($entry.Contains('incidentId')) { [string]$entry.incidentId } else { $null }
                    DetectedAt = $detectedAt
                    LastUpdated = $sourceLastModified
                    CollectionTime = $collectionTime
                    SourceLastModified = $sourceLastModified
                    TimestampProvenance = $provenance
                    Freshness = $freshness
                    DowntimeMinutes = $downtimeMinutes
                    AffectedUserPct = $affectedUserPct
                    ImpactDescription = $impactDescription
                    IsCritical = $isCritical
                    Source = 'sample-json-env'
                    RuntimeMode = 'sample-json'
                    Warning = $script:SampleWarning
                }
            }
        )
    }

    $stubWarning = if ([string]::IsNullOrWhiteSpace($TenantId) -or [string]::IsNullOrWhiteSpace($ClientId) -or $null -eq $ClientSecret) {
        $script:StubWarning
    }
    else {
        'Client credentials were supplied, but live monitoring is not wired in this repository; local stub records were emitted instead.'
    }

    if ([string]::IsNullOrWhiteSpace($TenantId) -or [string]::IsNullOrWhiteSpace($ClientId) -or $null -eq $ClientSecret) {
        Write-Verbose 'Client credentials are incomplete. Returning healthy stub records for local validation.'
    }
    else {
        Write-Verbose 'Client credentials supplied. Insert the authenticated Graph GET call to /admin/serviceAnnouncement/healthOverviews here when enabling live monitoring.'
    }

    $timestamp = Get-DrmUtcTimestamp
    return @(
        foreach ($service in $MonitoredServices) {
            # Production implementation note:
            # Invoke Microsoft Graph GET https://graph.microsoft.com/v1.0/admin/serviceAnnouncement/healthOverviews
            # and map the workload-specific response into the object below.
            $stubFreshness = Get-DrmFreshness -CollectionTime $timestamp -SourceLastModified $null -StalenessThresholdMinutes $StalenessThresholdMinutes -RuntimeMode 'local-stub' -Provenance 'synthetic-stub'
            [pscustomobject]@{
                Service = $service
                Status = 'Healthy'
                IncidentId = $null
                DetectedAt = $timestamp
                LastUpdated = $timestamp
                CollectionTime = $timestamp
                SourceLastModified = $null
                TimestampProvenance = 'synthetic-stub'
                Freshness = $stubFreshness
                DowntimeMinutes = 0
                AffectedUserPct = 0
                ImpactDescription = 'No active service advisories captured by the local Graph stub.'
                IsCritical = $service -in $criticalServices
                Source = 'local-graph-stub'
                RuntimeMode = 'local-stub'
                Warning = $stubWarning
            }
        }
    )
}

function Resolve-DrmReportedStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('implemented', 'partial', 'monitor-only', 'playbook-only')]
        [string]$CandidateStatus,

        [Parameter(Mandatory)]
        [string]$RuntimeMode
    )

    if ($RuntimeMode -ne 'live-graph' -and $CandidateStatus -eq 'implemented') {
        return 'partial'
    }

    return $CandidateStatus
}

function Invoke-DoraSeverityClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$HealthRecord,

        [Parameter(Mandatory)]
        [hashtable]$SeverityThresholds
    )

    $statusProfile = Get-DrmServiceHealthStatusProfile -Status ([string]$HealthRecord.Status)
    if (-not [bool]$statusProfile.IsClassifiable) {
        return $null
    }

    $majorThreshold = $SeverityThresholds.major
    $significantThreshold = $SeverityThresholds.significant
    $minorThreshold = $SeverityThresholds.minor

    $severity = 'minor'
    $classificationNote = 'Brief or low-impact issue recorded for local operational visibility.'

    if ($HealthRecord.IsCritical -and [double]$HealthRecord.DowntimeMinutes -ge [double]$majorThreshold.downtimeMinutes) {
        $severity = 'major'
        $classificationNote = 'Critical service downtime exceeded the major threshold.'
    }
    elseif ($HealthRecord.IsCritical -and [double]$HealthRecord.AffectedUserPct -ge [double]$majorThreshold.affectedUserPct) {
        $severity = 'major'
        $classificationNote = 'Critical service user impact exceeded the major threshold.'
    }
    elseif ([double]$HealthRecord.DowntimeMinutes -ge [double]$significantThreshold.downtimeMinutes -or [double]$HealthRecord.AffectedUserPct -ge [double]$significantThreshold.affectedUserPct) {
        $severity = 'significant'
        $classificationNote = 'Partial degradation or sustained impact met the significant threshold.'
    }
    elseif ([double]$HealthRecord.DowntimeMinutes -ge [double]$minorThreshold.downtimeMinutes -or [double]$HealthRecord.AffectedUserPct -ge [double]$minorThreshold.affectedUserPct) {
        if ([bool]$statusProfile.EscalatesMinorThreshold) {
            $severity = 'significant'
            $classificationNote = 'Status indicates an active Graph service-health issue and at least one minor numeric threshold was met; upgraded to significant.'
        }
        else {
            $severity = 'minor'
            $classificationNote = 'Short-duration or low-impact issue met the minor threshold.'
        }
    }

    $incidentIdentifier = if ($HealthRecord.IncidentId) {
        [string]$HealthRecord.IncidentId
    }
    else {
        "DRM-$((Get-Date -Format 'yyyyMMddHHmmss'))-$($HealthRecord.Service -replace '[^A-Za-z0-9]', '')"
    }

    $incidentState = if ([bool]$statusProfile.IsOpenIncident) { 'open' } else { 'resolved' }

    return [pscustomobject]@{
        incidentId = $incidentIdentifier
        severity = $severity
        affectedService = $HealthRecord.Service
        detectedAt = $HealthRecord.DetectedAt
        reportedAt = $HealthRecord.LastUpdated
        status = $incidentState
        downtimeMinutes = [double]$HealthRecord.DowntimeMinutes
        affectedUserPct = [double]$HealthRecord.AffectedUserPct
        impactDescription = $HealthRecord.ImpactDescription
        doraCategory = 'ICT-related incident'
        classificationNote = $classificationNote
    }
}

function Get-ResilienceTestDue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$ResilienceConfiguration,

        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    if (-not [bool]$ResilienceConfiguration.enabled) {
        return [pscustomobject]@{
            Enabled = $false
            Status = 'not-applicable'
            AnnualTestRequiredByDORA = [bool]$ResilienceConfiguration.annualTestRequiredByDORA
            LastTestDate = $null
            NextDueDate = $null
            IsOverdue = $false
            ReminderDaysBeforeDue = $null
            RtoTargetHours = $null
            RpoTargetHours = $null
            TlptRequired = $false
            Notes = 'Resilience test tracking is disabled for this tier.'
        }
    }

    $lastTestDate = $null
    if (-not [string]::IsNullOrWhiteSpace($env:DRM_LAST_RESILIENCE_TEST_DATE)) {
        $lastTestDate = [datetime]$env:DRM_LAST_RESILIENCE_TEST_DATE
    }

    $nextDueDate = if ($null -ne $lastTestDate) { $lastTestDate.AddYears(1) } else { $null }
    $status = 'current'
    $isOverdue = $false
    $notes = 'Annual resilience test evidence is within the required window.'

    if ([bool]$ResilienceConfiguration.annualTestRequiredByDORA) {
        if ($null -eq $lastTestDate) {
            $status = 'missing'
            $isOverdue = ($Tier -eq 'regulated')
            $notes = 'No recorded annual resilience test date was found in DRM_LAST_RESILIENCE_TEST_DATE.'
        }
        elseif ($nextDueDate -le (Get-Date)) {
            $status = 'overdue'
            $isOverdue = $true
            $notes = 'The next annual resilience test due date has passed.'
        }
    }

    return [pscustomobject]@{
        Enabled = $true
        Status = $status
        AnnualTestRequiredByDORA = [bool]$ResilienceConfiguration.annualTestRequiredByDORA
        LastTestDate = if ($null -ne $lastTestDate) { $lastTestDate.ToString('o') } else { $null }
        NextDueDate = if ($null -ne $nextDueDate) { $nextDueDate.ToString('o') } else { $null }
        IsOverdue = $isOverdue
        ReminderDaysBeforeDue = if ($ResilienceConfiguration.Contains('reminderDaysBeforeDue')) { [int]$ResilienceConfiguration.reminderDaysBeforeDue } else { $null }
        RtoTargetHours = if ($ResilienceConfiguration.Contains('rtoTargetHours')) { $ResilienceConfiguration.rtoTargetHours } else { $null }
        RpoTargetHours = if ($ResilienceConfiguration.Contains('rpoTargetHours')) { $ResilienceConfiguration.rpoTargetHours } else { $null }
        TlptRequired = if ($ResilienceConfiguration.Contains('tlptRequired')) { [bool]$ResilienceConfiguration.tlptRequired } else { $false }
        Notes = $notes
    }
}

Write-Verbose ("Loading DRM configuration for tier [{0}]." -f $ConfigurationTier)
$configuration = Get-DrmConfiguration -Tier $ConfigurationTier
Test-DrmConfiguration -Configuration $configuration

$resolvedOutputPath = (New-Item -ItemType Directory -Path $OutputPath -Force).FullName
$resolvedClientSecret = Resolve-DrmClientSecret -Secret $ClientSecret

$collectionTime = Get-DrmUtcTimestamp
$stalenessThresholdMinutes = Resolve-DrmStalenessThreshold -PollingIntervalMinutes ([int]$configuration.serviceHealthPollingIntervalMinutes)

Write-Verbose 'Collecting service-health snapshots.'
$serviceHealthSummary = @(Get-ServiceHealthStatus -MonitoredServices $configuration.defaults.monitoredServices -TenantId $TenantId -ClientId $ClientId -ClientSecret $resolvedClientSecret -StalenessThresholdMinutes $stalenessThresholdMinutes)
$runtimeModes = @($serviceHealthSummary | Select-Object -ExpandProperty RuntimeMode -Unique)
$runtimeMode = if ($runtimeModes.Count -eq 1) { [string]$runtimeModes[0] } else { 'mixed-nonlive' }
$statusWarning = if ($runtimeMode -eq 'sample-json') {
    $script:SampleWarning
}
elseif ($runtimeMode -eq 'local-stub') {
    $script:StubWarning
}
else {
    'Service health output combined multiple non-live sources; validate live Graph wiring before treating status as implemented.'
}

Write-Verbose 'Classifying service-health incidents with DORA severity logic.'
$incidentFindings = @(
    foreach ($record in $serviceHealthSummary) {
        $classification = Invoke-DoraSeverityClassification -HealthRecord $record -SeverityThresholds $configuration.incidentClassification.severityThresholds
        if ($null -ne $classification) {
            $classification
        }
    }
)

Write-Verbose 'Checking resilience-test schedule.'
$resilienceTestStatus = Get-ResilienceTestDue -ResilienceConfiguration $configuration.resilienceTestTracking -Tier $ConfigurationTier

Write-Verbose 'Evaluating evidence freshness across collected records.'
$recordFreshness = @($serviceHealthSummary | ForEach-Object { $_.Freshness })
$staleRecordCount = @($recordFreshness | Where-Object { $_.status -in @('stale', 'invalid-future') }).Count
$gapRecordCount = @($recordFreshness | Where-Object { [bool]$_.hasTimestampGap }).Count
$evaluatedRecordCount = @($recordFreshness | Where-Object { $_.status -in @('current', 'stale', 'invalid-future') }).Count
$overallFreshnessStatus = if ($gapRecordCount -gt 0) {
    'gap'
}
elseif ($staleRecordCount -gt 0) {
    'stale'
}
elseif ($evaluatedRecordCount -gt 0) {
    'current'
}
else {
    'not-applicable'
}
$freshnessSummary = [pscustomobject]@{
    CollectionTime = $collectionTime
    StalenessThresholdMinutes = $stalenessThresholdMinutes
    RuntimeMode = $runtimeMode
    OverallStatus = $overallFreshnessStatus
    RecordCount = $serviceHealthSummary.Count
    EvaluatedRecordCount = $evaluatedRecordCount
    StaleRecordCount = $staleRecordCount
    TimestampGapCount = $gapRecordCount
    Note = 'Freshness distinguishes collection time from source last-modified time. Records with missing or invalid source timestamps are reported as explicit gaps rather than treated as current.'
}

$candidateOverallStatus = 'implemented'
if ($incidentFindings.Count -gt 0) {
    $candidateOverallStatus = 'monitor-only'
}
elseif ($ConfigurationTier -eq 'regulated' -and $resilienceTestStatus.Status -in @('missing', 'overdue')) {
    $candidateOverallStatus = 'partial'
}
$overallStatus = Resolve-DrmReportedStatus -CandidateStatus $candidateOverallStatus -RuntimeMode $runtimeMode

Write-Warning $statusWarning
if ($overallFreshnessStatus -in @('gap', 'stale')) {
    Write-Warning ("Evidence freshness is [{0}]: {1} record(s) stale, {2} record(s) with timestamp gaps. Do not treat monitoring output as current." -f $overallFreshnessStatus, $staleRecordCount, $gapRecordCount)
}
$complianceStatus = [pscustomobject]@{
    Solution = $configuration.displayName
    Tier = $ConfigurationTier
    OverallStatus = $overallStatus
    RuntimeMode = $runtimeMode
    DataSourceMode = $runtimeMode
    StatusWarning = $statusWarning
    ServiceHealthSummary = $serviceHealthSummary
    IncidentFindings = $incidentFindings
    ResilienceTestStatus = $resilienceTestStatus
    Freshness = $freshnessSummary
    CollectionTime = $collectionTime
    LastCheckedAt = $collectionTime
}

$statusPath = Join-Path $resolvedOutputPath ("13-dora-resilience-monitor-status-{0}.json" -f $ConfigurationTier)
$complianceStatus | ConvertTo-Json -Depth 10 | Set-Content -Path $statusPath -Encoding utf8
Write-Verbose ("Compliance status snapshot written to {0}." -f $statusPath)

if ($PassThru) {
    return $complianceStatus
}

$complianceStatus
