<#
.SYNOPSIS
Applies FSI risk scoring to item-level oversharing findings.

.DESCRIPTION
Reads the CSV output from Get-ItemLevelPermissions.ps1 and applies FSI risk
scoring based on sharing type, sensitivity label, and content-type risk
weighting from the risk thresholds configuration. Items are classified as
HIGH, MEDIUM, or LOW risk. Outputs a risk-scored report CSV and a summary
JSON with counts by risk tier.

Scripts use representative sample data and do not connect to live Microsoft 365
services in their repository form.

.PARAMETER InputPath
Path to the item permissions CSV produced by Get-ItemLevelPermissions.ps1.

.PARAMETER OutputPath
Directory where the risk-scored report CSV and summary JSON will be written.

.PARAMETER ConfigPath
Path to the risk-thresholds.json configuration file.

.EXAMPLE
.\Export-OversharedItems.ps1 -InputPath .\artifacts\scan\item-permissions.csv -OutputPath .\artifacts\scored

.EXAMPLE
.\Export-OversharedItems.ps1 -InputPath .\artifacts\scan\item-permissions.csv -OutputPath .\artifacts\scored -ConfigPath .\config\risk-thresholds.json
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$InputPath,

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\scored'),

    [Parameter()]
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\config\risk-thresholds.json')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\GraphAuth.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

$sensitiveLabels = @('PII', 'Trading', 'Legal', 'Confidential')

function Get-RiskTier {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ShareType,

        [Parameter()]
        [string]$SensitivityLabel = ''
    )

    $hasSensitiveLabel = $false
    foreach ($label in $sensitiveLabels) {
        if ($SensitivityLabel -match $label) {
            $hasSensitiveLabel = $true
            break
        }
    }

    if ($ShareType -eq 'AnyoneLink') {
        return 'HIGH'
    }

    if ($ShareType -eq 'ExternalUser' -and $hasSensitiveLabel) {
        return 'HIGH'
    }

    if ($ShareType -eq 'OrgLink') {
        return 'MEDIUM'
    }

    if ($ShareType -eq 'ExternalUser' -and -not $hasSensitiveLabel) {
        return 'MEDIUM'
    }

    if ($ShareType -eq 'BroadGroup' -and -not $hasSensitiveLabel) {
        return 'LOW'
    }

    if ($ShareType -eq 'BroadGroup' -and $hasSensitiveLabel) {
        return 'MEDIUM'
    }

    return 'LOW'
}

function Get-ContentCategory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Item,

        [Parameter(Mandatory)]
        [object]$ContentTypeWeights
    )

    $itemText = '{0} {1} {2}' -f $Item.ItemPath, $Item.SensitivityLabel, $Item.LibraryName
    $bestMatch = $null
    $bestWeight = 1.0

    $weightProperties = if ($ContentTypeWeights -is [hashtable]) {
        $ContentTypeWeights.GetEnumerator()
    }
    else {
        $ContentTypeWeights.PSObject.Properties
    }

    foreach ($category in $weightProperties) {
        $catValue = $category.Value
        $keywords = if ($catValue -is [hashtable]) { $catValue['keywords'] } else { $catValue.keywords }
        $weight = if ($catValue -is [hashtable]) { $catValue['weight'] } else { $catValue.weight }

        foreach ($keyword in $keywords) {
            if ($itemText -match [regex]::Escape($keyword)) {
                if ([double]$weight -gt $bestWeight) {
                    $bestMatch = $category.Name
                    if ($null -eq $bestMatch) { $bestMatch = $category.Key }
                    $bestWeight = [double]$weight
                }
                break
            }
        }
    }

    return @{
        Category = if ($null -ne $bestMatch) { $bestMatch } else { 'general' }
        Weight = $bestWeight
    }
}

try {
    $riskConfig = (Get-Content -Path $ConfigPath -Raw) | ConvertFrom-Json
}
catch {
    Write-Warning "Failed to load risk thresholds from $ConfigPath. Using defaults."
    $riskConfig = [pscustomobject]@{
        contentTypeWeights = [pscustomobject]@{}
        baseRiskScores = [pscustomobject]@{
            AnyoneLink = 90
            ExternalUser = 70
            OrgLinkEdit = 50
            BroadGroup = 30
        }
    }
}

try {
    $items = Import-Csv -Path $InputPath -Encoding UTF8
}
catch {
    throw "Failed to read input CSV from $InputPath : $_"
}

$outputRoot = [System.IO.Path]::GetFullPath($OutputPath)
$null = New-Item -Path $outputRoot -ItemType Directory -Force

$scoredItems = foreach ($item in $items) {
    $riskTier = Get-RiskTier -ShareType $item.ShareType -SensitivityLabel $item.SensitivityLabel

    $baseScoreProperty = $item.ShareType
    if ($baseScoreProperty -eq 'OrgLink') { $baseScoreProperty = 'OrgLinkEdit' }

    $baseScore = 30
    $baseScores = $riskConfig.baseRiskScores
    $scoreValue = if ($baseScores -is [hashtable]) { $baseScores[$baseScoreProperty] } else { $baseScores.$baseScoreProperty }
    if ($null -ne $scoreValue) { $baseScore = [int]$scoreValue }

    $contentInfo = Get-ContentCategory -Item $item -ContentTypeWeights $riskConfig.contentTypeWeights
    $weightedScore = [math]::Round($baseScore * $contentInfo.Weight, 1)

    [pscustomobject]@{
        SiteUrl = $item.SiteUrl
        LibraryName = $item.LibraryName
        ItemPath = $item.ItemPath
        ItemType = $item.ItemType
        SharedWith = $item.SharedWith
        ShareType = $item.ShareType
        SensitivityLabel = $item.SensitivityLabel
        LastModified = $item.LastModified
        RiskTier = $riskTier
        BaseScore = $baseScore
        WeightedScore = $weightedScore
        ContentCategory = $contentInfo.Category
    }
}

$reportCsvPath = Join-Path $outputRoot 'risk-scored-report.csv'
$summaryJsonPath = Join-Path $outputRoot 'risk-scored-summary.json'

@($scoredItems) | Export-Csv -Path $reportCsvPath -NoTypeInformation -Encoding UTF8

$summary = [ordered]@{
    totalItems = @($scoredItems).Count
    highRisk = @($scoredItems | Where-Object { $_.RiskTier -eq 'HIGH' }).Count
    mediumRisk = @($scoredItems | Where-Object { $_.RiskTier -eq 'MEDIUM' }).Count
    lowRisk = @($scoredItems | Where-Object { $_.RiskTier -eq 'LOW' }).Count
    generatedAt = (Get-Date).ToString('o')
    shareTypeCounts = [ordered]@{
        AnyoneLink = @($scoredItems | Where-Object { $_.ShareType -eq 'AnyoneLink' }).Count
        ExternalUser = @($scoredItems | Where-Object { $_.ShareType -eq 'ExternalUser' }).Count
        OrgLink = @($scoredItems | Where-Object { $_.ShareType -eq 'OrgLink' }).Count
        BroadGroup = @($scoredItems | Where-Object { $_.ShareType -eq 'BroadGroup' }).Count
    }
}

$summary | ConvertTo-Json -Depth 5 | Set-Content -Path $summaryJsonPath -Encoding UTF8

[pscustomobject]@{
    TotalItems = $summary.totalItems
    HighRisk = $summary.highRisk
    MediumRisk = $summary.mediumRisk
    LowRisk = $summary.lowRisk
    ReportPath = $reportCsvPath
    SummaryPath = $summaryJsonPath
}
