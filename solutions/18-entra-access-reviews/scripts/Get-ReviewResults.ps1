<#
.SYNOPSIS
Queries active access review decisions and flags reviews approaching expiry.

.DESCRIPTION
Queries Microsoft Entra ID Access Reviews for pending and completed decisions using
GET /identityGovernance/accessReviews/definitions/{id}/instances/{id}/decisions.
Flags reviews approaching expiry (within 48 hours by default) for escalation.
Scripts use representative sample data and do not connect to live Microsoft 365 services.

.PARAMETER TenantId
Microsoft Entra ID tenant GUID.

.PARAMETER ClientId
Application (client) ID for app-only authentication.

.PARAMETER ClientSecret
Client secret for app-only authentication.

.PARAMETER UseMgGraph
When set, uses Connect-MgGraph for delegated authentication instead of client credentials.

.PARAMETER OutputPath
Directory where review results output will be written.

.EXAMPLE
.\Get-ReviewResults.ps1 -TenantId 00000000-0000-0000-0000-000000000000 -OutputPath .\artifacts\reviews

.EXAMPLE
.\Get-ReviewResults.ps1 -TenantId 00000000-0000-0000-0000-000000000000 -UseMgGraph
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
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\reviews')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\GraphAuth.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

function Get-SampleReviewDecisions {
    [CmdletBinding()]
    param()

    $now = Get-Date
    return @(
        [pscustomobject]@{
            reviewDefinitionId = 'ear-site-001-review'
            instanceId = 'instance-001'
            decisionId = 'decision-001'
            userId = 'user-001'
            userDisplayName = 'Jane Doe'
            userPrincipalName = 'jane.doe@contoso.com'
            decision = 'Approve'
            reviewedBy = 'trading-desk-owner@contoso.com'
            reviewedAt = $now.AddDays(-2).ToString('o')
            justification = 'User requires continued access for trading operations.'
            siteUrl = 'https://contoso.sharepoint.com/sites/TradingDesk'
            riskTier = 'HIGH'
            instanceEndDateTime = $now.AddDays(5).ToString('o')
            status = 'completed'
        }
        [pscustomobject]@{
            reviewDefinitionId = 'ear-site-001-review'
            instanceId = 'instance-001'
            decisionId = 'decision-002'
            userId = 'user-002'
            userDisplayName = 'External Contractor'
            userPrincipalName = 'contractor@external.com'
            decision = 'Deny'
            reviewedBy = 'trading-desk-owner@contoso.com'
            reviewedAt = $now.AddDays(-1).ToString('o')
            justification = 'Contractor engagement ended. Access no longer required.'
            siteUrl = 'https://contoso.sharepoint.com/sites/TradingDesk'
            riskTier = 'HIGH'
            instanceEndDateTime = $now.AddDays(5).ToString('o')
            status = 'completed'
        }
        [pscustomobject]@{
            reviewDefinitionId = 'ear-site-002-review'
            instanceId = 'instance-002'
            decisionId = 'decision-003'
            userId = 'user-003'
            userDisplayName = 'Bob Smith'
            userPrincipalName = 'bob.smith@contoso.com'
            decision = 'NotReviewed'
            reviewedBy = $null
            reviewedAt = $null
            justification = $null
            siteUrl = 'https://contoso.sharepoint.com/sites/CustomerPII'
            riskTier = 'HIGH'
            instanceEndDateTime = $now.AddHours(36).ToString('o')
            status = 'pending'
        }
        [pscustomobject]@{
            reviewDefinitionId = 'ear-site-003-review'
            instanceId = 'instance-003'
            decisionId = 'decision-004'
            userId = 'user-004'
            userDisplayName = 'Alice Johnson'
            userPrincipalName = 'alice.johnson@contoso.com'
            decision = 'NotReviewed'
            reviewedBy = $null
            reviewedAt = $null
            justification = $null
            siteUrl = 'https://contoso.sharepoint.com/sites/ComplianceDocs'
            riskTier = 'MEDIUM'
            instanceEndDateTime = $now.AddDays(10).ToString('o')
            status = 'pending'
        }
    )
}

