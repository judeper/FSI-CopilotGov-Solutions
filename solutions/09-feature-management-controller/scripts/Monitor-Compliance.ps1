<#
.SYNOPSIS
Monitors Copilot feature drift against the approved FMC baseline.

.DESCRIPTION
Reads an approved feature-state baseline, simulates current feature state collection,
compares observed values to the baseline, measures drift severity, and returns a
structured compliance result that can be used by operations and supervisory teams.

.PARAMETER ConfigurationTier
The governance tier to evaluate. Valid values are baseline, recommended, and regulated.

.PARAMETER BaselinePath
Path to the approved baseline JSON file.

.PARAMETER AlertThreshold
Number of drift findings that triggers an alert payload. Default is 3.

.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier recommended -BaselinePath .\artifacts\FMC\feature-state-baseline.json

.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier regulated -BaselinePath .\config\regulated.json -AlertThreshold 3

.NOTES
Supports compliance with SEC Reg FD and FINRA 3110 by preserving repeatable drift
analysis and alert metadata for Copilot feature changes.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter(Mandatory)]
    [string]$BaselinePath,

    [Parameter()]
    [ValidateRange(1, 100)]
    [int]$AlertThreshold = 3
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\TeamsNotification.psm1') -Force

function Get-NormalizedBaselineFeature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Feature
    )

    $expectedEnabled = if ($Feature.PSObject.Properties.Match('expectedEnabled').Count -gt 0 -and $null -ne $Feature.expectedEnabled) {
        [bool]$Feature.expectedEnabled
    }
    elseif ($Feature.PSObject.Properties.Match('enabled').Count -gt 0) {
        [bool]$Feature.enabled
    }
    else {
        $false
    }

    $expectedRing = if ($Feature.PSObject.Properties.Match('expectedRing').Count -gt 0 -and $null -ne $Feature.expectedRing) {
        [string]$Feature.expectedRing
    }
    elseif ($Feature.PSObject.Properties.Match('currentRing').Count -gt 0) {
        [string]$Feature.currentRing
    }
    else {
        'Restricted'
    }

    $sourceSystem = if ($Feature.PSObject.Properties.Match('sourceSystem').Count -gt 0) {
        [string]$Feature.sourceSystem
    }
    else {
        'unknown'
    }

    $category = if ($Feature.PSObject.Properties.Match('category').Count -gt 0) {
        [string]$Feature.category
    }
    else {
        'unclassified'
    }

    return [pscustomobject]@{
        featureId       = [string]$Feature.featureId
        displayName     = [string]$Feature.displayName
        sourceSystem    = $sourceSystem
        category        = $category
        expectedEnabled = $expectedEnabled
        expectedRing    = $expectedRing
    }
}

function Get-CurrentFeatureState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$BaselineDocument,

        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$ConfigurationTier
    )

    $currentState = foreach ($featureRecord in $BaselineDocument.features) {
        $expected = Get-NormalizedBaselineFeature -Feature $featureRecord
        $observedEnabled = $expected.expectedEnabled
        $observedRing = $expected.expectedRing

        switch ($ConfigurationTier) {
            'baseline' {
                if ($expected.featureId -eq 'teams-copilot-chat') {
                    $observedRing = 'General Availability'
                }
            }
            'recommended' {
                if ($expected.featureId -eq 'teams-copilot-meetings') {
                    $observedRing = 'Early Adopters'
                }

                if ($expected.featureId -eq 'word-copilot-drafting') {
                    $observedEnabled = $false
                }
            }
            'regulated' {
                if ($expected.featureId -eq 'teams-copilot-meetings') {
                    $observedRing = 'General Availability'
                }

                if ($expected.featureId -eq 'power-automate-copilot-designer') {
                    $observedEnabled = $false
                }

                if ($expected.featureId -eq 'third-party-plugin-execution') {
                    $observedEnabled = $true
                    $observedRing = 'Early Adopters'
                }
            }
        }

        [pscustomobject]@{
            featureId         = $expected.featureId
            displayName       = $expected.displayName
            sourceSystem      = $expected.sourceSystem
            currentEnabled    = $observedEnabled
            currentRing       = $observedRing
            observedAt        = (Get-Date).ToString('o')
            observationSource = 'stub-collection'
            notes             = 'Stub current-state collection for drift scoring validation.'
        }
    }

    return @($currentState)
}

