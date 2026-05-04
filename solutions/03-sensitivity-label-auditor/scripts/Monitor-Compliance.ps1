<#
.SYNOPSIS
Monitors sensitivity label coverage across SharePoint, OneDrive, and Exchange.

.DESCRIPTION
Loads the selected governance tier, resolves the workloads to audit, simulates workload-specific
label coverage collection, calculates workload and overall coverage metrics, cross-references
oversharing risk outputs when available, generates unlabeled content findings, and prepares a
remediation manifest. The workload functions are safe stubs intended to be replaced with approved
Microsoft Graph collection logic.

.PARAMETER ConfigurationTier
The governance tier to evaluate. Valid values are baseline, recommended, and regulated.

.PARAMETER TenantId
The Microsoft Entra tenant ID or primary tenant domain for the scan target.

.PARAMETER WorkloadsToAudit
Optional workload override. When omitted, the selected tier defines the workload scope.

.PARAMETER MaxItemsPerWorkload
Optional maximum item count to evaluate per workload. When omitted, the tier configuration value is used.

.PARAMETER OutputPath
Directory where monitoring artifacts are written.

.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier recommended -TenantId "contoso.onmicrosoft.com"

.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier baseline -TenantId "contoso.onmicrosoft.com" -WorkloadsToAudit sharePoint -MaxItemsPerWorkload 5000

.NOTES
This script reads prior oversharing assessment outputs from solution 02 when available so unlabeled
content in high-risk locations can be escalated in the remediation list.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter(Mandatory)]
    [string]$TenantId,

    [Parameter()]
    [ValidateSet('sharePoint', 'oneDrive', 'exchange')]
    [string[]]$WorkloadsToAudit,

    [Parameter()]
    [int]$MaxItemsPerWorkload,

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\monitoring')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-SolutionRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}

function Read-JsonFile {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw "Required file not found: $Path"
    }

    return Get-Content -Path $Path -Raw -Encoding utf8 | ConvertFrom-Json -Depth 20
}

function Get-ResolvedConfiguration {
    param(
        [Parameter(Mandatory)]
        [string]$Tier,

        [string[]]$RequestedWorkloads
    )

    $solutionRoot = Get-SolutionRoot
    $defaultConfig = Read-JsonFile -Path (Join-Path $solutionRoot 'config\default-config.json')
    $tierConfig = Read-JsonFile -Path (Join-Path $solutionRoot ("config\{0}.json" -f $Tier))

    $resolvedWorkloads = if ($RequestedWorkloads -and $RequestedWorkloads.Count -gt 0) {
        @($RequestedWorkloads | Select-Object -Unique)
    }
    else {
        @($tierConfig.workloadsToAudit)
    }

    return [pscustomobject]@{
        solution = $defaultConfig.solution
        solutionCode = $defaultConfig.solutionCode
        displayName = $defaultConfig.displayName
        version = $defaultConfig.version
        tier = $tierConfig.tier
        controls = @($defaultConfig.controls)
        workloadsToAudit = $resolvedWorkloads
        labelTaxonomy = @($defaultConfig.labelTaxonomy)
        prioritySites = @($defaultConfig.prioritySites)
        remediationManifestMaxItems = [int]$defaultConfig.remediationManifestMaxItems
        graphApiVersion = $defaultConfig.graphApiVersion
        sensitivityLabelDefinitionsApiVersion = $defaultConfig.sensitivityLabelDefinitionsApiVersion
        coverageThreshold = $defaultConfig.coverageThreshold
        tierSettings = $tierConfig
    }
}

function New-LabelTierDistribution {
    param(
        [Parameter(Mandatory)]
        [int]$LabeledCount,

        [Parameter(Mandatory)]
        [object[]]$Taxonomy
    )

    $ratios = @(0.08, 0.34, 0.30, 0.20, 0.08)
    if ($Taxonomy.Count -ne $ratios.Count) {
        throw "Label tier distribution requires exactly $($ratios.Count) taxonomy tiers but received $($Taxonomy.Count)."
    }
    $remaining = $LabeledCount
    $distribution = @()

    for ($index = 0; $index -lt $Taxonomy.Count; $index++) {
        $count = if ($index -eq ($Taxonomy.Count - 1)) {
            $remaining
        }
        else {
            [int][math]::Round($LabeledCount * $ratios[$index], 0)
        }

        if ($count -gt $remaining) {
            $count = $remaining
        }

        $remaining -= $count
        $tierDefinition = $Taxonomy[$index]
        $distribution += [pscustomobject]@{
            tier = [int]$tierDefinition.tier
            name = [string]$tierDefinition.name
            count = [int]$count
        }
    }

    return $distribution
}

