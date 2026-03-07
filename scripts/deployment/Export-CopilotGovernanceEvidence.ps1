[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SourcePath,
    [Parameter(Mandatory)]
    [string]$OutputPath
)

Import-Module (Join-Path $PSScriptRoot '..\common\EvidenceExport.psm1') -Force
$null = New-Item -ItemType Directory -Path $OutputPath -Force
$files = Get-ChildItem -Path $SourcePath -Recurse -Filter '*.json' | Where-Object {
    try {
        $candidate = Get-Content -Path $_.FullName -Raw -Encoding utf8 | ConvertFrom-Json -Depth 30
        $candidate.PSObject.Properties.Name -contains 'metadata' -and
        $candidate.PSObject.Properties.Name -contains 'summary' -and
        $candidate.PSObject.Properties.Name -contains 'controls' -and
        $candidate.PSObject.Properties.Name -contains 'artifacts'
    }
    catch {
        $false
    }
}
$manifest = [ordered]@{
    exportedAt = (Get-Date).ToString('o')
    fileCount = $files.Count
    files = @()
}
foreach ($file in $files) {
    $validation = Test-CopilotGovEvidencePackage -Path $file.FullName
    if (-not $validation.IsValid) {
        $details = ($validation.Errors | ForEach-Object { ' - {0}' -f $_ }) -join [Environment]::NewLine
        throw ("Evidence validation failed for {0}:{1}{2}" -f $file.FullName, [Environment]::NewLine, $details)
    }

    $package = Get-Content -Path $file.FullName -Raw -Encoding utf8 | ConvertFrom-Json -Depth 30
    $manifest.files += [pscustomobject]@{
        solution = $package.metadata.solution
        solutionCode = $package.metadata.solutionCode
        tier = $package.metadata.tier
        path = $file.FullName
        hash = (Get-CopilotGovSha256 -Path $file.FullName)
        artifactCount = @($package.artifacts).Count
    }
}
$manifestPath = Join-Path $OutputPath 'unified-evidence-manifest.json'
$manifest | ConvertTo-Json -Depth 6 | Set-Content -Path $manifestPath -Encoding utf8
Write-CopilotGovSha256File -Path $manifestPath | Out-Null
$manifest
