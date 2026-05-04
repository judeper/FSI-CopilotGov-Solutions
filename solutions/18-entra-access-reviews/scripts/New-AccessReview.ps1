<#
.SYNOPSIS
Creates Microsoft Entra ID Access Reviews for group memberships associated with SharePoint access via Microsoft Graph.

.DESCRIPTION
Reads site risk scores from solution 02-oversharing-risk-assessment output (or accepts a
site list as input), creates access review definitions prioritized by risk tier (HIGH first,
then MEDIUM, then LOW), sets review scope to group direct or transitive members that grant SharePoint access, assigns
the mapped resource owner as reviewer with compliance officer fallback, and sets duration and recurrence
from the review schedule configuration.

Uses POST /identityGovernance/accessReviews/definitions to create review definitions.
Scripts use representative sample data and do not connect to live Microsoft 365 services.

.PARAMETER TenantId
Microsoft Entra ID tenant GUID.

.PARAMETER ClientId
Application (client) ID for app-only authentication.

.PARAMETER ClientSecret
Client secret for app-only authentication.

.PARAMETER UseMgGraph
When set, uses Connect-MgGraph for delegated authentication instead of client credentials.

.PARAMETER RiskScoreInputPath
Path to the risk-scored site output from solution 02-oversharing-risk-assessment.

.PARAMETER ConfigPath
Path to the review schedule configuration file. Defaults to config\review-schedule.json.

.PARAMETER OutputPath
Directory where access review definition output will be written.

.EXAMPLE
.\New-AccessReview.ps1 -TenantId 00000000-0000-0000-0000-000000000000 -RiskScoreInputPath .\artifacts\oversharing-findings.json -OutputPath .\artifacts\reviews

.EXAMPLE
.\New-AccessReview.ps1 -TenantId 00000000-0000-0000-0000-000000000000 -UseMgGraph -RiskScoreInputPath .\artifacts\oversharing-findings.json
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantId,

    [Parameter()]
    [string]$ClientId,

    [Parameter()]
    [string]$ClientSecret,

    [Parameter()]
    [switch]$UseMgGraph,

    [Parameter()]
    [string]$RiskScoreInputPath,

    [Parameter()]
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\config\review-schedule.json'),

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\reviews')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\GraphAuth.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

function Get-ReviewSchedule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    if (-not (Test-Path -Path $fullPath)) {
        throw "Review schedule configuration not found: $fullPath"
    }

    return (Get-Content -Path $fullPath -Raw | ConvertFrom-Json)
}

function Get-RiskScoredSites {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$InputPath
    )

    if (-not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -Path $InputPath)) {
        try {
            $sites = Get-Content -Path $InputPath -Raw | ConvertFrom-Json
            return @($sites)
        }
        catch {
            Write-Warning "Failed to read risk score input from '$InputPath': $($_.Exception.Message). Using sample data."
        }
    }

    Write-Warning 'Using representative sample data. Connect to solution 02 output for production use.'
    return @(
        [pscustomobject]@{ siteUrl = 'https://contoso.sharepoint.com/sites/TradingDesk'; riskTier = 'HIGH'; owner = 'trading-desk-owner@contoso.com'; siteId = 'site-001'; groupId = 'group-001' }
        [pscustomobject]@{ siteUrl = 'https://contoso.sharepoint.com/sites/CustomerPII'; riskTier = 'HIGH'; owner = 'pii-owner@contoso.com'; siteId = 'site-002'; groupId = 'group-002' }
        [pscustomobject]@{ siteUrl = 'https://contoso.sharepoint.com/sites/ComplianceDocs'; riskTier = 'MEDIUM'; owner = 'compliance-lead@contoso.com'; siteId = 'site-003'; groupId = 'group-003' }
        [pscustomobject]@{ siteUrl = 'https://contoso.sharepoint.com/sites/HRPolicies'; riskTier = 'MEDIUM'; owner = 'hr-manager@contoso.com'; siteId = 'site-004'; groupId = 'group-004' }
        [pscustomobject]@{ siteUrl = 'https://contoso.sharepoint.com/sites/Marketing'; riskTier = 'LOW'; owner = 'marketing-lead@contoso.com'; siteId = 'site-005'; groupId = 'group-005' }
        [pscustomobject]@{ siteUrl = 'https://contoso.sharepoint.com/sites/GeneralCollab'; riskTier = 'LOW'; owner = 'collab-owner@contoso.com'; siteId = 'site-006'; groupId = 'group-006' }
    )
}