function Get-SuggestedLabel {
    param(
        [Parameter(Mandatory)]
        [int]$RiskScore,

        [Parameter(Mandatory)]
        [object[]]$Taxonomy
    )

    $targetTier = if ($RiskScore -ge 5) {
        5
    }
    elseif ($RiskScore -ge 4) {
        4
    }
    elseif ($RiskScore -ge 3) {
        3
    }
    else {
        2
    }

    $match = $Taxonomy | Where-Object { [int]$_.tier -eq $targetTier } | Select-Object -First 1
    return [string]$match.name
}

function Get-ContainerTemplates {
    param(
        [Parameter(Mandatory)]
        [string]$Workload
    )

    switch ($Workload) {
        'sharePoint' {
            return @(
                [pscustomobject]@{ containerId = 'https://contoso.sharepoint.com/sites/finance-records'; displayName = 'Finance Records'; riskScore = 5 },
                [pscustomobject]@{ containerId = 'https://contoso.sharepoint.com/sites/regulatory-reporting'; displayName = 'Regulatory Reporting'; riskScore = 5 },
                [pscustomobject]@{ containerId = 'https://contoso.sharepoint.com/sites/retail-banking'; displayName = 'Retail Banking'; riskScore = 4 }
            )
        }
        'oneDrive' {
            return @(
                [pscustomobject]@{ containerId = 'advisor01@contoso.com'; displayName = 'Advisor 01 OneDrive'; riskScore = 4 },
                [pscustomobject]@{ containerId = 'compliance01@contoso.com'; displayName = 'Compliance 01 OneDrive'; riskScore = 5 },
                [pscustomobject]@{ containerId = 'ops01@contoso.com'; displayName = 'Operations 01 OneDrive'; riskScore = 3 }
            )
        }
        'exchange' {
            return @(
                [pscustomobject]@{ containerId = 'tradingdesk@contoso.com'; displayName = 'Trading Desk Mailbox'; riskScore = 5 },
                [pscustomobject]@{ containerId = 'compliancearchive@contoso.com'; displayName = 'Compliance Archive'; riskScore = 5 },
                [pscustomobject]@{ containerId = 'retailadvisory@contoso.com'; displayName = 'Retail Advisory'; riskScore = 4 }
            )
        }
        default {
            throw "Unsupported workload: $Workload"
        }
    }
}

function New-GapCandidates {
    param(
        [Parameter(Mandatory)]
        [string]$Workload,

        [Parameter(Mandatory)]
        [int]$TotalItems,

        [Parameter(Mandatory)]
        [int]$UnlabeledCount,

        [Parameter(Mandatory)]
        [object[]]$Taxonomy
    )

    $templates = Get-ContainerTemplates -Workload $Workload
    $weightTotal = ($templates | Measure-Object -Property riskScore -Sum).Sum
    $itemsPerTemplate = [int][math]::Max(1, [math]::Round($TotalItems / $templates.Count, 0))
    $remainingItems = $TotalItems
    $remainingUnlabeled = $UnlabeledCount
    $candidates = @()

    for ($index = 0; $index -lt $templates.Count; $index++) {
        $template = $templates[$index]
        $isLast = $index -eq ($templates.Count - 1)

        $containerItemCount = if ($isLast) {
            $remainingItems
        }
        else {
            $itemsPerTemplate
        }

        $containerUnlabeled = if ($isLast) {
            $remainingUnlabeled
        }
        else {
            [int][math]::Round($UnlabeledCount * ($template.riskScore / $weightTotal), 0)
        }

        if ($containerUnlabeled -gt $remainingUnlabeled) {
            $containerUnlabeled = $remainingUnlabeled
        }

        $remainingItems -= $containerItemCount
        $remainingUnlabeled -= $containerUnlabeled

        $unlabeledPercent = if ($containerItemCount -gt 0) {
            [math]::Round(($containerUnlabeled / $containerItemCount) * 100, 2)
        }
        else {
            0
        }

        $candidates += [pscustomobject]@{
            workload = $Workload
            containerId = $template.containerId
            displayName = $template.displayName
            itemCount = [int]$containerItemCount
            unlabeledCount = [int]$containerUnlabeled
            unlabeledPercent = $unlabeledPercent
            riskScore = [int]$template.riskScore
            suggestedLabel = Get-SuggestedLabel -RiskScore $template.riskScore -Taxonomy $Taxonomy
        }
    }

    return $candidates
}

