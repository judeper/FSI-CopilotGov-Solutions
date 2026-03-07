[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path
)

Import-Module (Join-Path $PSScriptRoot '..\common\EvidenceExport.psm1') -Force
Test-EvidencePackageHash -Path $Path
