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
    Version: v0.1.0
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
        return (ConvertTo-SecureString -String $env:AZURE_CLIENT_SECRET -AsPlainText -Force)
    }

    return $null
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
        [System.Security.SecureString]$ClientSecret
    )

    $criticalServices = @('Exchange Online', 'SharePoint Online', 'Microsoft Teams', 'Microsoft Graph', 'Microsoft Copilot')
    $samplePayload = $env:DRM_SERVICE_HEALTH_SAMPLE_JSON

    if (-not [string]::IsNullOrWhiteSpace($samplePayload)) {
        Write-Verbose 'Using DRM_SERVICE_HEALTH_SAMPLE_JSON to simulate Graph service-health output.'
        $sampleEntries = @($samplePayload | ConvertFrom-Json -AsHashtable)

        return @(
            foreach ($entry in $sampleEntries) {
                $serviceName = if ($entry.Contains('service')) { [string]$entry.service } else { 'Unknown Service' }
                $detectedAt = if ($entry.Contains('detectedAt')) { ([datetime]$entry.detectedAt).ToString('o') } else { (Get-Date).ToString('o') }
                $lastUpdated = if ($entry.Contains('lastUpdated')) { ([datetime]$entry.lastUpdated).ToString('o') } else { $detectedAt }
                $downtimeMinutes = if ($entry.Contains('downtimeMinutes')) { [double]$entry.downtimeMinutes } else { 0 }
                $affectedUserPct = if ($entry.Contains('affectedUserPct')) { [double]$entry.affectedUserPct } else { 0 }
                $impactDescription = if ($entry.Contains('impactDescription')) { [string]$entry.impactDescription } else { 'Sample service-health event.' }
                $isCritical = if ($entry.Contains('isCritical')) { [bool]$entry.isCritical } else { $serviceName -in $criticalServices }

                [pscustomobject]@{
                    Service = $serviceName
                    Status = if ($entry.Contains('status')) { [string]$entry.status } else { 'Degraded' }
                    IncidentId = if ($entry.Contains('incidentId')) { [string]$entry.incidentId } else { $null }
                    DetectedAt = $detectedAt
                    LastUpdated = $lastUpdated
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

    $timestamp = (Get-Date).ToString('o')
    return @(
        foreach ($service in $MonitoredServices) {
            # Production implementation note:
            # Invoke Microsoft Graph GET https://graph.microsoft.com/v1.0/admin/serviceAnnouncement/healthOverviews
            # and map the workload-specific response into the object below.
            [pscustomobject]@{
                Service = $service
                Status = 'Healthy'
                IncidentId = $null
                DetectedAt = $timestamp
                LastUpdated = $timestamp
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

    if ([string]$HealthRecord.Status -eq 'Healthy') {
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
        if ([string]$HealthRecord.Status -match 'Degraded|Advisory|Interruption|Investigating') {
            $severity = 'significant'
            $classificationNote = 'Status indicates degradation and at least one minor numeric threshold was met; upgraded to significant.'
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

    $incidentState = if ([string]$HealthRecord.Status -match 'Resolved|Restored') { 'resolved' } else { 'open' }

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

Write-Verbose 'Collecting service-health snapshots.'
$serviceHealthSummary = @(Get-ServiceHealthStatus -MonitoredServices $configuration.defaults.monitoredServices -TenantId $TenantId -ClientId $ClientId -ClientSecret $resolvedClientSecret)
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

$candidateOverallStatus = 'implemented'
if ($incidentFindings.Count -gt 0) {
    $candidateOverallStatus = 'monitor-only'
}
elseif ($ConfigurationTier -eq 'regulated' -and $resilienceTestStatus.Status -in @('missing', 'overdue')) {
    $candidateOverallStatus = 'partial'
}
$overallStatus = Resolve-DrmReportedStatus -CandidateStatus $candidateOverallStatus -RuntimeMode $runtimeMode

Write-Warning $statusWarning
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
    LastCheckedAt = (Get-Date).ToString('o')
}

$statusPath = Join-Path $resolvedOutputPath ("13-dora-resilience-monitor-status-{0}.json" -f $ConfigurationTier)
$complianceStatus | ConvertTo-Json -Depth 10 | Set-Content -Path $statusPath -Encoding utf8
Write-Verbose ("Compliance status snapshot written to {0}." -f $statusPath)

if ($PassThru) {
    return $complianceStatus
}

$complianceStatus
