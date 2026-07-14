<#
.SYNOPSIS
Exports an evidence package for the License Governance and ROI Tracker solution.

.DESCRIPTION
Builds solution-specific evidence artifacts for license utilization, ROI scorecards, and
reallocation recommendations, then packages those artifacts into the shared evidence schema
with a companion SHA-256 file. The export is designed to support recurring financial-services
governance reviews and control evidence collection.

.PARAMETER ConfigurationTier
Governance tier to export. Valid values are baseline, recommended, and regulated.

.PARAMETER OutputPath
Directory where the evidence package and supporting artifacts will be written.

.EXAMPLE
PS> .\Export-Evidence.ps1 -ConfigurationTier baseline -OutputPath '.\artifacts\evidence'
Creates a baseline-tier evidence package and supporting artifact files.

.EXAMPLE
PS> .\Export-Evidence.ps1 -ConfigurationTier regulated -OutputPath '.\artifacts\regulated'
Creates a regulated-tier evidence package with strict review assumptions.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

. (Join-Path $PSScriptRoot 'SolutionConfig.ps1')

function New-ArtifactFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BaseName,

        [Parameter(Mandatory)]
        [ValidateSet('json', 'csv', 'txt')]
        [string]$Type,

        [Parameter(Mandatory)]
        [object]$Content,

        [Parameter(Mandatory)]
        [string]$OutputDirectory,

        [Parameter(Mandatory)]
        [string]$Description
    )

    $extension = ".{0}" -f $Type
    $artifactPath = Join-Path $OutputDirectory ($BaseName + $extension)

    switch ($Type) {
        'json' {
            $Content | ConvertTo-Json -Depth 8 | Set-Content -Path $artifactPath -Encoding utf8
        }
        'csv' {
            $Content | Export-Csv -Path $artifactPath -NoTypeInformation -Encoding utf8
        }
        default {
            Set-Content -Path $artifactPath -Value ([string]$Content) -Encoding utf8
        }
    }

    $hashInfo = Write-CopilotGovSha256File -Path $artifactPath

    return [pscustomobject]@{
        name = $BaseName
        type = $Type
        path = $artifactPath
        packagePath = [IO.Path]::GetFileName($artifactPath)
        hash = $hashInfo.Hash
        description = $Description
    }
}

function Get-OverallStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Controls
    )

    if ($Controls.status -contains 'partial' -or $Controls.status -contains 'monitor-only') {
        return 'partial'
    }

    return 'implemented'
}

