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

function Get-ConfigValue {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [AllowNull()]
        [object]$DefaultValue = $null
    )

    if ($null -eq $InputObject) {
        return $DefaultValue
    }

    if ($InputObject -is [hashtable]) {
        if ($InputObject.ContainsKey($Name)) {
            return $InputObject[$Name]
        }
        return $DefaultValue
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -ne $property) {
        return $property.Value
    }

    return $DefaultValue
}

function Get-RiskThreshold {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [object]$RiskConfig
    )

    $thresholds = Get-ConfigValue -InputObject $RiskConfig -Name 'riskThresholds' -DefaultValue $null
    if ($null -eq $thresholds) {
        $defaultConfigPath = Join-Path $PSScriptRoot '..\config\default-config.json'
        if (Test-Path -Path $defaultConfigPath) {
            try {
                $defaultConfig = (Get-Content -Path $defaultConfigPath -Raw) | ConvertFrom-Json
                $thresholds = Get-ConfigValue -InputObject $defaultConfig -Name 'riskThresholds' -DefaultValue $null
            }
            catch {
                Write-Warning "Failed to load riskThresholds from default configuration: $_"
            }
        }
    }

    if ($null -eq $thresholds) {
        return [pscustomobject]@{
            high = 70
            medium = 40
            low = 0
        }
    }

    return $thresholds
}

function Get-RiskTier {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ShareType,

        [Parameter()]
        [string]$SensitivityLabel = '',

        [Parameter(Mandatory)]
        [double]$WeightedScore,

        [Parameter(Mandatory)]
        [object]$RiskThresholds
    )

    $highThreshold = [double](Get-ConfigValue -InputObject $RiskThresholds -Name 'high' -DefaultValue 70)
    $mediumThreshold = [double](Get-ConfigValue -InputObject $RiskThresholds -Name 'medium' -DefaultValue 40)
    $lowThreshold = [double](Get-ConfigValue -InputObject $RiskThresholds -Name 'low' -DefaultValue 0)

    $scoreTier = if ($WeightedScore -ge $highThreshold) {
        'HIGH'
    }
    elseif ($WeightedScore -ge $mediumThreshold) {
        'MEDIUM'
    }
    elseif ($WeightedScore -ge $lowThreshold) {
        'LOW'
    }
    else {
        'LOW'
    }

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

    if ($ShareType -eq 'BroadGroup' -and $hasSensitiveLabel -and $scoreTier -eq 'LOW') {
        return 'MEDIUM'
    }

    return $scoreTier
}

function Get-ContentCategory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Item,

        [Parameter(Mandatory)]
        [object]$ContentTypeWeights
    )

    $itemPathForMatching = [string]$Item.ItemPath
    $libraryNameForMatching = [string]$Item.LibraryName
    if (-not [string]::IsNullOrWhiteSpace($itemPathForMatching) -and -not [string]::IsNullOrWhiteSpace($libraryNameForMatching)) {
        $libraryPattern = '(?i)[/\\]{0}[/\\]?(.*)$' -f [regex]::Escape($libraryNameForMatching)
        $libraryMatch = [regex]::Match($itemPathForMatching, $libraryPattern)
        if ($libraryMatch.Success -and $libraryMatch.Groups.Count -gt 1) {
            $itemPathForMatching = $libraryMatch.Groups[1].Value
        }
    }

    $itemText = '{0} {1} {2}' -f $itemPathForMatching, $Item.SensitivityLabel, $libraryNameForMatching
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
        riskThresholds = [pscustomobject]@{
            high = 70
            medium = 40
            low = 0
        }
    }
}

$riskThresholds = Get-RiskThreshold -RiskConfig $riskConfig

try {
    $items = Import-Csv -Path $InputPath -Encoding UTF8
}
catch {
    throw "Failed to read input CSV from $InputPath : $_"
}

$outputRoot = [System.IO.Path]::GetFullPath($OutputPath)
$null = New-Item -Path $outputRoot -ItemType Directory -Force

$scoredItems = foreach ($item in $items) {
    $baseScoreProperty = $item.ShareType
    if ($baseScoreProperty -eq 'OrgLink') { $baseScoreProperty = 'OrgLinkEdit' }

    $baseScore = 30
    $baseScores = $riskConfig.baseRiskScores
    $scoreValue = if ($baseScores -is [hashtable]) { $baseScores[$baseScoreProperty] } else { $baseScores.$baseScoreProperty }
    if ($null -ne $scoreValue) { $baseScore = [int]$scoreValue }

    $contentInfo = Get-ContentCategory -Item $item -ContentTypeWeights $riskConfig.contentTypeWeights
    $weightedScore = [math]::Round($baseScore * $contentInfo.Weight, 1)
    $riskTier = Get-RiskTier -ShareType $item.ShareType -SensitivityLabel $item.SensitivityLabel -WeightedScore $weightedScore -RiskThresholds $riskThresholds

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
