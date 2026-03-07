[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SourcePath,
    [Parameter(Mandatory)]
    [string]$OutputPath
)

Import-Module (Join-Path $PSScriptRoot '..\common\EvidenceExport.psm1') -Force
$null = New-Item -ItemType Directory -Path $OutputPath -Force
$files = Get-ChildItem -Path $SourcePath -Recurse -Filter '*-evidence.json'
$manifest = [ordered]@{
    exportedAt = (Get-Date).ToString('o')
    fileCount = $files.Count
    files = @()
}
foreach ($file in $files) {
    $manifest.files += [pscustomobject]@{
        path = $file.FullName
        hash = (Get-CopilotGovSha256 -Path $file.FullName)
    }
}
$manifestPath = Join-Path $OutputPath 'unified-evidence-manifest.json'
$manifest | ConvertTo-Json -Depth 6 | Set-Content -Path $manifestPath -Encoding utf8
Set-Content -Path ($manifestPath + '.sha256') -Value ("{0}  {1}" -f (Get-CopilotGovSha256 -Path $manifestPath), 'unified-evidence-manifest.json') -Encoding utf8
$manifest
