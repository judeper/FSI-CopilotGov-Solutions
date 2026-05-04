<#
.SYNOPSIS
Produces a monitoring snapshot for the License Governance and ROI Tracker solution.

.DESCRIPTION
Loads the selected governance tier, simulates Microsoft Graph Copilot usage report data,
identifies inactive seats, calculates license-utilization metrics, and writes a structured
status object for operational review. The output is designed to support compliance-focused
license reviews and reallocation workflows in financial-services environments.

.PARAMETER ConfigurationTier
Governance tier to monitor. Valid values are baseline, recommended, and regulated.

.PARAMETER InactivityThresholdDays
Number of days without activity that should classify a seat as inactive. If omitted, the tier
configuration value is used.

.PARAMETER OutputPath
Directory where the monitoring status JSON file will be written.

.EXAMPLE
PS> .\Monitor-Compliance.ps1 -ConfigurationTier baseline -OutputPath '.\artifacts\monitor'
Writes a baseline-tier compliance snapshot and returns the structured status object.

.EXAMPLE
PS> .\Monitor-Compliance.ps1 -ConfigurationTier regulated -InactivityThresholdDays 14 -OutputPath '.\artifacts\regulated'
Runs a regulated-tier monitoring snapshot with an explicit inactivity threshold.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [int]$InactivityThresholdDays = 30,

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force

. (Join-Path $PSScriptRoot 'SolutionConfig.ps1')

function Get-CopilotUsageReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration
    )

    return @(
        [pscustomobject]@{ userPrincipalName = 'alex.morgan@contoso.com'; department = 'Treasury'; assignedSku = 'Microsoft 365 Copilot'; lastActivityDate = (Get-Date).AddDays(-3).ToString('yyyy-MM-dd'); accountEnabled = $true; vivaImpactScore = 0.82; riskTier = 'medium' }
        [pscustomobject]@{ userPrincipalName = 'jamie.lee@contoso.com'; department = 'Retail Banking'; assignedSku = 'Microsoft 365 Copilot'; lastActivityDate = (Get-Date).AddDays(-9).ToString('yyyy-MM-dd'); accountEnabled = $true; vivaImpactScore = 0.67; riskTier = 'low' }
        [pscustomobject]@{ userPrincipalName = 'pat.owens@contoso.com'; department = 'Finance'; assignedSku = 'Microsoft 365 Copilot'; lastActivityDate = (Get-Date).AddDays(-31).ToString('yyyy-MM-dd'); accountEnabled = $true; vivaImpactScore = 0.19; riskTier = 'medium' }
        [pscustomobject]@{ userPrincipalName = 'chris.evans@contoso.com'; department = 'Internal Audit'; assignedSku = 'Microsoft 365 Copilot'; lastActivityDate = (Get-Date).AddDays(-45).ToString('yyyy-MM-dd'); accountEnabled = $true; vivaImpactScore = 0.05; riskTier = 'high' }
        [pscustomobject]@{ userPrincipalName = 'dana.ross@contoso.com'; department = 'Operations'; assignedSku = 'Microsoft 365 Copilot'; lastActivityDate = (Get-Date).AddDays(-16).ToString('yyyy-MM-dd'); accountEnabled = $true; vivaImpactScore = 0.54; riskTier = 'medium' }
        [pscustomobject]@{ userPrincipalName = 'samir.patel@contoso.com'; department = 'Wealth Management'; assignedSku = 'Microsoft 365 Copilot'; lastActivityDate = (Get-Date).AddDays(-61).ToString('yyyy-MM-dd'); accountEnabled = $true; vivaImpactScore = 0.08; riskTier = 'low' }
    )
}

function Get-InactiveSeats {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$UsageReport,

        [Parameter(Mandatory)]
        [int]$ThresholdDays
    )

    $cutoffDate = (Get-Date).Date.AddDays(-$ThresholdDays)
    return @(
        $UsageReport | Where-Object {
            ([datetime]$_.lastActivityDate).Date -lt $cutoffDate
        }
    )
}