function Get-ReviewDecisions {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object]$GraphContext
    )

    if ($null -ne $GraphContext -and $GraphContext.Mode -ne 'placeholder') {
        try {
            $definitions = Invoke-CopilotGovGraphRequest -Context $GraphContext `
                -Uri '/identityGovernance/accessReviews/definitions' `
                -Method 'GET' `
                -AllPages

            $allDecisions = @()
            foreach ($definition in $definitions) {
                try {
                    $instances = Invoke-CopilotGovGraphRequest -Context $GraphContext `
                        -Uri "/identityGovernance/accessReviews/definitions/$($definition.id)/instances" `
                        -Method 'GET' `
                        -AllPages

                    foreach ($instance in $instances) {
                        try {
                            $decisions = Invoke-CopilotGovGraphRequest -Context $GraphContext `
                                -Uri "/identityGovernance/accessReviews/definitions/$($definition.id)/instances/$($instance.id)/decisions" `
                                -Method 'GET' `
                                -AllPages

                            foreach ($decision in $decisions) {
                                $allDecisions += [pscustomobject]@{
                                    reviewDefinitionId = $definition.id
                                    instanceId = $instance.id
                                    decisionId = $decision.id
                                    userId = $decision.principal.id
                                    userDisplayName = $decision.principal.displayName
                                    userPrincipalName = $decision.principal.userPrincipalName
                                    decision = $decision.decision
                                    reviewedBy = $decision.reviewedBy.displayName
                                    reviewedAt = $decision.reviewedDateTime
                                    justification = $decision.justification
                                    instanceEndDateTime = $instance.endDateTime
                                    status = if ($decision.decision -eq 'NotReviewed') { 'pending' } else { 'completed' }
                                }
                            }
                        }
                        catch {
                            Write-Warning "Failed to get decisions for instance '$($instance.id)': $($_.Exception.Message)"
                        }
                    }
                }
                catch {
                    Write-Warning "Failed to get instances for definition '$($definition.id)': $($_.Exception.Message)"
                }
            }

            return $allDecisions
        }
        catch {
            Write-Warning "Failed to query access reviews: $($_.Exception.Message). Using sample data."
        }
    }

    Write-Warning 'Using representative sample data. Connect to Graph API for production use.'
    return Get-SampleReviewDecisions
}

function Test-ApproachingExpiry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Decisions,

        [Parameter()]
        [int]$ThresholdHours = 48
    )

    $now = Get-Date
    $escalationItems = @()

    foreach ($decision in $Decisions) {
        if ($decision.status -ne 'pending') { continue }

        try {
            $endDate = [datetime]::Parse($decision.instanceEndDateTime)
            $hoursRemaining = ($endDate - $now).TotalHours

            if ($hoursRemaining -le $ThresholdHours -and $hoursRemaining -gt 0) {
                $escalationItems += [pscustomobject]@{
                    reviewDefinitionId = $decision.reviewDefinitionId
                    instanceId = $decision.instanceId
                    decisionId = $decision.decisionId
                    userId = $decision.userId
                    userDisplayName = $decision.userDisplayName
                    hoursRemaining = [math]::Round($hoursRemaining, 1)
                    instanceEndDateTime = $decision.instanceEndDateTime
                    escalationLevel = if ($hoursRemaining -le 24) { 'critical' } else { 'warning' }
                }
            }
        }
        catch {
            Write-Warning "Failed to parse end date for decision '$($decision.decisionId)': $($_.Exception.Message)"
        }
    }

    return $escalationItems
}

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

$decisions = Get-ReviewDecisions -GraphContext $graphContext
$escalationItems = Test-ApproachingExpiry -Decisions $decisions

$outputRoot = [System.IO.Path]::GetFullPath($OutputPath)
$null = New-Item -Path $outputRoot -ItemType Directory -Force

$decisionsFile = Join-Path $outputRoot 'review-decisions.json'
$decisions | ConvertTo-Json -Depth 10 | Set-Content -Path $decisionsFile -Encoding utf8

if ($escalationItems.Count -gt 0) {
    $escalationFile = Join-Path $outputRoot 'escalation-alerts.json'
    $escalationItems | ConvertTo-Json -Depth 10 | Set-Content -Path $escalationFile -Encoding utf8
}

$pendingCount = @($decisions | Where-Object { $_.status -eq 'pending' }).Count
$completedCount = @($decisions | Where-Object { $_.status -eq 'completed' }).Count

[pscustomobject]@{
    TenantId = $TenantId
    TotalDecisions = @($decisions).Count
    PendingDecisions = $pendingCount
    CompletedDecisions = $completedCount
    EscalationAlerts = @($escalationItems).Count
    DecisionsOutputPath = $decisionsFile
}
