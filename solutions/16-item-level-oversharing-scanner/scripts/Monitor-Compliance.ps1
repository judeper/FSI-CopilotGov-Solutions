<#
.SYNOPSIS
Orchestrates the item-level oversharing scan and score workflow.

.DESCRIPTION
Loads the selected solution configuration, runs the item-level permissions
scan using Get-ItemLevelPermissions.ps1, applies FSI risk scoring using
Export-OversharedItems.ps1, and returns the scored results. This script
provides a single entry point for scheduled monitoring of item-level
oversharing.

Scripts use representative sample data and do not connect to live Microsoft 365
services in their repository form.

.PARAMETER ConfigurationTier
Selects the governance tier to apply. Supported values are baseline,
recommended, and regulated.

.PARAMETER TenantId
Tenant GUID used to label the monitoring run.

.PARAMETER SiteUrls
Optional list of SharePoint site URLs to scan. When omitted, uses
representative sample sites.

.PARAMETER TenantUrl
SharePoint tenant admin URL used for PnP connection.

.PARAMETER ExportPath
Optional directory used to write monitoring output files.

.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier recommended -TenantId 00000000-0000-0000-0000-000000000000 -TenantUrl "https://tenant-admin.sharepoint.com"

.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier regulated -TenantId 00000000-0000-0000-0000-000000000000 -SiteUrls @("https://tenant.sharepoint.com/sites/finance") -TenantUrl "https://tenant-admin.sharepoint.com" -ExportPath .\artifacts\monitor
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
    [string[]]$SiteUrls,

    [Parameter()]
    [string]$TenantUrl = 'https://tenant-admin.sharepoint.com',

    [Parameter()]
    [string]$ExportPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\GraphAuth.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

function ConvertTo-Hashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$InputObject
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $table = @{}
        foreach ($key in $InputObject.Keys) {
            $table[$key] = ConvertTo-Hashtable -InputObject $InputObject[$key]
        }
        return $table
    }

    if ($InputObject -is [pscustomobject]) {
        $table = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $table[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
        }
        return $table
    }

    if (($InputObject -is [System.Collections.IEnumerable]) -and -not ($InputObject -is [string])) {
        $list = @()
        foreach ($item in $InputObject) {
            $list += ,(ConvertTo-Hashtable -InputObject $item)
        }
        return $list
    }

    return $InputObject
}

function Merge-Hashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Base,

        [Parameter(Mandatory)]
        [hashtable]$Override
    )

    $merged = @{}

    foreach ($key in $Base.Keys) {
        $merged[$key] = $Base[$key]
    }

    foreach ($key in $Override.Keys) {
        if (($merged.ContainsKey($key)) -and ($merged[$key] -is [hashtable]) -and ($Override[$key] -is [hashtable])) {
            $merged[$key] = Merge-Hashtable -Base $merged[$key] -Override $Override[$key]
        }
        else {
            $merged[$key] = $Override[$key]
        }
    }

    return $merged
}

function Get-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$ConfigurationTier
    )

    $configRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\config'))
    $defaultConfig = ConvertTo-Hashtable -InputObject ((Get-Content -Path (Join-Path $configRoot 'default-config.json') -Raw) | ConvertFrom-Json)
    $tierConfig = ConvertTo-Hashtable -InputObject ((Get-Content -Path (Join-Path $configRoot ("{0}.json" -f $ConfigurationTier)) -Raw) | ConvertFrom-Json)

    return (Merge-Hashtable -Base $defaultConfig -Override $tierConfig)
}

$configuration = Get-Configuration -ConfigurationTier $ConfigurationTier

if (-not $SiteUrls) {
    $SiteUrls = @(
        "https://contoso.sharepoint.com/sites/finance",
        "https://contoso.sharepoint.com/sites/legal",
        "https://contoso.sharepoint.com/sites/compliance"
    )
}

$scanOutputPath = if ($ExportPath) {
    Join-Path ([System.IO.Path]::GetFullPath($ExportPath)) 'scan'
}
else {
    Join-Path $PSScriptRoot '..\artifacts\monitor\scan'
}

$scoreOutputPath = if ($ExportPath) {
    Join-Path ([System.IO.Path]::GetFullPath($ExportPath)) 'scored'
}
else {
    Join-Path $PSScriptRoot '..\artifacts\monitor\scored'
}

$scanScript = Join-Path $PSScriptRoot 'Get-ItemLevelPermissions.ps1'
$scoreScript = Join-Path $PSScriptRoot 'Export-OversharedItems.ps1'

Write-Verbose "Starting item-level scan for $($SiteUrls.Count) sites"

try {
    $scanResult = & $scanScript -SiteUrls $SiteUrls -TenantUrl $TenantUrl -OutputPath $scanOutputPath
    Write-Verbose "Scan complete: $($scanResult.ItemsFound) items found"
}
catch {
    Write-Warning "Item-level scan failed: $_"
    throw
}

$scanCsvPath = Join-Path $scanOutputPath 'item-permissions.csv'
if (-not (Test-Path -Path $scanCsvPath)) {
    Write-Warning 'No scan output found. Returning empty results.'
    return @()
}

try {
    $scoreResult = & $scoreScript -InputPath $scanCsvPath -OutputPath $scoreOutputPath
    Write-Verbose "Scoring complete: HIGH=$($scoreResult.HighRisk) MEDIUM=$($scoreResult.MediumRisk) LOW=$($scoreResult.LowRisk)"
}
catch {
    Write-Warning "Risk scoring failed: $_"
    throw
}

$scoredCsvPath = Join-Path $scoreOutputPath 'risk-scored-report.csv'
if (Test-Path -Path $scoredCsvPath) {
    $scoredItems = Import-Csv -Path $scoredCsvPath -Encoding UTF8
    return @($scoredItems)
}

return @()