function New-ReviewDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Site,

        [Parameter(Mandatory)]
        [object]$Schedule,

        [Parameter(Mandatory)]
        [string]$RiskTier,

        [Parameter()]
        [object]$GraphContext
    )

    $cadence = $Schedule.reviewCadence.$RiskTier
    if ($null -eq $cadence) {
        Write-Warning "No cadence configured for risk tier '$RiskTier'. Skipping site: $($Site.siteUrl)"
        return $null
    }

    $reviewer = if ($Site.owner) { $Site.owner } else { $Schedule.fallbackReviewer }
    $reviewStartDate = Get-Date

    $reviewBody = [ordered]@{
        displayName = "Access Review - $($Site.siteUrl) [$RiskTier]"
        descriptionForAdmins = "Risk-triaged access review for group membership associated with SharePoint access. Risk tier: $RiskTier."
        descriptionForReviewers = "Please review whether each user still requires access through this group or access package."
        scope = [ordered]@{
            '@odata.type' = '#microsoft.graph.accessReviewQueryScope'
            query = "/groups/$($Site.groupId)/transitiveMembers"
            queryType = 'MicrosoftGraph'
        }
        reviewers = @(
            [ordered]@{
                query = "/users/$reviewer"
                queryType = 'MicrosoftGraph'
            }
        )
        settings = [ordered]@{
            mailNotificationsEnabled = $true
            reminderNotificationsEnabled = $true
            justificationRequiredOnApproval = $true
            defaultDecisionEnabled = $false
            defaultDecision = 'None'
            instanceDurationInDays = $cadence.durationDays
            autoApplyDecisionsEnabled = [bool]$Schedule.autoApplyDecisions
            recommendationsEnabled = $true
            recurrence = [ordered]@{
                pattern = [ordered]@{
                    type = 'absoluteMonthly'
                    interval = [math]::Ceiling($cadence.frequencyDays / 30)
                    dayOfMonth = [int]$reviewStartDate.Day
                }
                range = [ordered]@{
                    type = 'noEnd'
                    startDate = $reviewStartDate.ToString('yyyy-MM-dd')
                }
            }
        }
    }

    if ($null -ne $GraphContext -and $GraphContext.Mode -ne 'placeholder') {
        try {
            $result = Invoke-CopilotGovGraphRequest -Context $GraphContext `
                -Uri '/identityGovernance/accessReviews/definitions' `
                -Method 'POST' `
                -Body $reviewBody
            return [pscustomobject]@{
                reviewDefinitionId = $result.id
                siteUrl = $Site.siteUrl
                riskTier = $RiskTier
                reviewFrequencyDays = $cadence.frequencyDays
                reviewDurationDays = $cadence.durationDays
                reviewer = $reviewer
                scope = 'group-transitive-members'
                createdAt = (Get-Date).ToString('o')
                status = 'created'
            }
        }
        catch {
            Write-Warning "Failed to create access review for '$($Site.siteUrl)': $($_.Exception.Message)"
            return [pscustomobject]@{
                reviewDefinitionId = $null
                siteUrl = $Site.siteUrl
                riskTier = $RiskTier
                reviewFrequencyDays = $cadence.frequencyDays
                reviewDurationDays = $cadence.durationDays
                reviewer = $reviewer
                scope = 'group-transitive-members'
                createdAt = (Get-Date).ToString('o')
                status = 'failed'
                error = $_.Exception.Message
            }
        }
    }

    return [pscustomobject]@{
        reviewDefinitionId = "ear-$($Site.siteId)-$(Get-Date -Format 'yyyyMMdd')"
        siteUrl = $Site.siteUrl
        riskTier = $RiskTier
        reviewFrequencyDays = $cadence.frequencyDays
        reviewDurationDays = $cadence.durationDays
        reviewer = $reviewer
        scope = 'group-transitive-members'
        createdAt = (Get-Date).ToString('o')
        status = 'sample-data'
    }
}

$schedule = Get-ReviewSchedule -Path $ConfigPath
$sites = Get-RiskScoredSites -InputPath $RiskScoreInputPath

$graphContext = $null
if ($UseMgGraph.IsPresent) {
    try {
        $graphContext = Connect-CopilotGovGraph -TenantId $TenantId -UseMgGraph
    }
    catch {
        Write-Warning "Graph authentication failed: $($_.Exception.Message). Continuing with sample data."
        $graphContext = New-CopilotGovGraphContext -TenantId $TenantId
    }
}
elseif (-not [string]::IsNullOrWhiteSpace($ClientId) -and -not [string]::IsNullOrWhiteSpace($ClientSecret)) {
    try {
        $graphContext = Connect-CopilotGovGraph -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
    }
    catch {
        Write-Warning "Graph authentication failed: $($_.Exception.Message). Continuing with sample data."
        $graphContext = New-CopilotGovGraphContext -TenantId $TenantId
    }
}
else {
    $graphContext = New-CopilotGovGraphContext -TenantId $TenantId
}

$tierOrder = @('HIGH', 'MEDIUM', 'LOW')
$results = @()

foreach ($tier in $tierOrder) {
    $tierSites = @($sites | Where-Object { $_.riskTier -eq $tier })
    if ($tierSites.Count -eq 0) {
        Write-Verbose "No sites found for risk tier: $tier"
        continue
    }

    Write-Verbose "Creating access reviews for $($tierSites.Count) resources mapped to $tier-risk sites."

    foreach ($site in $tierSites) {
        $definition = New-ReviewDefinition -Site $site -Schedule $schedule -RiskTier $tier -GraphContext $graphContext
        if ($null -ne $definition) {
            $results += $definition
        }
    }
}

$outputRoot = [System.IO.Path]::GetFullPath($OutputPath)
$null = New-Item -Path $outputRoot -ItemType Directory -Force
$outputFile = Join-Path $outputRoot 'access-review-definitions.json'
$results | ConvertTo-Json -Depth 10 | Set-Content -Path $outputFile -Encoding utf8

[pscustomobject]@{
    TenantId = $TenantId
    ReviewsCreated = @($results).Count
    HighRisk = @($results | Where-Object { $_.riskTier -eq 'HIGH' }).Count
    MediumRisk = @($results | Where-Object { $_.riskTier -eq 'MEDIUM' }).Count
    LowRisk = @($results | Where-Object { $_.riskTier -eq 'LOW' }).Count
    OutputPath = $outputFile
}
