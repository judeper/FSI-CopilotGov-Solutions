[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter()]
    [string[]]$ExpectedArtifacts = @()
)

Import-Module (Join-Path $PSScriptRoot '..\common\EvidenceExport.psm1') -Force
$validation = Test-CopilotGovEvidencePackage -Path $Path -ExpectedArtifacts $ExpectedArtifacts
if (-not $validation.IsValid) {
    $details = ($validation.Errors | ForEach-Object { ' - {0}' -f $_ }) -join [Environment]::NewLine
    throw ("Evidence validation failed for {0}:{1}{2}" -f $Path, [Environment]::NewLine, $details)
}

$validation
