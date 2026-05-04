<#
.SYNOPSIS
    Records a documentation-first model risk monitoring snapshot for in-scope generative AI models.

.DESCRIPTION
    Builds representative sample inventory, validation, ongoing-monitoring, content safety,
    guardrail, and third-party due diligence records for Microsoft 365 Copilot, Copilot agents,
    Microsoft Foundry projects, Azure OpenAI or Foundry deployments, and approved Foundry
    partner/community model sources under an SR 11-7 / OCC Bulletin 2011-12 interim generative
    AI model risk management approach. Does not connect to live Microsoft 365 or Azure services.
    The output is intended for review by the model risk officer and the model risk committee,
    not for direct examiner submission.

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
    Version: v0.1.1
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
$script:RuntimeWarning = 'Monitoring snapshot was generated from representative sample data; live Microsoft 365, Microsoft Foundry, Azure OpenAI, Microsoft Purview, or Azure AI Content Safety integration is not wired in this repository.'

function Get-GmgMapValue {
    param(
        [Parameter()] [System.Collections.IDictionary]$Source,
        [Parameter(Mandatory)] [string]$Name,
        [Parameter()] [object]$Default = $null
    )

    if ($null -ne $Source -and $Source.Contains($Name) -and $null -ne $Source[$Name]) {
        return $Source[$Name]
    }

    return $Default
}

function New-SampleInventoryRecords {
    param(
        [Parameter()] [object[]]$TrackedModelSources = @(),
        [Parameter()] [string[]]$TrackedModels = @(),
        [Parameter(Mandatory)] [string]$Provider
    )

    $now = Get-Date
    $nowText = $now.ToString('o')

    if (@($TrackedModelSources).Count -gt 0) {
        return @(
            foreach ($source in $TrackedModelSources) {
                $sourceMap = [System.Collections.IDictionary]$source
                $modelName = [string](Get-GmgMapValue -Source $sourceMap -Name 'modelName' -Default (Get-GmgMapValue -Source $sourceMap -Name 'modelFamily' -Default 'Generative AI model'))
                $freshnessDays = [int](Get-GmgMapValue -Source $sourceMap -Name 'attestationFreshnessDays' -Default 365)
                [pscustomobject]@{
                    modelId                    = ('GMG-{0}' -f ([string](Get-GmgMapValue -Source $sourceMap -Name 'sourceId' -Default $modelName) -replace '[^A-Za-z0-9]', ''))
                    modelSource                = Get-GmgMapValue -Source $sourceMap -Name 'modelSource' -Default 'microsoft365copilot'
                    modelName                  = $modelName
                    modelFamily                = Get-GmgMapValue -Source $sourceMap -Name 'modelFamily' -Default $modelName
                    modelVersion               = Get-GmgMapValue -Source $sourceMap -Name 'modelVersion' -Default '2026-RW1-sample'
                    modelProvider              = Get-GmgMapValue -Source $sourceMap -Name 'provider' -Default $Provider
                    deploymentType             = Get-GmgMapValue -Source $sourceMap -Name 'deploymentType' -Default 'microsoft365service'
                    regionOrCloud              = Get-GmgMapValue -Source $sourceMap -Name 'regionOrCloud' -Default 'tenant-region-sample'
                    lifecycleStatus            = Get-GmgMapValue -Source $sourceMap -Name 'lifecycleStatus' -Default 'approved-for-inventory'
                    contentSafetyProfile       = Get-GmgMapValue -Source $sourceMap -Name 'contentSafetyProfile' -Default 'not-applicable'
                    responsibleAiReference     = 'Responsible AI or transparency reference placeholder (sample value)'
                    intendedUse                = 'Productivity assistance or approved generative AI use case for in-scope business users (sample value)'
                    materialityTier            = Get-GmgMapValue -Source $sourceMap -Name 'materialityTier' -Default 'medium'
                    owner                      = Get-GmgMapValue -Source $sourceMap -Name 'owner' -Default 'gmg-business-owner@example.com (sample value)'
                    validationStatus           = 'attestation'
                    attestationLastReviewedAt  = $nowText
                    attestationNextReviewDue   = $now.AddDays($freshnessDays).ToString('o')
                    lastReviewedAt             = $nowText
                }
            }
        )
    }

    return @(
        foreach ($model in $TrackedModels) {
            [pscustomobject]@{
                modelId                    = ('GMG-{0}' -f ($model -replace '[^A-Za-z0-9]', ''))
                modelSource                = 'microsoft365copilot'
                modelName                  = $model
                modelFamily                = $model
                modelVersion               = '2026-RW1-sample'
                modelProvider              = $Provider
                deploymentType             = 'microsoft365service'
                regionOrCloud              = 'tenant-region-sample'
                lifecycleStatus            = 'approved-for-inventory'
                contentSafetyProfile       = 'not-applicable'
                responsibleAiReference     = 'Responsible AI or transparency reference placeholder (sample value)'
                intendedUse                = 'Productivity assistance for in-scope business users (sample value)'
                materialityTier            = 'medium'
                owner                      = 'gmg-business-owner@example.com (sample value)'
                validationStatus           = 'attestation'
                attestationLastReviewedAt  = $nowText
                attestationNextReviewDue   = $now.AddDays(365).ToString('o')
                lastReviewedAt             = $nowText
            }
        }
    )
}

