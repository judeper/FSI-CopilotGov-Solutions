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

function Get-DrmConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    $configRoot = Join-Path $PSScriptRoot '..\config'
    $defaultConfigPath = Join-Path $configRoot 'default-config.json'
    $tierConfigPath = Join-Path $configRoot ("{0}.json" -f $Tier)

    foreach ($pathToCheck in @($defaultConfigPath, $tierConfigPath)) {
        if (-not (Test-Path -Path $pathToCheck)) {
            throw "Configuration file not found: $pathToCheck"
        }
    }

    $defaultConfig = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
    $tierConfig = Get-Content -Path $tierConfigPath -Raw | ConvertFrom-Json -AsHashtable

    return [ordered]@{
        solution = $defaultConfig.solution
        displayName = $defaultConfig.displayName
        solutionCode = $defaultConfig.solutionCode
        version = $defaultConfig.version
        defaults = $defaultConfig.defaults
        tier = $tierConfig.tier
        controls = $tierConfig.controls
        evidenceRetentionDays = $tierConfig.evidenceRetentionDays
        notificationMode = $tierConfig.notificationMode
        serviceHealthPollingIntervalMinutes = $tierConfig.serviceHealthPollingIntervalMinutes
        incidentClassification = $tierConfig.incidentClassification
        resilienceTestTracking = $tierConfig.resilienceTestTracking
        sentinelIntegration = $tierConfig.sentinelIntegration
        powerAutomateFlow = $tierConfig.powerAutomateFlow
        dataResidency = if ($tierConfig.Contains('dataResidency')) { $tierConfig.dataResidency } else { $null }
        evidenceImmutability = if ($tierConfig.Contains('evidenceImmutability')) { $tierConfig.evidenceImmutability } else { $null }
    }
}

function Test-DrmConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration
    )

    $requiredFields = @(
        'solution',
        'displayName',
        'solutionCode',
        'version',
        'defaults',
        'tier',
        'controls',
        'evidenceRetentionDays',
        'notificationMode',
        'serviceHealthPollingIntervalMinutes',
        'incidentClassification',
        'resilienceTestTracking',
        'sentinelIntegration',
        'powerAutomateFlow'
    )

    $missingFields = @()
    foreach ($field in $requiredFields) {
        if (-not $Configuration.Contains($field) -or $null -eq $Configuration[$field]) {
            $missingFields += $field
        }
    }

    if ($missingFields.Count -gt 0) {
        throw "DRM configuration is missing required fields: $($missingFields -join ', ')"
    }
}

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
    $hash = Get-CopilotGovSha256 -Path $Path
    Set-Content -Path ($Path + '.sha256') -Value ("{0}  {1}" -f $hash, [System.IO.Path]::GetFileName($Path)) -Encoding utf8

    return [pscustomobject]@{
        Path = $Path
        Hash = $hash
    }
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
            checkedAt = $entry.LastUpdated
            pollingIntervalMinutes = $configuration.serviceHealthPollingIntervalMinutes
            retentionDays = $configuration.evidenceRetentionDays
            sourceEndpoint = $entry.Source
            incidentId = $entry.IncidentId
            impactDescription = $entry.ImpactDescription
        }
    }
)
$serviceHealthArtifact = [ordered]@{
    solution = $configuration.solution
    tier = $ConfigurationTier
    periodStart = $PeriodStart.ToString('o')
    periodEnd = $PeriodEnd.ToString('o')
    generatedAt = (Get-Date).ToString('o')
    pollingIntervalMinutes = $configuration.serviceHealthPollingIntervalMinutes
    retentionDays = $configuration.evidenceRetentionDays
    records = $serviceHealthRecords
}
$serviceHealthFile = New-DrmArtifactFile -Path (Join-Path $resolvedOutputPath ("service-health-log-{0}.json" -f $ConfigurationTier)) -Content $serviceHealthArtifact

Write-Verbose 'Building incident-register artifact.'
$incidentRecords = @(
    foreach ($incident in @($complianceStatus.IncidentFindings)) {
        [pscustomobject]@{
            incidentId = $incident.incidentId
            severity = $incident.severity
            affectedService = $incident.affectedService
            detectedAt = $incident.detectedAt
            reportedAt = $incident.reportedAt
            status = $incident.status
            rtoActual = if ($null -ne $incident.downtimeMinutes) { [math]::Round(([double]$incident.downtimeMinutes / 60), 2) } else { $null }
            rpoActual = 0
            affectedUserPct = $incident.affectedUserPct
            impactDescription = $incident.impactDescription
            rootCauseAnalysisStatus = if ($ConfigurationTier -eq 'regulated') { 'pending' } else { 'not-required' }
            regulatoryNotificationRequired = ($incident.severity -eq 'major')
            notes = $incident.classificationNote
        }
    }
)
$incidentRegisterArtifact = [ordered]@{
    solution = $configuration.solution
    tier = $ConfigurationTier
    periodStart = $PeriodStart.ToString('o')
    periodEnd = $PeriodEnd.ToString('o')
    generatedAt = (Get-Date).ToString('o')
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
    periodStart = $PeriodStart.ToString('o')
    periodEnd = $PeriodEnd.ToString('o')
    generatedAt = (Get-Date).ToString('o')
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
        status = 'implemented'
        notes = 'Incident reporting and DORA-aligned severity classification are included in the exported incident register.'
    },
    [pscustomobject]@{
        controlId = '4.10'
        status = 'partial'
        notes = 'Resilience test tracking and recovery objectives are documented; automated failover validation requires additional tenant-specific engineering.'
    },
    [pscustomobject]@{
        controlId = '4.11'
        status = 'monitor-only'
        notes = 'Sentinel integration requires separate workspace provisioning, data connectors, and alert rules outside this solution.'
    }
)

$recordCount = $serviceHealthRecords.Count + $incidentRecords.Count + $resilienceRecords.Count
$findingCount = $incidentRecords.Count
if ($complianceStatus.ResilienceTestStatus.Status -in @('missing', 'overdue')) {
    $findingCount++
}
$exceptionCount = ($controls | Where-Object { $_.status -ne 'implemented' }).Count

$artifacts = @(
    [pscustomobject]@{ name = 'service-health-log'; type = 'json'; path = $serviceHealthFile.Path; hash = $serviceHealthFile.Hash },
    [pscustomobject]@{ name = 'incident-register'; type = 'json'; path = $incidentRegisterFile.Path; hash = $incidentRegisterFile.Hash },
    [pscustomobject]@{ name = 'resilience-test-results'; type = 'json'; path = $resilienceFile.Path; hash = $resilienceFile.Hash }
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
    -Artifacts $artifacts

$result = [pscustomobject]@{
    Summary = $summary
    Controls = $controls
    Artifacts = $artifacts
    Package = $package
}

if ($PassThru) {
    return $result
}

$result