function Compare-FeatureBaseline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$BaselineDocument,

        [Parameter(Mandatory)]
        [object[]]$CurrentState
    )

    $findings = @()
    $baselineFeatureIds = @()

    foreach ($featureRecord in $BaselineDocument.features) {
        $expected = Get-NormalizedBaselineFeature -Feature $featureRecord
        $baselineFeatureIds += $expected.featureId
        $observed = $CurrentState | Where-Object { $_.featureId -eq $expected.featureId } | Select-Object -First 1

        if (-not $observed) {
            $findings += [pscustomobject]@{
                findingId       = [guid]::NewGuid().Guid
                featureId       = $expected.featureId
                displayName     = $expected.displayName
                driftType       = 'missingFeature'
                severity        = 'high'
                baselineValue   = 'feature expected in baseline'
                observedValue   = 'feature not observed'
                detectedAt      = (Get-Date).ToString('o')
                remediationHint = 'Review inventory connectors and refresh baseline after validation.'
                score           = 4
            }

            continue
        }

        if ($expected.expectedEnabled -ne [bool]$observed.currentEnabled) {
            $findings += [pscustomobject]@{
                findingId       = [guid]::NewGuid().Guid
                featureId       = $expected.featureId
                displayName     = $expected.displayName
                driftType       = 'enablementMismatch'
                severity        = 'high'
                baselineValue   = [string]$expected.expectedEnabled
                observedValue   = [string]$observed.currentEnabled
                detectedAt      = (Get-Date).ToString('o')
                remediationHint = 'Reapply approved enablement state or update the baseline after approval.'
                score           = 3
            }
        }

        if ($expected.expectedRing -ne [string]$observed.currentRing) {
            $findings += [pscustomobject]@{
                findingId       = [guid]::NewGuid().Guid
                featureId       = $expected.featureId
                displayName     = $expected.displayName
                driftType       = 'ringMismatch'
                severity        = 'medium'
                baselineValue   = $expected.expectedRing
                observedValue   = [string]$observed.currentRing
                detectedAt      = (Get-Date).ToString('o')
                remediationHint = 'Confirm ring promotion approval or move the feature back to the approved ring.'
                score           = 2
            }
        }
    }

    foreach ($observed in $CurrentState) {
        if ($observed.featureId -notin $baselineFeatureIds) {
            $findings += [pscustomobject]@{
                findingId       = [guid]::NewGuid().Guid
                featureId       = $observed.featureId
                displayName     = $observed.displayName
                driftType       = 'unexpectedFeature'
                severity        = 'high'
                baselineValue   = 'feature not approved'
                observedValue   = 'feature observed'
                detectedAt      = (Get-Date).ToString('o')
                remediationHint = 'Review whether the feature requires approval and registry inclusion.'
                score           = 4
            }
        }
    }

    return @($findings)
}

function Measure-FeatureDrift {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$DriftFindings,

        [Parameter(Mandatory)]
        [int]$AlertThreshold
    )

    $driftCount = @($DriftFindings).Count
    $driftScore = 0

    if ($driftCount -gt 0) {
        $driftScore = [int](($DriftFindings | Measure-Object -Property score -Sum).Sum)
    }

    $status = if ($driftCount -eq 0) {
        'implemented'
    }
    elseif ($driftCount -lt $AlertThreshold) {
        'partial'
    }
    else {
        'monitor-only'
    }

    return [pscustomobject]@{
        driftCount     = $driftCount
        driftScore     = $driftScore
        alertThreshold = $AlertThreshold
        status         = $status
        requiresAlert  = ($driftCount -ge $AlertThreshold)
    }
}

try {
    if (-not (Test-Path -Path $BaselinePath)) {
        throw "Baseline file not found: $BaselinePath"
    }

    $baselineDocument = Get-Content -Path $BaselinePath -Raw | ConvertFrom-Json
    if (-not $baselineDocument.features) {
        throw 'Baseline file does not contain a features collection.'
    }

    $currentState = Get-CurrentFeatureState -BaselineDocument $baselineDocument -ConfigurationTier $ConfigurationTier
    $driftFindings = Compare-FeatureBaseline -BaselineDocument $baselineDocument -CurrentState $currentState
    $driftSummary = Measure-FeatureDrift -DriftFindings $driftFindings -AlertThreshold $AlertThreshold
    $alert = $null

    if ($driftSummary.requiresAlert) {
        $alert = New-TeamsMessageCard -Title 'FMC drift threshold exceeded' -Summary ("{0} drift findings detected for tier {1}." -f $driftSummary.driftCount, $ConfigurationTier)
    }

    [pscustomobject]@{
        Solution           = 'Copilot Feature Management Controller'
        SolutionCode       = 'FMC'
        Tier               = $ConfigurationTier
        BaselinePath       = (Resolve-Path -Path $BaselinePath).Path
        EvaluatedAt        = (Get-Date).ToString('o')
        FindingsTable      = (New-CopilotGovTableName -SolutionSlug 'fmc' -Purpose 'finding')
        Status             = $driftSummary.status
        StatusScore        = (Get-CopilotGovStatusScore -Status $driftSummary.status)
        DriftCount         = $driftSummary.driftCount
        DriftScore         = $driftSummary.driftScore
        AlertThreshold     = $driftSummary.alertThreshold
        AlertRaised        = [bool]$driftSummary.requiresAlert
        Findings           = $driftFindings
        Alert              = $alert
        ObservedFeatureState = $currentState
    }
}
catch {
    $message = "Monitor-Compliance.ps1 failed for FMC: $($_.Exception.Message)"
    Write-Error $message
    throw
}