function New-WorkloadCoverageResult {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration,

        [Parameter(Mandatory)]
        [string]$Workload,

        [Parameter(Mandatory)]
        [int]$BaseTotalItems,

        [Parameter(Mandatory)]
        [double]$BaseCoveragePercent,

        [Parameter(Mandatory)]
        [int]$ItemLimit,

        [Parameter(Mandatory)]
        [string[]]$SourceEndpoints,

        [Parameter(Mandatory)]
        [string]$CoverageNotes
    )

    $totalItems = if ($ItemLimit -lt 0) {
        $BaseTotalItems
    }
    else {
        [int][math]::Min($BaseTotalItems, $ItemLimit)
    }

    $coveragePercent = [math]::Round($BaseCoveragePercent, 2)
    $labeledCount = [int][math]::Round($totalItems * ($coveragePercent / 100), 0)
    $unlabeledCount = [int][math]::Max(0, $totalItems - $labeledCount)
    $distribution = New-LabelTierDistribution -LabeledCount $labeledCount -Taxonomy $Configuration.labelTaxonomy
    $gapCandidates = New-GapCandidates -Workload $Workload -TotalItems $totalItems -UnlabeledCount $unlabeledCount -Taxonomy $Configuration.labelTaxonomy

    return [pscustomobject]@{
        workload = $Workload
        totalItems = [int]$totalItems
        labeledCount = [int]$labeledCount
        unlabeledCount = [int]$unlabeledCount
        coveragePercent = $coveragePercent
        distributionByLabelTier = $distribution
        gapCandidates = $gapCandidates
        sourceEndpoints = $SourceEndpoints
        coverageNotes = $CoverageNotes
    }
}

function Get-SharePointLabelCoverage {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration,

        [Parameter(Mandatory)]
        [int]$MaxItemsPerWorkload
    )

    return New-WorkloadCoverageResult -Configuration $Configuration -Workload 'sharePoint' -BaseTotalItems 40000 -BaseCoveragePercent 86.5 -ItemLimit $MaxItemsPerWorkload -SourceEndpoints @('/sites/{site-id}/drives', '/drives/{drive-id}/items/{item-id}/extractSensitivityLabels', '/beta/security/informationProtection/sensitivityLabels') -CoverageNotes 'SharePoint coverage uses driveItem extractSensitivityLabels results for supported files and beta label definitions for tier mapping.'
}

function Get-OneDriveLabelCoverage {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration,

        [Parameter(Mandatory)]
        [int]$MaxItemsPerWorkload
    )

    return New-WorkloadCoverageResult -Configuration $Configuration -Workload 'oneDrive' -BaseTotalItems 25000 -BaseCoveragePercent 82.2 -ItemLimit $MaxItemsPerWorkload -SourceEndpoints @('/users/{user-id}/drive', '/drives/{drive-id}/items/{item-id}/extractSensitivityLabels', '/beta/security/informationProtection/sensitivityLabels') -CoverageNotes 'OneDrive coverage uses driveItem extractSensitivityLabels results for supported files and highlights business-user stores that may contain customer or supervisory data outside shared repositories.'
}

