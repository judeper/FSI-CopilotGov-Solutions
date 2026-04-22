<#
.SYNOPSIS
    Captures a documentation-first model risk monitoring snapshot for Microsoft 365 Copilot.

.DESCRIPTION
    Builds representative sample inventory, validation, ongoing-monitoring, and third-party
    due diligence records for Microsoft 365 Copilot under an SR 11-7 / OCC Bulletin 2011-12
    interim generative AI model risk management approach. Does not connect to live Microsoft
    365 services. The output is intended for review by the model risk officer and the model
    risk committee, not for direct examiner submission.

.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.

.PARAMETER OutputPath
    Path for the monitoring snapshot output.

.PARAMETER PassThru
    Returns the monitoring snapshot object after writing the JSON file.

.EXAMPLE
    .\Monitor-Compliance.ps1 -ConfigurationTier recommended -Verbose

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
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'GmgConfig.psm1') -Force
$script:RuntimeMode = 'local-stub'
$script:RuntimeWarning = 'Monitoring snapshot was generated from representative sample data; live Microsoft Graph or Purview integration is not wired in this repository.'

function New-SampleInventoryRecords {
    param(
        [Parameter(Mandatory)] [string[]]$TrackedModels,
        [Parameter(Mandatory)] [string]$Provider
    )
    $now = (Get-Date).ToString('o')
    return @(
        foreach ($model in $TrackedModels) {
            [pscustomobject]@{
                modelId          = ('GMG-{0}' -f ($model -replace '[^A-Za-z0-9]', ''))
                modelName        = $model
                modelVersion     = '2026-RW1-sample'
                modelProvider    = $Provider
                intendedUse      = 'Productivity assistance for in-scope business users (sample value)'
                materialityTier  = 'medium'
                owner            = 'gmg-business-owner@example.com (sample value)'
                validationStatus = 'attestation'
                lastReviewedAt   = $now
            }
        }
    )
}

function New-SampleValidationRecord {
    param([Parameter(Mandatory)] [string]$ModelId, [Parameter(Mandatory)] [string]$ValidationApproach)
    return [pscustomobject]@{
        modelId                    = $ModelId
        validationApproach         = $ValidationApproach
        conceptualSoundnessNotes   = 'Vendor-supplied generative model; conceptual soundness derived from Microsoft Responsible AI documentation (sample reference).'
        outputTestingScope         = 'Representative use cases reviewed against firm acceptable use policy (sample scope).'
        limitationsLog             = @('Limited transparency into underlying foundation model parameters', 'Outputs may vary across releases')
        findings                   = @()
        independentChallengeStatus = 'not-required'
        nextValidationDue          = (Get-Date).AddYears(1).ToString('o')
    }
}

function New-SampleMonitoringObservation {
    param([Parameter(Mandatory)] [hashtable]$OngoingMonitoring)
    return [pscustomobject]@{
        observationId        = ('GMG-OBS-{0}' -f (Get-Date -Format 'yyyyMMddHHmmss'))
        observedAt           = (Get-Date).ToString('o')
        samplingCadence      = $OngoingMonitoring.samplingCadence
        outputSampleSize     = if ($OngoingMonitoring.Contains('outputSampleSize')) { [int]$OngoingMonitoring.outputSampleSize } else { 0 }
        highRiskOutputCount  = 0
        userFeedbackSignal   = 'no-signal-in-sample-window'
        driftIndicator       = 'within-expected-range'
        escalation           = $null
        notes                = 'Sample monitoring observation; replace with live sampling output when integration is enabled.'
    }
}

function New-SampleThirdPartyReview {
    param([Parameter(Mandatory)] [string]$Vendor, [Parameter(Mandatory)] [int]$ReviewCadenceDays)
    $cycle = switch ($ReviewCadenceDays) {
        { $_ -le 90 }  { 'quarterly'; break }
        { $_ -le 180 } { 'semi-annual'; break }
        default        { 'annual' }
    }
    return [pscustomobject]@{
        vendor             = $Vendor
        reviewCycle        = $cycle
        lastReviewedAt     = (Get-Date).ToString('o')
        nextReviewDue      = (Get-Date).AddDays($ReviewCadenceDays).ToString('o')
        evidenceReferences = @('Microsoft SOC 2 Type II report (sample reference)', 'Microsoft Responsible AI Standard (sample reference)', 'Microsoft 365 Copilot transparency note (sample reference)')
        openItems          = @()
        reviewer           = 'gmg-third-party-risk@example.com (sample value)'
    }
}

Write-Verbose ("Loading GMG configuration for tier [{0}]." -f $ConfigurationTier)
$configuration = Get-GmgConfiguration -Tier $ConfigurationTier
Test-GmgConfiguration -Configuration $configuration

$resolvedOutputPath = (New-Item -ItemType Directory -Path $OutputPath -Force).FullName

$inventoryRecords = New-SampleInventoryRecords -TrackedModels $configuration.defaults.trackedModels -Provider $configuration.defaults.modelProvider
$validationRecords = @( foreach ($entry in $inventoryRecords) { New-SampleValidationRecord -ModelId $entry.modelId -ValidationApproach $configuration.validation_assessment_required } )
$monitoringObservations = @( New-SampleMonitoringObservation -OngoingMonitoring $configuration.ongoingMonitoring )
$thirdPartyReview = New-SampleThirdPartyReview -Vendor $configuration.defaults.modelProvider -ReviewCadenceDays $configuration.third_party_review_cadence_days

$snapshot = [pscustomobject]@{
    Solution               = $configuration.displayName
    Tier                   = $ConfigurationTier
    OverallStatus          = 'monitor-only'
    RuntimeMode            = $script:RuntimeMode
    StatusWarning          = $script:RuntimeWarning
    InventoryRecords       = $inventoryRecords
    ValidationRecords      = $validationRecords
    MonitoringObservations = $monitoringObservations
    ThirdPartyReview       = $thirdPartyReview
    LastCheckedAt          = (Get-Date).ToString('o')
}

Write-Warning $script:RuntimeWarning

$snapshotPath = Join-Path $resolvedOutputPath ("20-generative-ai-model-governance-monitor-status-{0}.json" -f $ConfigurationTier)
$snapshot | ConvertTo-Json -Depth 10 | Set-Content -Path $snapshotPath -Encoding utf8
Write-Verbose ("Monitoring snapshot written to {0}." -f $snapshotPath)

if ($PassThru) {
    return $snapshot
}

$snapshot
