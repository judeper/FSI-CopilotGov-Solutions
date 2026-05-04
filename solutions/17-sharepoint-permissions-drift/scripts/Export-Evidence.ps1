<#
.SYNOPSIS
    Standard evidence export for SharePoint Permissions Drift Detection.

.DESCRIPTION
    Wraps Export-DriftEvidence.ps1 with the shared EvidenceExport module to produce
    a standardized evidence package. This script aligns with the common evidence
    export pattern used across all FSI-CopilotGov solutions.

.PARAMETER ConfigurationTier
    The configuration tier for evidence retention settings. Valid values: baseline, recommended, regulated.

.PARAMETER TenantId
    The Microsoft Entra tenant identifier.

.PARAMETER OutputPath
    Directory for evidence package output. Defaults to .\artifacts\SPD.

.EXAMPLE
    .\Export-Evidence.ps1 -ConfigurationTier recommended -TenantId "00000000-0000-0000-0000-000000000000"
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
    [string]$OutputPath = '.\artifacts\SPD'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\GraphAuth.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

#region Main Logic

Write-Host "=== SharePoint Permissions Drift Detection — Evidence Export ===" -ForegroundColor Cyan
Write-Host "Configuration tier: $ConfigurationTier"

$solutionRoot = Join-Path $PSScriptRoot '..'
$reportsDir = Join-Path $solutionRoot 'reports'
$baselinesDir = Join-Path $solutionRoot 'baselines'

# Find latest drift report
$latestReport = $null
if (Test-Path $reportsDir) {
    $reportFiles = Get-ChildItem -Path $reportsDir -Filter 'drift-report-*.json' -ErrorAction SilentlyContinue
    if ($reportFiles) {
        $latestReport = ($reportFiles | Sort-Object Name -Descending | Select-Object -First 1).FullName
    }
}

# Find latest baseline
$latestBaseline = $null
$baselinePointer = Join-Path $baselinesDir 'latest-baseline.json'
if (Test-Path $baselinePointer) {
    try {
        $pointer = Get-Content -Path $baselinePointer -Raw | ConvertFrom-Json
        $latestBaseline = Join-Path $baselinesDir $pointer.baselinePath
    }
    catch {
        Write-Warning "Unable to parse baseline pointer: $($_.Exception.Message)"
    }
}

# Ensure output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Delegate to Export-DriftEvidence.ps1
$exportScript = Join-Path $PSScriptRoot 'Export-DriftEvidence.ps1'
$exportParams = @{
    OutputPath        = $OutputPath
    ConfigurationTier = $ConfigurationTier
}
if ($latestReport) { $exportParams['DriftReportPath'] = $latestReport }
if ($latestBaseline) { $exportParams['BaselinePath'] = $latestBaseline }

try {
    $exportResult = & $exportScript @exportParams
    Write-Host "Evidence export complete: $($exportResult.ArtifactCount) artifact(s) produced." -ForegroundColor Green
}
catch {
    Write-Warning "Evidence export failed: $($_.Exception.Message)"
    $exportResult = [pscustomobject]@{
        ArtifactCount = 0
        Status        = 'Failed'
    }
}

#endregion

# Return summary
[pscustomobject]@{
    Solution          = '17-sharepoint-permissions-drift'
    ConfigurationTier = $ConfigurationTier
    TenantId          = $TenantId
    OutputPath        = $OutputPath
    ArtifactCount     = $exportResult.ArtifactCount
    Status            = $exportResult.Status
}
