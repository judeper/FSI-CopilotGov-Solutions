<#
.SYNOPSIS
Orchestrates the full access review lifecycle: risk read, create, collect, apply, export.

.DESCRIPTION
Coordinates the end-to-end risk-triaged access review workflow by reading risk scores
from solution 02 output, creating access reviews for HIGH-risk sites first, collecting
review results, applying completed decisions, and exporting evidence packages.
Scripts use representative sample data and do not connect to live Microsoft 365 services.

.PARAMETER TenantId
Azure AD tenant GUID.

.PARAMETER ClientId
Application (client) ID for app-only authentication.

.PARAMETER ClientSecret
Client secret for app-only authentication.

.PARAMETER UseMgGraph
When set, uses Connect-MgGraph for delegated authentication instead of client credentials.

.PARAMETER RiskScoreInputPath
Path to the risk-scored site output from solution 02-oversharing-risk-assessment.

.PARAMETER ConfigPath
Path to the review schedule configuration file. Defaults to config\review-schedule.json.

.PARAMETER OutputPath
Directory where all output artifacts will be written.

.EXAMPLE
.\Invoke-RiskTriagedReviews.ps1 -TenantId 00000000-0000-0000-0000-000000000000 -RiskScoreInputPath .\artifacts\oversharing-findings.json -OutputPath .\artifacts\reviews

.EXAMPLE
.\Invoke-RiskTriagedReviews.ps1 -TenantId 00000000-0000-0000-0000-000000000000 -UseMgGraph -OutputPath .\artifacts\reviews
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantId,

    [Parameter()]
    [string]$ClientId,

    [Parameter()]
    [string]$ClientSecret,

    [Parameter()]
    [switch]$UseMgGraph,

    [Parameter()]
    [string]$RiskScoreInputPath,

    [Parameter()]
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\config\review-schedule.json'),

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\reviews')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\GraphAuth.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

$outputRoot = [System.IO.Path]::GetFullPath($OutputPath)
$null = New-Item -Path $outputRoot -ItemType Directory -Force

$authParams = @{}
if ($UseMgGraph.IsPresent) {
    $authParams['UseMgGraph'] = $true
}
elseif (-not [string]::IsNullOrWhiteSpace($ClientId)) {
    $authParams['ClientId'] = $ClientId
    if (-not [string]::IsNullOrWhiteSpace($ClientSecret)) {
        $authParams['ClientSecret'] = $ClientSecret
    }
}

Write-Verbose '--- Step 1: Creating access reviews from risk scores ---'
$newReviewParams = @{
    TenantId = $TenantId
    ConfigPath = $ConfigPath
    OutputPath = $outputRoot
}
if (-not [string]::IsNullOrWhiteSpace($RiskScoreInputPath)) {
    $newReviewParams['RiskScoreInputPath'] = $RiskScoreInputPath
}
foreach ($key in $authParams.Keys) {
    $newReviewParams[$key] = $authParams[$key]
}

$createResult = & (Join-Path $PSScriptRoot 'New-AccessReview.ps1') @newReviewParams

Write-Verbose '--- Step 2: Collecting review results ---'
$getResultParams = @{
    TenantId = $TenantId
    OutputPath = $outputRoot
}
foreach ($key in $authParams.Keys) {
    $getResultParams[$key] = $authParams[$key]
}

$reviewResult = & (Join-Path $PSScriptRoot 'Get-ReviewResults.ps1') @getResultParams

Write-Verbose '--- Step 3: Applying completed decisions ---'
$definitionsFile = Join-Path $outputRoot 'access-review-definitions.json'
$appliedResults = @()

if (Test-Path -Path $definitionsFile) {
    try {
        $definitions = Get-Content -Path $definitionsFile -Raw | ConvertFrom-Json
        $uniqueDefinitions = @($definitions | Select-Object -ExpandProperty reviewDefinitionId -Unique)

        foreach ($defId in $uniqueDefinitions) {
            $applyParams = @{
                TenantId = $TenantId
                ReviewDefinitionId = $defId
                OutputPath = $outputRoot
            }
            foreach ($key in $authParams.Keys) {
                $applyParams[$key] = $authParams[$key]
            }

            try {
                $result = & (Join-Path $PSScriptRoot 'Apply-ReviewDecisions.ps1') @applyParams
                $appliedResults += $result
            }
            catch {
                Write-Warning "Failed to apply decisions for definition '$defId': $($_.Exception.Message)"
            }
        }
    }
    catch {
        Write-Warning "Failed to read review definitions for decision application: $($_.Exception.Message)"
    }
}

Write-Verbose '--- Step 4: Exporting evidence ---'
$exportParams = @{
    ConfigurationTier = 'baseline'
    TenantId = $TenantId
    OutputPath = (Join-Path $outputRoot 'evidence')
}

try {
    $exportResult = & (Join-Path $PSScriptRoot 'Export-Evidence.ps1') @exportParams
}
catch {
    Write-Warning "Evidence export encountered an issue: $($_.Exception.Message)"
    $exportResult = $null
}

$summary = [ordered]@{
    orchestratorRun = (Get-Date).ToString('o')
    tenantId = $TenantId
    steps = [ordered]@{
        createReviews = [ordered]@{
            reviewsCreated = $createResult.ReviewsCreated
            highRisk = $createResult.HighRisk
            mediumRisk = $createResult.MediumRisk
            lowRisk = $createResult.LowRisk
        }
        collectResults = [ordered]@{
            totalDecisions = $reviewResult.TotalDecisions
            pendingDecisions = $reviewResult.PendingDecisions
            completedDecisions = $reviewResult.CompletedDecisions
            escalationAlerts = $reviewResult.EscalationAlerts
        }
        applyDecisions = [ordered]@{
            definitionsProcessed = @($appliedResults).Count
            totalActions = ($appliedResults | ForEach-Object { $_.TotalActions } | Measure-Object -Sum).Sum
        }
        exportEvidence = [ordered]@{
            status = if ($null -ne $exportResult) { 'completed' } else { 'skipped' }
        }
    }
    outputPath = $outputRoot
}

$summaryFile = Join-Path $outputRoot 'orchestrator-summary.json'
$summary | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryFile -Encoding utf8

[pscustomobject]@{
    TenantId = $TenantId
    ReviewsCreated = $createResult.ReviewsCreated
    DecisionsCollected = $reviewResult.TotalDecisions
    EscalationAlerts = $reviewResult.EscalationAlerts
    ActionsApplied = ($appliedResults | ForEach-Object { $_.TotalActions } | Measure-Object -Sum).Sum
    SummaryPath = $summaryFile
}
