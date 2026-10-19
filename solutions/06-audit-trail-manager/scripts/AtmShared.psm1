#Requires -Version 7.0

function Resolve-AtmOutputPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if ([IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    return [IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

function Read-AtmJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return Get-Content -Path $Path -Raw | ConvertFrom-Json -Depth 20
}

function Write-AtmJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [object]$InputObject
    )

    $directory = Split-Path -Path $Path -Parent
    if (-not (Test-Path -Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    # Hash the same UTF-8/LF bytes that Git preserves in maintained evidence samples.
    $json = ($InputObject | ConvertTo-Json -Depth 20) -replace "`r`n?", "`n"
    $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    [IO.File]::WriteAllText($resolvedPath, "$json`n", [Text.UTF8Encoding]::new($false))
    return $Path
}

Export-ModuleMember -Function Resolve-AtmOutputPath, Read-AtmJsonFile, Write-AtmJsonFile