function Measure-LicenseUtilization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$UsageReport,

        [Parameter(Mandatory)]
        [object[]]$InactiveSeats,

        [Parameter(Mandatory)]
        [int]$ThresholdPct,

        [Parameter(Mandatory)]
        [int]$AnnualizedCostPerSeatUsd
    )

    $totalSeats = @($UsageReport).Count
    $activeSeats = $totalSeats - @($InactiveSeats).Count
    $enabledSeats = @($UsageReport | Where-Object { $_.accountEnabled }).Count

    $averageImpact = if ($totalSeats -gt 0) {
        [math]::Round((($UsageReport | Measure-Object -Property vivaImpactScore -Average).Average), 2)
    }
    else {
        0
    }

    $utilizationPct = if ($totalSeats -gt 0) {
        [math]::Round(($activeSeats / $totalSeats) * 100, 2)
    }
    else {
        0
    }

    return [pscustomobject]@{
        totalSeats = $totalSeats
        activeSeats = $activeSeats
        enabledSeats = $enabledSeats
        inactiveSeats = @($InactiveSeats).Count
        utilizationRatePct = $utilizationPct
        reallocationTriggerUtilizationPct = $ThresholdPct
        atOrAboveThreshold = ($utilizationPct -ge $ThresholdPct)
        averageVivaImpactScore = $averageImpact
        estimatedRecoverableCostUsd = (@($InactiveSeats).Count * $AnnualizedCostPerSeatUsd)
    }
}

try {
    $configuration = Get-SolutionConfiguration -Tier $ConfigurationTier
    $effectiveThreshold = if ($PSBoundParameters.ContainsKey('InactivityThresholdDays')) {
        $InactivityThresholdDays
    }
    else {
        [int]$configuration.inactivityThresholdDays
    }

    $usageReport = @(Get-CopilotUsageReport -Configuration $configuration)
    $inactiveSeats = @(Get-InactiveSeats -UsageReport $usageReport -ThresholdDays $effectiveThreshold)
    $metrics = Measure-LicenseUtilization -UsageReport $usageReport -InactiveSeats $inactiveSeats -ThresholdPct ([int]$configuration.reallocationTriggerUtilizationPct) -AnnualizedCostPerSeatUsd ([int]$configuration.defaults.annualizedCostPerSeatUsd)

    $flaggedSeats = foreach ($seat in $inactiveSeats) {
        [pscustomobject]@{
            userPrincipalName = $seat.userPrincipalName
            department = $seat.department
            riskTier = $seat.riskTier
            lastActivityDate = $seat.lastActivityDate
            accountEnabled = $seat.accountEnabled
            recommendedAction = if ($seat.riskTier -eq 'high') { 'Retain pending control-owner review' } else { 'Reallocate after manager approval' }
            annualizedRecoverableCostUsd = [int]$configuration.defaults.annualizedCostPerSeatUsd
        }
    }

    $statusValue = if (@($flaggedSeats).Count -eq 0 -and $metrics.atOrAboveThreshold) {
        'implemented'
    }
    elseif (@($flaggedSeats).Count -gt 0) {
        'partial'
    }
    elseif (-not $configuration.vivaInsightsEnabled) {
        'monitor-only'
    }
    else {
        'implemented'
    }

    $statusObject = [pscustomobject][ordered]@{
        solution = '08-license-governance-roi'
        solutionCode = 'LGR'
        displayName = 'License Governance and ROI Tracker'
        assessedAt = (Get-Date).ToString('o')
        configurationTier = $ConfigurationTier
        inactivityThresholdDays = $effectiveThreshold
        status = $statusValue
        statusScore = Get-CopilotGovStatusScore -Status $statusValue
        controls = @('1.9', '4.5', '4.6', '4.8')
        graphEndpoints = @(
            '/v1.0/users?$select=id,displayName,userPrincipalName,department,assignedLicenses,accountEnabled'
            '/v1.0/subscribedSkus'
            "/v1.0/copilot/reports/getMicrosoft365CopilotUsageUserDetail(period='D30')"
        )
        metrics = $metrics
        inactiveSeats = $flaggedSeats
        recommendations = @(
            'Review inactive seats with business owners before license removal.'
            'Exclude protected users provided by solution 11-risk-tiered-rollout from automatic reallocation.'
            'Re-baseline the Power BI scorecard once approved actions are completed.'
        )
    }

    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $resolvedOutputPath = (Resolve-Path $OutputPath).Path
    $statusPath = Join-Path $resolvedOutputPath '08-license-governance-roi-compliance-status.json'
    $statusObject | ConvertTo-Json -Depth 8 | Set-Content -Path $statusPath -Encoding utf8
    $statusObject | Add-Member -NotePropertyName outputPath -NotePropertyValue $statusPath -Force

    Write-Output $statusObject
}
catch {
    $message = "Compliance monitoring failed for 08-license-governance-roi: {0}" -f $_.Exception.Message
    Write-Error $message
    throw
}
