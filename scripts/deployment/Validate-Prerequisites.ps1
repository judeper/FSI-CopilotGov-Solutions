[CmdletBinding()]
param()

$results = [ordered]@{
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    HasPython = [bool](Get-Command python -ErrorAction SilentlyContinue)
    HasDocsConfig = Test-Path -Path (Join-Path $PSScriptRoot '..\..\mkdocs.yml')
    HasSolutionCatalog = Test-Path -Path (Join-Path $PSScriptRoot '..\..\data\solution-catalog.json')
}

[pscustomobject]$results
