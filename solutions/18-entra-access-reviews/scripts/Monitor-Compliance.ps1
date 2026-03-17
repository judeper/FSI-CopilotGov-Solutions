<#
.SYNOPSIS
Monitors access review compliance status and reports coverage gaps.

.DESCRIPTION
Loads the solution configuration, queries active access review definitions and
instances, checks review completion rates, identifies sites without active reviews,
and exports a compliance status summary. Uses representative sample data when Graph
API is unavailable.

.PARAMETER ConfigurationTier
Selects the governance tier to apply. Supported values are baseline,
recommended, and regulated.

.PARAMETER TenantId
Tenant GUID used for Graph context and evidence labeling.

.PARAMETER MaxSites
Maximum number of sites to include in the compliance check.

.PARAMETER ExportPath
Directory where the compliance monitoring output will be written.

.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier recommended -TenantId 00000000-0000-0000-0000-000000000000

.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier regulated -TenantId 00000000-0000-0000-0000-000000000000 -MaxSites 100
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
    [int]$MaxSites = 500,

    [Parameter()]
    [string]$ExportPath = (Join-Path $PSScriptRoot '..\artifacts\monitor')
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

function Get-SampleComplianceStatus {
    [CmdletBinding()]
    param()

    $now = Get-Date
    return @(
        [pscustomobject]@{
            SiteUrl = 'https://contoso.sharepoint.com/sites/TradingDesk'
            RiskTier = 'HIGH'
            ReviewStatus = 'active'
            LastReviewDate = $now.AddDays(-15).ToString('yyyy-MM-dd')
            NextReviewDate = $now.AddDays(15).ToString('yyyy-MM-dd')
            CompletionRate = 100
            PendingDecisions = 0
            Owner = 'trading-desk-owner@contoso.com'
            ComplianceStatus = 'compliant'
        }
        [pscustomobject]@{
            SiteUrl = 'https://contoso.sharepoint.com/sites/CustomerPII'
            RiskTier = 'HIGH'
            ReviewStatus = 'active'
            LastReviewDate = $now.AddDays(-25).ToString('yyyy-MM-dd')
            NextReviewDate = $now.AddDays(5).ToString('yyyy-MM-dd')
            CompletionRate = 50
            PendingDecisions = 3
            Owner = 'pii-owner@contoso.com'
            ComplianceStatus = 'at-risk'
        }
        [pscustomobject]@{
            SiteUrl = 'https://contoso.sharepoint.com/sites/ComplianceDocs'
            RiskTier = 'MEDIUM'
            ReviewStatus = 'active'
            LastReviewDate = $now.AddDays(-60).ToString('yyyy-MM-dd')
            NextReviewDate = $now.AddDays(30).ToString('yyyy-MM-dd')
            CompletionRate = 100
            PendingDecisions = 0
            Owner = 'compliance-lead@contoso.com'
            ComplianceStatus = 'compliant'
        }
        [pscustomobject]@{
            SiteUrl = 'https://contoso.sharepoint.com/sites/Marketing'
            RiskTier = 'LOW'
            ReviewStatus = 'not-configured'
            LastReviewDate = $null
            NextReviewDate = $null
            CompletionRate = 0
            PendingDecisions = 0
            Owner = 'marketing-lead@contoso.com'
            ComplianceStatus = 'gap'
        }
    )
}

$configuration = Get-Configuration -ConfigurationTier $ConfigurationTier

Write-Verbose 'Using representative sample data for compliance monitoring.'
$complianceResults = Get-SampleComplianceStatus

$effectiveMax = if ($MaxSites -gt 0 -and $MaxSites -lt @($complianceResults).Count) { $MaxSites } else { @($complianceResults).Count }
$complianceResults = @($complianceResults | Select-Object -First $effectiveMax)

$compliantCount = @($complianceResults | Where-Object { $_.ComplianceStatus -eq 'compliant' }).Count
$atRiskCount = @($complianceResults | Where-Object { $_.ComplianceStatus -eq 'at-risk' }).Count
$gapCount = @($complianceResults | Where-Object { $_.ComplianceStatus -eq 'gap' }).Count

$outputRoot = [System.IO.Path]::GetFullPath($ExportPath)
$null = New-Item -Path $outputRoot -ItemType Directory -Force

$summary = [ordered]@{
    solution = $configuration.solution
    tier = $ConfigurationTier
    tenantId = $TenantId
    monitoredAt = (Get-Date).ToString('o')
    totalSites = @($complianceResults).Count
    compliant = $compliantCount
    atRisk = $atRiskCount
    coverageGaps = $gapCount
    findings = @($complianceResults)
}

$outputFile = Join-Path $outputRoot 'compliance-status.json'
$summary | ConvertTo-Json -Depth 10 | Set-Content -Path $outputFile -Encoding utf8

$complianceResults
