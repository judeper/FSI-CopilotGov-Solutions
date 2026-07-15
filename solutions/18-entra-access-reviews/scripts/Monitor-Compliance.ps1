<#
.SYNOPSIS
Monitors access review compliance status and reports coverage gaps.

.DESCRIPTION
Loads the solution configuration, queries active access review definitions and
instances, checks review completion rates, identifies sites without active reviews,
and exports a compliance status summary. Prefers emitted review artifacts when available
and falls back to representative sample data when no parseable artifacts are present.

.PARAMETER ConfigurationTier
Selects the governance tier to apply. Supported values are baseline,
recommended, and regulated.

.PARAMETER TenantId
Tenant GUID used for Graph context and evidence labeling.

.PARAMETER MaxSites
Maximum number of sites to include in the compliance check.

.PARAMETER ExportPath
Directory where the compliance monitoring output will be written.

.PARAMETER ReviewArtifactsPath
Directory containing emitted review artifacts (`access-review-definitions.json` and
`review-decisions.json`). When present, monitoring uses those artifacts; otherwise it falls
back to representative sample data.

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
    [string]$ReviewArtifactsPath = (Join-Path $PSScriptRoot '..\artifacts\reviews'),

    [Parameter()]
    [string]$ExportPath = (Join-Path $PSScriptRoot '..\artifacts\monitor')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

function Get-JsonArrayArtifact {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        return @()
    }

    try {
        return @((Get-Content -Path $Path -Raw | ConvertFrom-Json))
    }
    catch {
        Write-Warning "Failed to parse artifact '$Path': $($_.Exception.Message)"
        return @()
    }
}

function Get-ComplianceStatusFromArtifacts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ReviewArtifactsPath
    )

    $artifactRoot = [System.IO.Path]::GetFullPath($ReviewArtifactsPath)
    if (-not (Test-Path -Path $artifactRoot -PathType Container)) {
        return $null
    }

    $definitions = Get-JsonArrayArtifact -Path (Join-Path $artifactRoot 'access-review-definitions.json')
    $decisions = Get-JsonArrayArtifact -Path (Join-Path $artifactRoot 'review-decisions.json')

    if (($definitions.Count -eq 0) -and ($decisions.Count -eq 0)) {
        return $null
    }

    $definitionBySite = @{}
    foreach ($definition in $definitions) {
        $siteUrl = [string]$definition.siteUrl
        if ([string]::IsNullOrWhiteSpace($siteUrl)) {
            continue
        }
        if (-not $definitionBySite.ContainsKey($siteUrl)) {
            $definitionBySite[$siteUrl] = $definition
        }
    }

    $decisionsBySite = @{}
    foreach ($decision in $decisions) {
        $siteUrl = [string]$decision.siteUrl
        if ([string]::IsNullOrWhiteSpace($siteUrl)) {
            continue
        }
        if (-not $decisionsBySite.ContainsKey($siteUrl)) {
            $decisionsBySite[$siteUrl] = @()
        }
        $decisionsBySite[$siteUrl] += $decision
    }

    $siteKeys = @($definitionBySite.Keys + $decisionsBySite.Keys | Sort-Object -Unique)
    if ($siteKeys.Count -eq 0) {
        return $null
    }

    $findings = @()
    foreach ($siteUrl in $siteKeys) {
        $definition = if ($definitionBySite.ContainsKey($siteUrl)) { $definitionBySite[$siteUrl] } else { $null }
        $siteDecisions = if ($decisionsBySite.ContainsKey($siteUrl)) { @($decisionsBySite[$siteUrl]) } else { @() }

        $pendingDecisions = @($siteDecisions | Where-Object { [string]$_.status -eq 'pending' -or [string]$_.decision -eq 'NotReviewed' }).Count
        $totalDecisions = @($siteDecisions).Count
        $completedDecisions = $totalDecisions - $pendingDecisions
        $completionRate = if ($totalDecisions -gt 0) {
            [int][math]::Round(($completedDecisions / $totalDecisions) * 100, 0)
        }
        else {
            0
        }

        $reviewedDates = @(
            $siteDecisions |
                Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.reviewedAt) } |
                ForEach-Object { try { [datetime]::Parse([string]$_.reviewedAt) } catch { $null } } |
                Where-Object { $null -ne $_ } |
                Sort-Object -Descending
        )
        $nextDates = @(
            $siteDecisions |
                Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.instanceEndDateTime) } |
                ForEach-Object { try { [datetime]::Parse([string]$_.instanceEndDateTime) } catch { $null } } |
                Where-Object { $null -ne $_ } |
                Sort-Object
        )

        $reviewStatus = if ($totalDecisions -gt 0) { 'active' } elseif ($null -ne $definition) { 'configured-no-decisions' } else { 'not-configured' }
        $complianceStatus = switch ($reviewStatus) {
            'not-configured' { 'gap' }
            default {
                if ($pendingDecisions -gt 0) { 'at-risk' }
                elseif ($totalDecisions -gt 0) { 'compliant' }
                else { 'monitoring' }
            }
        }

        $riskTier = if (($null -ne $definition) -and -not [string]::IsNullOrWhiteSpace([string]$definition.riskTier)) {
            [string]$definition.riskTier
        }
        elseif ($siteDecisions.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$siteDecisions[0].riskTier)) {
            [string]$siteDecisions[0].riskTier
        }
        else {
            'UNKNOWN'
        }

        $owner = if (($null -ne $definition) -and -not [string]::IsNullOrWhiteSpace([string]$definition.reviewer)) {
            [string]$definition.reviewer
        }
        else {
            $null
        }

        $findings += [pscustomobject]@{
            SiteUrl = $siteUrl
            RiskTier = $riskTier
            ReviewStatus = $reviewStatus
            LastReviewDate = if ($reviewedDates.Count -gt 0) { $reviewedDates[0].ToString('yyyy-MM-dd') } else { $null }
            NextReviewDate = if ($nextDates.Count -gt 0) { $nextDates[0].ToString('yyyy-MM-dd') } else { $null }
            CompletionRate = $completionRate
            PendingDecisions = $pendingDecisions
            Owner = $owner
            ComplianceStatus = $complianceStatus
        }
    }

    return [pscustomobject]@{
        Findings = $findings
        DataSource = 'emitted-artifacts'
        DataSourceNotes = "Read review artifacts from '$artifactRoot'."
    }
}

$configuration = Get-Configuration -ConfigurationTier $ConfigurationTier

$artifactStatus = Get-ComplianceStatusFromArtifacts -ReviewArtifactsPath $ReviewArtifactsPath
if ($null -ne $artifactStatus) {
    Write-Verbose $artifactStatus.DataSourceNotes
    $complianceResults = @($artifactStatus.Findings)
    $dataSource = [string]$artifactStatus.DataSource
    $dataSourceNotes = [string]$artifactStatus.DataSourceNotes
}
else {
    Write-Verbose 'Using representative sample data for compliance monitoring.'
    $complianceResults = Get-SampleComplianceStatus
    $dataSource = 'sample-data'
    $dataSourceNotes = 'No emitted review artifacts were found or parseable; representative sample data was used.'
}

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
    dataSource = $dataSource
    dataSourceNotes = $dataSourceNotes
    totalSites = @($complianceResults).Count
    compliant = $compliantCount
    atRisk = $atRiskCount
    coverageGaps = $gapCount
    findings = @($complianceResults)
}

$outputFile = Join-Path $outputRoot 'compliance-status.json'
$summary | ConvertTo-Json -Depth 10 | Set-Content -Path $outputFile -Encoding utf8

$complianceResults