try {
    $configuration = Get-SolutionConfiguration -Tier $ConfigurationTier
    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $resolvedOutputPath = (Resolve-Path $OutputPath).Path

    $periodEnd = (Get-Date).Date
    $periodStart = $periodEnd.AddDays(-([int]$configuration.reportingPeriodDays))

    $licenseUtilizationReport = [ordered]@{
        reportingPeriodStart = $periodStart.ToString('yyyy-MM-dd')
        reportingPeriodEnd = $periodEnd.ToString('yyyy-MM-dd')
        skuName = 'Microsoft 365 Copilot'
        totalAssignedSeats = 60
        activeSeats = 41
        inactiveSeats = 19
        utilizationPct = 68.33
        reallocationTriggerUtilizationPct = $configuration.reallocationTriggerUtilizationPct
        businessUnitSummary = @(
            [ordered]@{ businessUnit = 'Retail Banking'; assignedSeats = 20; activeSeats = 16; inactiveSeats = 4; utilizationPct = 80.00 }
            [ordered]@{ businessUnit = 'Treasury'; assignedSeats = 12; activeSeats = 9; inactiveSeats = 3; utilizationPct = 75.00 }
            [ordered]@{ businessUnit = 'Finance'; assignedSeats = 10; activeSeats = 5; inactiveSeats = 5; utilizationPct = 50.00 }
            [ordered]@{ businessUnit = 'Internal Audit'; assignedSeats = 8; activeSeats = 4; inactiveSeats = 4; utilizationPct = 50.00 }
            [ordered]@{ businessUnit = 'Operations'; assignedSeats = 10; activeSeats = 7; inactiveSeats = 3; utilizationPct = 70.00 }
        )
        dataSources = if ($configuration.vivaInsightsEnabled) { @('Representative Microsoft Graph-shaped sample', 'Representative Viva Insights-shaped sample') } else { @('Representative Microsoft Graph-shaped sample', 'Representative management-review input') }
    }

    $roiScorecard = [ordered]@{
        reportingPeriodDays = $configuration.reportingPeriodDays
        vivaInsightsEnabled = $configuration.vivaInsightsEnabled
        roiSignalCoveragePct = if ($configuration.vivaInsightsEnabled) { 78.5 } else { 42.0 }
        estimatedHoursSaved = if ($configuration.vivaInsightsEnabled) { 326.5 } else { 184.0 }
        estimatedCostAvoidanceUsd = if ($configuration.vivaInsightsEnabled) { 57100 } else { 24800 }
        costBasis = 'illustrative-customer-provided-planning-assumption'
        businessUnitScorecard = @(
            [ordered]@{ businessUnit = 'Retail Banking'; estimatedHoursSaved = 112.0; managerValidatedUseCases = 4; vivaImpactScore = 0.81 }
            [ordered]@{ businessUnit = 'Treasury'; estimatedHoursSaved = 79.5; managerValidatedUseCases = 3; vivaImpactScore = 0.76 }
            [ordered]@{ businessUnit = 'Operations'; estimatedHoursSaved = 68.0; managerValidatedUseCases = 2; vivaImpactScore = 0.63 }
        )
        assumptions = @(
            'Estimated value is directional and intended for governance review, not external financial reporting.'
            'Dollar values use illustrative customer-provided planning assumptions and are not Microsoft prices or formal accounting values.'
            'Protected users from solution 11-risk-tiered-rollout are excluded from automatic seat-recovery assumptions.'
        )
    }

    $annualizedCost = [int]$configuration.defaults.annualizedCostPerSeatUsd

    $reallocationRecommendations = @(
        [pscustomobject]@{ userPrincipalName = 'pat.owens@contoso.com'; department = 'Finance'; riskTier = 'medium'; lastActivityDate = $periodEnd.AddDays(-31).ToString('yyyy-MM-dd'); utilizationPct = 18.0; recommendedAction = 'Reallocate after manager approval'; annualizedRecoverableCostUsd = $annualizedCost; costBasis = 'illustrative-customer-provided-planning-assumption'; managerApprovalRequired = $true; reviewDueDate = $periodEnd.AddDays(7).ToString('yyyy-MM-dd') }
        [pscustomobject]@{ userPrincipalName = 'chris.evans@contoso.com'; department = 'Internal Audit'; riskTier = 'high'; lastActivityDate = $periodEnd.AddDays(-45).ToString('yyyy-MM-dd'); utilizationPct = 5.0; recommendedAction = 'Hold for control-owner exception review'; annualizedRecoverableCostUsd = $annualizedCost; costBasis = 'illustrative-customer-provided-planning-assumption'; managerApprovalRequired = $true; reviewDueDate = $periodEnd.AddDays(7).ToString('yyyy-MM-dd') }
        [pscustomobject]@{ userPrincipalName = 'samir.patel@contoso.com'; department = 'Wealth Management'; riskTier = 'low'; lastActivityDate = $periodEnd.AddDays(-61).ToString('yyyy-MM-dd'); utilizationPct = 8.0; recommendedAction = 'Reallocate after manager approval'; annualizedRecoverableCostUsd = $annualizedCost; costBasis = 'illustrative-customer-provided-planning-assumption'; managerApprovalRequired = $true; reviewDueDate = $periodEnd.AddDays(7).ToString('yyyy-MM-dd') }
    )

    $resultArtifacts = @(
        (New-ArtifactFile -BaseName 'license-utilization-report' -Type 'json' -Content $licenseUtilizationReport -OutputDirectory $resolvedOutputPath -Description 'Summarizes seat allocation, inactivity, and utilization by business unit.')
        (New-ArtifactFile -BaseName 'roi-scorecard' -Type 'json' -Content $roiScorecard -OutputDirectory $resolvedOutputPath -Description 'Summarizes ROI signals from Viva Insights and management-reviewed adoption metrics.')
        (New-ArtifactFile -BaseName 'reallocation-recommendations' -Type 'csv' -Content $reallocationRecommendations -OutputDirectory $resolvedOutputPath -Description 'Lists low-utilization seats and recommended actions for approval-based reallocation.')
    )

    $controls = @(
        [pscustomobject]@{
            controlId = '1.9'
            status = 'partial'
            notes = 'Tier configuration and representative sample output document inactivity thresholds, approval routing, and SKU scope; live tenant evidence is required.'
        }
        [pscustomobject]@{
            controlId = '4.5'
            status = 'partial'
            notes = 'Representative sample reporting documents the intended active/inactive and business-unit evidence shape; live usage-report evidence is required.'
        }
        [pscustomobject]@{
            controlId = '4.6'
            status = if ($configuration.vivaInsightsEnabled) { 'partial' } else { 'monitor-only' }
            notes = if ($configuration.vivaInsightsEnabled) {
                'ROI scorecard includes Viva Insights enrichment and management-reviewed value assumptions.'
            }
            else {
                'ROI scorecard is limited to Microsoft 365 usage signals until Viva Insights enrichment is enabled for the selected tier.'
            }
        }
        [pscustomobject]@{
            controlId = '4.8'
            status = 'partial'
            notes = 'Sample recommendations demonstrate the review workflow using illustrative customer-provided cost assumptions; no live cost or seat action is performed.'
        }
    )

    $findingCount = @($reallocationRecommendations | Where-Object { $_.recommendedAction -like 'Reallocate*' }).Count
    $exceptionCount = @($reallocationRecommendations | Where-Object { $_.managerApprovalRequired }).Count
    $overallStatus = Get-OverallStatus -Controls $controls

    $packageArtifacts = @(
        foreach ($artifact in $resultArtifacts) {
            [pscustomobject]@{
                name = $artifact.name
                type = $artifact.type
                path = $artifact.packagePath
                hash = $artifact.hash
                description = $artifact.description
            }
        }
    )

    $package = Export-SolutionEvidencePackage `
        -Solution '08-license-governance-roi' `
        -SolutionCode 'LGR' `
        -Tier $ConfigurationTier `
        -OutputPath $resolvedOutputPath `
        -Summary @{
            overallStatus = $overallStatus
            recordCount = [int]$licenseUtilizationReport.totalAssignedSeats
            findingCount = $findingCount
            exceptionCount = $exceptionCount
        } `
        -Controls $controls `
        -Artifacts $packageArtifacts

    [pscustomobject]@{
        solution = '08-license-governance-roi'
        solutionCode = 'LGR'
        configurationTier = $ConfigurationTier
        overallStatus = $overallStatus
        evidencePackage = $package
        controls = $controls
        artifacts = $resultArtifacts
    }
}
catch {
    $message = "Evidence export failed for 08-license-governance-roi: {0}" -f $_.Exception.Message
    Write-Error $message
    throw
}