function Get-ExchangeLabelCoverage {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration,

        [Parameter(Mandatory)]
        [int]$MaxItemsPerWorkload
    )

    return New-WorkloadCoverageResult -Configuration $Configuration -Workload 'exchange' -BaseTotalItems 60000 -BaseCoveragePercent 79.8 -ItemLimit $MaxItemsPerWorkload -SourceEndpoints @('tenant-approved Purview audit/activity export', '/users/{user-id}/messages?$expand=singleValueExtendedProperties', '/beta/security/informationProtection/sensitivityLabels') -CoverageNotes 'Exchange coverage must come from a tenant-approved Purview audit/activity export, documented Internet message headers, or documented extended-property extraction because Graph messages do not expose a first-class sensitivity-label field.'
}

function Measure-LabelCoverage {
    param(
        [Parameter(Mandatory)]
        [object[]]$WorkloadCoverage
    )

    $totalItems = ($WorkloadCoverage | Measure-Object -Property totalItems -Sum).Sum
    $labeledCount = ($WorkloadCoverage | Measure-Object -Property labeledCount -Sum).Sum
    $unlabeledCount = ($WorkloadCoverage | Measure-Object -Property unlabeledCount -Sum).Sum
    $coveragePercent = if ($totalItems -gt 0) {
        [math]::Round(($labeledCount / $totalItems) * 100, 2)
    }
    else {
        0
    }

    $tierDistributionMap = @{}
    foreach ($workload in $WorkloadCoverage) {
        foreach ($entry in @($workload.distributionByLabelTier)) {
            $key = [string]$entry.tier
            if (-not $tierDistributionMap.ContainsKey($key)) {
                $tierDistributionMap[$key] = [ordered]@{
                    tier = [int]$entry.tier
                    name = [string]$entry.name
                    count = 0
                }
            }

            $tierDistributionMap[$key].count += [int]$entry.count
        }
    }

    $distribution = @(
        $tierDistributionMap.Values |
            Sort-Object -Property tier |
            ForEach-Object {
                [pscustomobject]@{
                    tier = $_.tier
                    name = $_.name
                    count = $_.count
                }
            }
    )

    return [pscustomobject]@{
        totalItems = [int]$totalItems
        labeledCount = [int]$labeledCount
        unlabeledCount = [int]$unlabeledCount
        coveragePercent = $coveragePercent
        distributionByLabelTier = $distribution
    }
}

function Get-OversharingRiskContext {
    $solutionRoot = Get-SolutionRoot
    $artifactRoot = Join-Path $solutionRoot '..\02-oversharing-risk-assessment\artifacts'

    if (-not (Test-Path -Path $artifactRoot)) {
        return [pscustomobject]@{
            status = 'not-found'
            sourceFile = $null
            highRiskContainers = @()
            notes = 'Prior oversharing risk output was not found. Coverage findings will use local risk scoring only.'
        }
    }

    $candidateFiles = Get-ChildItem -Path $artifactRoot -Recurse -File -Filter '*.json' -ErrorAction SilentlyContinue | Sort-Object -Property LastWriteTime -Descending
    foreach ($file in $candidateFiles) {
        try {
            $content = Get-Content -Path $file.FullName -Raw -Encoding utf8 | ConvertFrom-Json -Depth 20
        }
        catch {
            continue
        }

        $highRiskContainers = New-Object System.Collections.Generic.List[string]
        foreach ($propertyName in @('highRiskContainers', 'prioritySites', 'containers', 'findings')) {
            if ($content.PSObject.Properties.Name -notcontains $propertyName) {
                continue
            }

            foreach ($entry in @($content.$propertyName)) {
                if ($entry -is [string]) {
                    [void]$highRiskContainers.Add($entry)
                    continue
                }

                if ($entry -and $entry.PSObject.Properties.Name -contains 'containerId') {
                    [void]$highRiskContainers.Add([string]$entry.containerId)
                }
                elseif ($entry -and $entry.PSObject.Properties.Name -contains 'siteUrl') {
                    [void]$highRiskContainers.Add([string]$entry.siteUrl)
                }
                elseif ($entry -and $entry.PSObject.Properties.Name -contains 'mailbox') {
                    [void]$highRiskContainers.Add([string]$entry.mailbox)
                }
            }
        }

        return [pscustomobject]@{
            status = 'detected'
            sourceFile = $file.FullName
            highRiskContainers = @($highRiskContainers | Where-Object { $_ } | Select-Object -Unique)
            notes = 'Latest solution 02 output was discovered and used to elevate matching containers where identifiers were present.'
        }
    }

    return [pscustomobject]@{
        status = 'not-found'
        sourceFile = $null
        highRiskContainers = @()
        notes = 'No readable oversharing risk artifact was found.'
    }
}

