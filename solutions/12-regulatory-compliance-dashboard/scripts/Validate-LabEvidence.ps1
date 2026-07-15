<#
.SYNOPSIS
Validates an already-generated Solution 12 lab evidence output set without mutating artifacts.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputPath = 'lab-output'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$validatePackageScript = Join-Path $repoRoot 'scripts\validate-lab-package.ps1'
if (-not (Test-Path -Path $validatePackageScript -PathType Leaf)) {
    throw "validate-lab-package wrapper not found at $validatePackageScript"
}

$resolvedOutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
$packagePath = Join-Path $resolvedOutputPath '12-regulatory-compliance-dashboard-evidence.json'
$dashboardExportPath = Join-Path $resolvedOutputPath 'dashboard-export.json'
$monitorStatusPath = Join-Path $resolvedOutputPath 'rcd-monitoring-status.json'
$controlSnapshotPath = Join-Path $resolvedOutputPath 'control-status-snapshot.json'

foreach ($requiredFile in @($packagePath, $dashboardExportPath, $monitorStatusPath, $controlSnapshotPath)) {
    if (-not (Test-Path -Path $requiredFile -PathType Leaf)) {
        throw "Required validation input was not found: $requiredFile"
    }
}

& $validatePackageScript -Path $packagePath | Out-Null

$dashboardExport = Get-Content -Path $dashboardExportPath -Raw -Encoding utf8 | ConvertFrom-Json -Depth 20
$monitorStatus = Get-Content -Path $monitorStatusPath -Raw -Encoding utf8 | ConvertFrom-Json -Depth 20
$controlSnapshot = @(Get-Content -Path $controlSnapshotPath -Raw -Encoding utf8 | ConvertFrom-Json -Depth 20)

if ([string]$dashboardExport.dataQuality.overall -ne 'gap') {
    throw 'dashboard-export dataQuality.overall must be "gap" while seed evidence remains unresolved.'
}

$unresolvedPackages = @(
    @($dashboardExport.referencedEvidencePackages) |
        Where-Object { [string]$_.hashState -eq 'unresolved' -or [string]$_.freshnessStatus -eq 'unknown' }
)
if ($unresolvedPackages.Count -eq 0) {
    throw 'dashboard-export must retain unresolved seed package evidence references during documentation-first validation.'
}

$invalidCurrentPackages = @(
    @($dashboardExport.referencedEvidencePackages) |
        Where-Object {
            ([string]$_.freshnessStatus -eq 'current') -and (
                [string]::IsNullOrWhiteSpace([string]$_.sourceLastModified) -or
                [string]::IsNullOrWhiteSpace([string]$_.hash) -or
                ([string]$_.hash -eq 'pending-runtime-resolution') -or
                ([string]$_.hashState -eq 'unresolved')
            )
        }
)
if ($invalidCurrentPackages.Count -gt 0) {
    throw ('Referenced package freshness is invalid: {0} package(s) are marked current without resolved source timestamp/hash.' -f $invalidCurrentPackages.Count)
}

if (-not [bool]$monitorStatus.DataQualityGap) {
    throw 'rcd-monitoring-status DataQualityGap must be true for unresolved documentation-first seed evidence.'
}

if ([string]$monitorStatus.SnapshotSource -ne 'control-status-snapshot') {
    throw ('rcd-monitoring-status SnapshotSource must be "control-status-snapshot" for the seed evidence path, but was "{0}".' -f [string]$monitorStatus.SnapshotSource)
}

$allowedCoverageStates = @('implemented', 'partial', 'monitor-only', 'playbook-only', 'not-applicable')
$invalidControlStates = @(
    $controlSnapshot |
        Where-Object { [string]$_.status -notin $allowedCoverageStates }
)
if ($invalidControlStates.Count -gt 0) {
    $invalidStates = @($invalidControlStates | ForEach-Object { [string]$_.status } | Sort-Object -Unique)
    throw ('control-status-snapshot contains non-coverage status values: {0}' -f ($invalidStates -join ', '))
}

$dispositionFields = @('disposition', 'labDisposition')
$snapshotDispositionLeaks = @(
    $controlSnapshot |
        Where-Object {
            $propertyNames = @($_.PSObject.Properties.Name)
            @($dispositionFields | Where-Object { $_ -in $propertyNames }).Count -gt 0
        }
)
if ($snapshotDispositionLeaks.Count -gt 0) {
    throw ('control-status-snapshot contains lab disposition fields ({0}), which must remain separate from coverage status values.' -f ($dispositionFields -join ', '))
}

[pscustomobject]@{
    OutputPath = $resolvedOutputPath
    PackagePath = $packagePath
    DashboardExportPath = $dashboardExportPath
    MonitorStatusPath = $monitorStatusPath
    ControlSnapshotPath = $controlSnapshotPath
    UnresolvedReferencedPackageCount = $unresolvedPackages.Count
}