function New-SampleValidationRecord {
    param([Parameter(Mandatory)] [string]$ModelId, [Parameter(Mandatory)] [string]$ValidationApproach)
    return [pscustomobject]@{
        modelId                    = $ModelId
        validationApproach         = $ValidationApproach
        conceptualSoundnessNotes   = 'Vendor-supplied or platform-hosted generative model; conceptual soundness derived from Responsible AI and transparency documentation (sample reference).'
        outputTestingScope         = 'Representative use cases reviewed against firm acceptable use and content safety policies (sample scope).'
        limitationsLog             = @('Limited transparency into underlying foundation model parameters', 'Outputs may vary across releases', 'Provider and model availability may vary by region or cloud')
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

function New-SampleContentSafetyRecord {
    param([Parameter()] [System.Collections.IDictionary]$ContentSafetyDefaults)

    return [pscustomobject]@{
        guardrailProfileId          = 'GMG-GUARDRAIL-SAMPLE'
        contentSafetyResourceStatus = Get-GmgMapValue -Source $ContentSafetyDefaults -Name 'contentSafetyResourceStatus' -Default 'not-configured-in-sample'
        promptShields               = Get-GmgMapValue -Source $ContentSafetyDefaults -Name 'promptShields' -Default 'record-where-applicable'
        groundednessDetection       = Get-GmgMapValue -Source $ContentSafetyDefaults -Name 'groundednessDetection' -Default 'record-where-supported'
        protectedMaterialDetection  = Get-GmgMapValue -Source $ContentSafetyDefaults -Name 'protectedMaterialDetection' -Default 'record-where-supported'
        filterThresholds            = Get-GmgMapValue -Source $ContentSafetyDefaults -Name 'filterThresholds' -Default ([ordered]@{})
        reviewCadenceDays           = [int](Get-GmgMapValue -Source $ContentSafetyDefaults -Name 'reviewCadenceDays' -Default 90)
        exceptions                  = @()
        exceptionRegister           = Get-GmgMapValue -Source $ContentSafetyDefaults -Name 'exceptionRegister' -Default 'GMG-content-safety-exceptions'
        lastValidatedAt             = (Get-Date).ToString('o')
    }
}

function New-SampleThirdPartyReview {
    param(
        [Parameter(Mandatory)] [object[]]$InventoryRecords,
        [Parameter(Mandatory)] [int]$ReviewCadenceDays
    )

    $cycle = switch ($ReviewCadenceDays) {
        { $_ -le 90 }  { 'quarterly'; break }
        { $_ -le 180 } { 'semi-annual'; break }
        default        { 'annual' }
    }

    $vendors = @($InventoryRecords | ForEach-Object { $_.modelProvider } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
    if ($vendors.Count -eq 0) {
        $vendors = @('Microsoft')
    }

    return @(
        foreach ($vendor in $vendors) {
            [pscustomobject]@{
                vendor             = $vendor
                reviewCycle        = $cycle
                lastReviewedAt     = (Get-Date).ToString('o')
                nextReviewDue      = (Get-Date).AddDays($ReviewCadenceDays).ToString('o')
                evidenceReferences = @('SOC or equivalent assurance report (sample reference)', 'Responsible AI or transparency documentation (sample reference)', 'Model card or provider attestation (sample reference)')
                openItems          = @()
                reviewer           = 'gmg-third-party-risk@example.com (sample value)'
            }
        }
    )
}

Write-Verbose ("Loading GMG configuration for tier [{0}]." -f $ConfigurationTier)
$configuration = Get-GmgConfiguration -Tier $ConfigurationTier
Test-GmgConfiguration -Configuration $configuration

$resolvedOutputPath = (New-Item -ItemType Directory -Path $OutputPath -Force).FullName
$defaults = [System.Collections.IDictionary]$configuration.defaults
$trackedModelSources = if ($defaults.Contains('trackedModelSources')) { @($defaults.trackedModelSources) } else { @() }
$trackedModels = if ($defaults.Contains('trackedModels')) { [string[]]@($defaults.trackedModels) } else { @() }
$contentSafetyDefaults = if ($defaults.Contains('contentSafetyDefaults')) { [System.Collections.IDictionary]$defaults.contentSafetyDefaults } else { [ordered]@{} }

$inventoryRecords = New-SampleInventoryRecords -TrackedModelSources $trackedModelSources -TrackedModels $trackedModels -Provider $configuration.defaults.modelProvider
$validationRecords = @( foreach ($entry in $inventoryRecords) { New-SampleValidationRecord -ModelId $entry.modelId -ValidationApproach $configuration.validation_assessment_required } )
$monitoringObservations = @( New-SampleMonitoringObservation -OngoingMonitoring $configuration.ongoingMonitoring )
$contentSafetyAndGuardrails = @( New-SampleContentSafetyRecord -ContentSafetyDefaults $contentSafetyDefaults )
$thirdPartyReview = New-SampleThirdPartyReview -InventoryRecords $inventoryRecords -ReviewCadenceDays $configuration.third_party_review_cadence_days

$snapshot = [pscustomobject]@{
    Solution                   = $configuration.displayName
    Tier                       = $ConfigurationTier
    OverallStatus              = 'monitor-only'
    RuntimeMode                = $script:RuntimeMode
    StatusWarning              = $script:RuntimeWarning
    InventoryRecords           = $inventoryRecords
    ValidationRecords          = $validationRecords
    MonitoringObservations     = $monitoringObservations
    ContentSafetyAndGuardrails = $contentSafetyAndGuardrails
    ThirdPartyReview           = $thirdPartyReview
    LastCheckedAt              = (Get-Date).ToString('o')
}

Write-Warning $script:RuntimeWarning

$snapshotPath = Join-Path $resolvedOutputPath ("20-generative-ai-model-governance-monitor-status-{0}.json" -f $ConfigurationTier)
$snapshot | ConvertTo-Json -Depth 10 | Set-Content -Path $snapshotPath -Encoding utf8
Write-Verbose ("Monitoring snapshot written to {0}." -f $snapshotPath)

if ($PassThru) {
    return $snapshot
}

$snapshot
