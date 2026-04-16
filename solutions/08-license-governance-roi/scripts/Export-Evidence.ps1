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
        dataSources = if ($configuration.vivaInsightsEnabled) { @('Microsoft Graph', 'Viva Insights') } else { @('Microsoft Graph', 'Management review inputs') }
    }

    $roiScorecard = [ordered]@{
        reportingPeriodDays = $configuration.reportingPeriodDays
        vivaInsightsEnabled = $configuration.vivaInsightsEnabled
        roiSignalCoveragePct = if ($configuration.vivaInsightsEnabled) { 78.5 } else { 42.0 }
        estimatedHoursSaved = if ($configuration.vivaInsightsEnabled) { 326.5 } else { 184.0 }
        estimatedCostAvoidanceUsd = if ($configuration.vivaInsightsEnabled) { 57100 } else { 24800 }
        businessUnitScorecard = @(
            [ordered]@{ businessUnit = 'Retail Banking'; estimatedHoursSaved = 112.0; managerValidatedUseCases = 4; vivaImpactScore = 0.81 }
            [ordered]@{ businessUnit = 'Treasury'; estimatedHoursSaved = 79.5; managerValidatedUseCases = 3; vivaImpactScore = 0.76 }
            [ordered]@{ businessUnit = 'Operations'; estimatedHoursSaved = 68.0; managerValidatedUseCases = 2; vivaImpactScore = 0.63 }
        )
        assumptions = @(
            'Estimated value is directional and intended for governance review, not external financial reporting.'
            'Protected users from solution 11-risk-tiered-rollout are excluded from automatic seat-recovery assumptions.'
        )
    }

    $annualizedCost = [int]$configuration.defaults.annualizedCostPerSeatUsd

    $reallocationRecommendations = @(
        [pscustomobject]@{ userPrincipalName = 'pat.owens@contoso.com'; department = 'Finance'; riskTier = 'medium'; lastActivityDate = $periodEnd.AddDays(-31).ToString('yyyy-MM-dd'); utilizationPct = 18.0; recommendedAction = 'Reallocate after manager approval'; annualizedRecoverableCostUsd = $annualizedCost; managerApprovalRequired = $true; reviewDueDate = $periodEnd.AddDays(7).ToString('yyyy-MM-dd') }
        [pscustomobject]@{ userPrincipalName = 'chris.evans@contoso.com'; department = 'Internal Audit'; riskTier = 'high'; lastActivityDate = $periodEnd.AddDays(-45).ToString('yyyy-MM-dd'); utilizationPct = 5.0; recommendedAction = 'Hold for control-owner exception review'; annualizedRecoverableCostUsd = $annualizedCost; managerApprovalRequired = $true; reviewDueDate = $periodEnd.AddDays(7).ToString('yyyy-MM-dd') }
        [pscustomobject]@{ userPrincipalName = 'samir.patel@contoso.com'; department = 'Wealth Management'; riskTier = 'low'; lastActivityDate = $periodEnd.AddDays(-61).ToString('yyyy-MM-dd'); utilizationPct = 8.0; recommendedAction = 'Reallocate after manager approval'; annualizedRecoverableCostUsd = $annualizedCost; managerApprovalRequired = $true; reviewDueDate = $periodEnd.AddDays(7).ToString('yyyy-MM-dd') }
    )

    $artifacts = @(
        (New-ArtifactFile -BaseName 'license-utilization-report' -Type 'json' -Content $licenseUtilizationReport -OutputDirectory $resolvedOutputPath -Description 'Summarizes seat allocation, inactivity, and utilization by business unit.')
        (New-ArtifactFile -BaseName 'roi-scorecard' -Type 'json' -Content $roiScorecard -OutputDirectory $resolvedOutputPath -Description 'Summarizes ROI signals from Viva Insights and management-reviewed adoption metrics.')
        (New-ArtifactFile -BaseName 'reallocation-recommendations' -Type 'csv' -Content $reallocationRecommendations -OutputDirectory $resolvedOutputPath -Description 'Lists low-utilization seats and recommended actions for approval-based reallocation.')
    )

    $controls = @(
        [pscustomobject]@{
            controlId = '1.9'
            status = 'implemented'
            notes = 'Tier configuration defines inactivity thresholds, approval routing, and SKU scope for periodic seat-assignment review.'
        }
        [pscustomobject]@{
            controlId = '4.5'
            status = 'implemented'
            notes = 'License-utilization reporting documents active versus inactive seats, utilization trends, and business-unit segmentation.'
        }
        [pscustomobject]@{
            controlId = '4.6'
            status = if ($configuration.vivaInsightsEnabled) { 'implemented' } else { 'monitor-only' }
            notes = if ($configuration.vivaInsightsEnabled) {
                'ROI scorecard includes Viva Insights enrichment and management-reviewed value assumptions.'
            }
            else {
                'ROI scorecard is limited to Microsoft 365 usage signals until Viva Insights enrichment is enabled for the selected tier.'
            }
        }
        [pscustomobject]@{
            controlId = '4.8'
            status = 'implemented'
            notes = 'Reallocation recommendations quantify recoverable spend and direct protected users to exception review before seat removal.'
        }
    )

    $findingCount = @($reallocationRecommendations | Where-Object { $_.recommendedAction -like 'Reallocate*' }).Count
    $exceptionCount = @($reallocationRecommendations | Where-Object { $_.managerApprovalRequired }).Count
    $overallStatus = Get-OverallStatus -Controls $controls

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
        -Artifacts $artifacts

    [pscustomobject]@{
        solution = '08-license-governance-roi'
        solutionCode = 'LGR'
        configurationTier = $ConfigurationTier
        overallStatus = $overallStatus
        evidencePackage = $package
        controls = $controls
        artifacts = $artifacts
    }
}
catch {
    $message = "Evidence export failed for 08-license-governance-roi: {0}" -f $_.Exception.Message
    Write-Error $message
    throw
}
