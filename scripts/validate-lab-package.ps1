[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter()]
    [string]$ResultPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$modulePath = Join-Path $repoRoot 'scripts/common/EvidenceExport.psm1'
if (-not (Test-Path -Path $modulePath -PathType Leaf)) {
    throw "Shared evidence module not found at $modulePath"
}

Import-Module $modulePath -Force

$resolvedPackagePath = (Resolve-Path -Path $Path -ErrorAction Stop).Path
$validation = Test-CopilotGovEvidencePackage -Path $resolvedPackagePath
if (-not $validation.IsValid) {
    $details = if ($validation.Errors.Count -gt 0) {
        ($validation.Errors | ForEach-Object { ' - {0}' -f $_ }) -join [Environment]::NewLine
    }
    else {
        ' - Unknown package validation error.'
    }
    throw ("Lab package validation failed for {0}:{1}{2}" -f $resolvedPackagePath, [Environment]::NewLine, $details)
}

$resolvedResultPath = $null
if ($PSBoundParameters.ContainsKey('ResultPath') -and -not [string]::IsNullOrWhiteSpace($ResultPath)) {
    $resolvedResultPath = (Resolve-Path -Path $ResultPath -ErrorAction Stop).Path
    $resultValidatorPath = Join-Path $repoRoot 'scripts/validate-lab-result.py'
    if (-not (Test-Path -Path $resultValidatorPath -PathType Leaf)) {
        throw "Lab result validator not found at $resultValidatorPath"
    }

    $pythonCommand = Get-Command python -ErrorAction Stop
    & $pythonCommand.Source $resultValidatorPath $resolvedResultPath
    if ($LASTEXITCODE -ne 0) {
        throw "Lab result validation failed for $resolvedResultPath."
    }
}

Write-Host ("Lab package validation passed: {0}" -f $resolvedPackagePath)
if ($null -ne $resolvedResultPath) {
    Write-Host ("Lab result validation passed: {0}" -f $resolvedResultPath)
}

[pscustomobject]@{
    PackagePath   = $resolvedPackagePath
    ResultPath    = $resolvedResultPath
    ArtifactCount = $validation.ArtifactCount
    Artifacts     = @($validation.Artifacts)
}