function New-GapFindings {
    param(
        [Parameter(Mandatory)]
        [object[]]$WorkloadCoverage,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$PrioritySites,

        [Parameter(Mandatory)]
        [pscustomobject]$OversharingContext
    )

    $oversharingContainers = @($OversharingContext.highRiskContainers)
    $findings = foreach ($workload in $WorkloadCoverage) {
        foreach ($candidate in @($workload.gapCandidates)) {
            $isPrioritySite = @($PrioritySites) -contains $candidate.containerId
            $isOversharingMatch = @($oversharingContainers) -contains $candidate.containerId
            $priorityScore = [math]::Round($candidate.riskScore * $candidate.unlabeledPercent, 2)

            $priority = if ($isPrioritySite -or $isOversharingMatch) {
                'HIGH'
            }
            elseif ($priorityScore -ge 120) {
                'HIGH'
            }
            elseif ($priorityScore -ge 70) {
                'MEDIUM'
            }
            else {
                'LOW'
            }

            [pscustomobject]@{
                workload = $candidate.workload
                containerId = $candidate.containerId
                displayName = $candidate.displayName
                itemCount = $candidate.itemCount
                unlabeledCount = $candidate.unlabeledCount
                unlabeledPercent = $candidate.unlabeledPercent
                riskScore = $candidate.riskScore
                remediationPriorityScore = $priorityScore
                priority = $priority
                suggestedLabel = $candidate.suggestedLabel
                oversharingCrossReference = $isOversharingMatch
                notes = if ($isPrioritySite) {
                    'Priority site override applied because the container is configured for elevated monitoring.'
                }
                elseif ($isOversharingMatch) {
                    'Priority elevated by solution 02 oversharing findings.'
                }
                else {
                    'Priority derived from risk score multiplied by unlabeled percent.'
                }
            }
        }
    }

    return @(
        $findings | Sort-Object -Property @{ Expression = 'remediationPriorityScore'; Descending = $true }, @{ Expression = 'unlabeledCount'; Descending = $true }
    )
}

function New-RemediationManifest {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$GapFindings,

        [Parameter(Mandatory)]
        [pscustomobject]$Configuration
    )

    $maxItems = if ($Configuration.remediationManifestMaxItems -gt 0) {
        $Configuration.remediationManifestMaxItems
    }
    else {
        $GapFindings.Count
    }

    $sequence = 0
    $selectedItems = @($GapFindings | Select-Object -First $maxItems)

    return @(
        $selectedItems | ForEach-Object {
            $sequence++
            [pscustomobject]@{
                manifestItemId = 'RM-{0:D4}' -f $sequence
                workload = $_.workload
                containerId = $_.containerId
                displayName = $_.displayName
                priority = $_.priority
                remediationPriorityScore = $_.remediationPriorityScore
                suggestedLabel = $_.suggestedLabel
                recommendedAction = 'Review with the data owner, confirm business context, then schedule bulk labeling or policy remediation.'
                notes = $_.notes
            }
        }
    )
}

$scanStartedAt = Get-Date
$configuration = Get-ResolvedConfiguration -Tier $ConfigurationTier -RequestedWorkloads $WorkloadsToAudit
$effectiveMaxItems = if ($PSBoundParameters.ContainsKey('MaxItemsPerWorkload')) {
    $MaxItemsPerWorkload
}
else {
    [int]$configuration.tierSettings.maxItemsPerScan
}

$oversharingContext = Get-OversharingRiskContext
$workloadResults = @()

