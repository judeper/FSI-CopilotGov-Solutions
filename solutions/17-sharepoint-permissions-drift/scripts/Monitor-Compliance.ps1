<#
.SYNOPSIS
    Orchestrates baseline check and drift scan for SharePoint Permissions Drift Detection.

.DESCRIPTION
    Runs the permissions drift monitoring workflow: validates that a current baseline
    exists, captures a new baseline if the existing one is stale (beyond the configured
    scan frequency), and executes a drift scan against the latest baseline.

    This script is intended for scheduled execution (e.g., Azure Automation runbook
    or Windows Task Scheduler) to provide continuous drift monitoring.

.PARAMETER ConfigurationTier
    The configuration tier to use. Valid values: baseline, recommended, regulated.

.PARAMETER TenantId
    The Azure AD tenant identifier.

.PARAMETER TenantUrl
    The SharePoint Online tenant URL (e.g., https://contoso.sharepoint.com).

.PARAMETER OutputPath
    Directory for monitoring output files. Defaults to .\artifacts\SPD.

.PARAMETER AlertRecipient
    Email address to receive HIGH-risk drift alert notifications.

.EXAMPLE
    .\Monitor-Compliance.ps1 -ConfigurationTier recommended -TenantId "00000000-0000-0000-0000-000000000000" -TenantUrl "https://contoso.sharepoint.com"
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantId,

    [Parameter()]
    [string]$TenantUrl = 'https://contoso.sharepoint.com',

    [Parameter()]
    [string]$OutputPath = '.\artifacts\SPD',

    [Parameter()]
    [string]$AlertRecipient
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\GraphAuth.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

#region Helper Functions

function Get-BaselineStatus {
    <#
    .SYNOPSIS
        Checks whether the current baseline is fresh or stale.
    #>
    param(
        [string]$BaselinePath,
        [int]$ScanFrequencyHours
    )

    $latestPointer = Join-Path $BaselinePath 'latest-baseline.json'
    if (-not (Test-Path $latestPointer)) {
        return [pscustomobject]@{
            Exists    = $false
            IsStale   = $true
            Age       = $null
            FilePath  = $null
        }
    }

    try {
        $pointer = Get-Content -Path $latestPointer -Raw | ConvertFrom-Json
        $capturedAt = [datetime]::Parse($pointer.capturedAt)
        $ageHours = ((Get-Date) - $capturedAt).TotalHours

        return [pscustomobject]@{
            Exists    = $true
            IsStale   = ($ageHours -gt $ScanFrequencyHours)
            Age       = [math]::Round($ageHours, 1)
            FilePath  = Join-Path $BaselinePath $pointer.baselinePath
        }
    }
    catch {
        Write-Warning "Unable to parse baseline pointer: $($_.Exception.Message)"
        return [pscustomobject]@{
            Exists    = $false
            IsStale   = $true
            Age       = $null
            FilePath  = $null
        }
    }
}

#endregion

#region Main Logic

Write-Host "=== SharePoint Permissions Drift Detection — Compliance Monitor ===" -ForegroundColor Cyan
Write-Host "Configuration tier: $ConfigurationTier"
Write-Host "Tenant: $TenantUrl"

$solutionRoot = Join-Path $PSScriptRoot '..'

# Load baseline config for scan frequency
$baselineConfigPath = Join-Path $solutionRoot 'config\baseline-config.json'
$scanFrequency = 24
if (Test-Path $baselineConfigPath) {
    $baselineConfig = Get-Content -Path $baselineConfigPath -Raw | ConvertFrom-Json
    $scanFrequency = $baselineConfig.scanFrequencyHours
}

# Load tier config for overrides
$tierConfigPath = Join-Path $solutionRoot "config\$ConfigurationTier.json"
if (Test-Path $tierConfigPath) {
    $tierConfig = Get-Content -Path $tierConfigPath -Raw | ConvertFrom-Json
    if ($tierConfig.PSObject.Properties.Name -contains 'scanFrequencyHours') {
        $scanFrequency = $tierConfig.scanFrequencyHours
    }
}

$baselinesDir = Join-Path $solutionRoot 'baselines'
$reportsDir = Join-Path $solutionRoot 'reports'

# Step 1: Check baseline status
Write-Host "`nStep 1: Checking baseline status..." -ForegroundColor Yellow
$baselineStatus = Get-BaselineStatus -BaselinePath $baselinesDir -ScanFrequencyHours $scanFrequency

if (-not $baselineStatus.Exists) {
    Write-Host "  No baseline found. A new baseline should be captured using New-PermissionsBaseline.ps1."
    Write-Host "  Proceeding with drift scan using sample data."
}
elseif ($baselineStatus.IsStale) {
    Write-Host "  Baseline is stale ($($baselineStatus.Age) hours old, threshold: $scanFrequency hours)."
    Write-Host "  Consider recapturing baseline using New-PermissionsBaseline.ps1."
}
else {
    Write-Host "  Baseline is current ($($baselineStatus.Age) hours old)."
}

# Step 2: Run drift scan
Write-Host "`nStep 2: Running drift scan..." -ForegroundColor Yellow
$driftScanScript = Join-Path $PSScriptRoot 'Invoke-DriftScan.ps1'
$baselineFile = if ($baselineStatus.FilePath) { $baselineStatus.FilePath } else { "$baselinesDir\latest-baseline.json" }

$driftScanParams = @{
    TenantUrl    = $TenantUrl
    BaselinePath = $baselineFile
    OutputPath   = $reportsDir
    ConfigPath   = $baselineConfigPath
}
if ($AlertRecipient) {
    $driftScanParams['AlertRecipient'] = $AlertRecipient
}

try {
    $scanResult = & $driftScanScript @driftScanParams
    Write-Host "  Drift scan complete: $($scanResult.TotalDrift) drift item(s) detected."
    Write-Host "  HIGH: $($scanResult.HighRisk) | MEDIUM: $($scanResult.MediumRisk) | LOW: $($scanResult.LowRisk)"
}
catch {
    Write-Warning "Drift scan failed: $($_.Exception.Message)"
    $scanResult = [pscustomobject]@{
        TotalDrift = 0
        HighRisk   = 0
        MediumRisk = 0
        LowRisk    = 0
        ReportFile = $null
        Status     = 'Failed'
    }
}

# Ensure output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Step 3: Save monitoring summary
Write-Host "`nStep 3: Saving monitoring summary..." -ForegroundColor Yellow
$monitoringSummary = [pscustomobject]@{
    solution          = '17-sharepoint-permissions-drift'
    solutionCode      = 'SPD'
    monitoredAt       = (Get-Date).ToString('o')
    configurationTier = $ConfigurationTier
    tenantId          = $TenantId
    tenantUrl         = $TenantUrl
    baselineStatus    = $baselineStatus
    scanFrequencyHours = $scanFrequency
    driftSummary      = [pscustomobject]@{
        totalDrift = $scanResult.TotalDrift
        highRisk   = $scanResult.HighRisk
        mediumRisk = $scanResult.MediumRisk
        lowRisk    = $scanResult.LowRisk
        reportFile = $scanResult.ReportFile
    }
    status = if ($scanResult.TotalDrift -eq 0) { 'NoDriftDetected' } else { 'DriftDetected' }
}

$summaryPath = Join-Path $OutputPath "SPD-monitoring-$(Get-Date -Format 'yyyyMMddTHHmmss').json"
$monitoringSummary | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryPath -Encoding UTF8
Write-Host "Monitoring summary saved: $summaryPath" -ForegroundColor Green

#endregion

# Return summary
[pscustomobject]@{
    Solution          = '17-sharepoint-permissions-drift'
    ConfigurationTier = $ConfigurationTier
    BaselineStatus    = if ($baselineStatus.Exists) { 'Current' } else { 'Missing' }
    TotalDrift        = $scanResult.TotalDrift
    HighRisk          = $scanResult.HighRisk
    SummaryFile       = $summaryPath
    Status            = $monitoringSummary.status
}