foreach ($workload in $configuration.workloadsToAudit) {
    switch ($workload) {
        'sharePoint' {
            $workloadResults += Get-SharePointLabelCoverage -Configuration $configuration -MaxItemsPerWorkload $effectiveMaxItems
        }
        'oneDrive' {
            $workloadResults += Get-OneDriveLabelCoverage -Configuration $configuration -MaxItemsPerWorkload $effectiveMaxItems
        }
        'exchange' {
            $workloadResults += Get-ExchangeLabelCoverage -Configuration $configuration -MaxItemsPerWorkload $effectiveMaxItems
        }
        default {
            throw "Unsupported workload: $workload"
        }
    }
}

$overallCoverage = Measure-LabelCoverage -WorkloadCoverage $workloadResults
$gapFindings = New-GapFindings -WorkloadCoverage $workloadResults -PrioritySites @($configuration.prioritySites) -OversharingContext $oversharingContext
$remediationManifest = if ([bool]$configuration.tierSettings.generateRemediationManifest) {
    New-RemediationManifest -GapFindings $gapFindings -Configuration $configuration
}
else {
    @()
}

$thresholdStatus = if ($overallCoverage.coveragePercent -lt [double]$configuration.tierSettings.alertOnCoverageBelow) {
    'below-threshold'
}
else {
    'within-threshold'
}

$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$null = New-Item -Path $resolvedOutputPath -ItemType Directory -Force
$coverageReportPath = Join-Path $resolvedOutputPath 'monitor-label-coverage-report.json'
$gapFindingsPath = Join-Path $resolvedOutputPath 'monitor-label-gap-findings.json'
$remediationManifestPath = Join-Path $resolvedOutputPath 'monitor-remediation-manifest.json'

$coverageReportObj = [pscustomobject]@{
    metadata = [pscustomobject]@{
        solution = $configuration.solution
        solutionCode = $configuration.solutionCode
        tenantId = $TenantId
        tier = $configuration.tier
        graphApiVersion = $configuration.graphApiVersion
        sensitivityLabelDefinitionsApiVersion = $configuration.sensitivityLabelDefinitionsApiVersion
        generatedAt = (Get-Date).ToString('s')
    }
    overall = $overallCoverage
    workloads = $workloadResults
    thresholdStatus = $thresholdStatus
    oversharingContext = $oversharingContext
}

if ($PSCmdlet.ShouldProcess($coverageReportPath, 'Write monitoring artifact')) {
    $coverageReportObj | ConvertTo-Json -Depth 20 | Set-Content -Path $coverageReportPath -Encoding utf8
}

$gapFindingsObj = [pscustomobject]@{
    metadata = [pscustomobject]@{
        solution = $configuration.solution
        tenantId = $TenantId
        tier = $configuration.tier
        generatedAt = (Get-Date).ToString('s')
    }
    findings = $gapFindings
}

if ($PSCmdlet.ShouldProcess($gapFindingsPath, 'Write monitoring artifact')) {
    $gapFindingsObj | ConvertTo-Json -Depth 20 | Set-Content -Path $gapFindingsPath -Encoding utf8
}

$remediationManifestObj = [pscustomobject]@{
    metadata = [pscustomobject]@{
        solution = $configuration.solution
        tenantId = $TenantId
        tier = $configuration.tier
        generatedAt = (Get-Date).ToString('s')
    }
    items = $remediationManifest
}

if ($PSCmdlet.ShouldProcess($remediationManifestPath, 'Write monitoring artifact')) {
    $remediationManifestObj | ConvertTo-Json -Depth 20 | Set-Content -Path $remediationManifestPath -Encoding utf8
}

[pscustomobject]@{
    solution = $configuration.displayName
    solutionCode = $configuration.solutionCode
    tenantId = $TenantId
    tier = $configuration.tier
    scanStartedAt = $scanStartedAt.ToString('s')
    scanCompletedAt = (Get-Date).ToString('s')
    workloads = $workloadResults
    overall = $overallCoverage
    overallScore = $overallCoverage.coveragePercent
    thresholdStatus = $thresholdStatus
    oversharingContext = $oversharingContext
    gapFindings = $gapFindings
    remediationManifest = $remediationManifest
    artifactPaths = [pscustomobject]@{
        coverageReport = $coverageReportPath
        gapFindings = $gapFindingsPath
        remediationManifest = $remediationManifestPath
    }
}
