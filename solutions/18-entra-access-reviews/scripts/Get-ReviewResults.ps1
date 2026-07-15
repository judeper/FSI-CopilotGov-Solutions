<#
.SYNOPSIS
Queries active access review decisions and flags reviews approaching expiry.

.DESCRIPTION
Queries access reviews in Microsoft Entra ID Governance for pending and completed decisions using
GET /identityGovernance/accessReviews/definitions/{id}/instances/{id}/decisions.
Flags reviews approaching expiry using the selected governance-tier escalation threshold
(48 hours by default, 24 hours in the regulated tier).
Scripts use representative sample data and do not connect to live Microsoft 365 services.

.PARAMETER TenantId
Microsoft Entra ID tenant GUID.

.PARAMETER ClientId
Application (client) ID for app-only authentication.

.PARAMETER ClientSecret
Client secret for app-only authentication, provided as a SecureString. Migrate to managed identity (Stage 2, tenant-bound) when available.

.PARAMETER UseMgGraph
When set, uses Connect-MgGraph for delegated authentication instead of client credentials.

.PARAMETER ConfigurationTier
Selects the governance tier to apply for escalation behavior. Supported values are baseline,
recommended, and regulated.

.PARAMETER EscalationThresholdHours
Optional override for escalation threshold hours. Use -1 to apply the tier configuration value.

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
    # IDENTITY-STANDARD: legacy-client-secret — accepts SecureString; migrate to managed identity (Stage 2, tenant-bound)
    [System.Security.SecureString]$ClientSecret,

    [Parameter()]
    [switch]$UseMgGraph,

    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [ValidateRange(-1, 168)]
    [int]$EscalationThresholdHours = -1,

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\reviews')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\GraphAuth.psm1') -Force

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

function ConvertTo-ObjectArray {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object]$InputObject
    )

    if ($null -eq $InputObject) {
        return @()
    }

    return @($InputObject)
}

function Get-DefinitionContext {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object]$Definition
    )

    $siteUrl = $null
    $riskTier = $null

    if ($null -ne $Definition) {
        if (($Definition.PSObject.Properties.Name -contains 'siteUrl') -and -not [string]::IsNullOrWhiteSpace([string]$Definition.siteUrl)) {
            $siteUrl = [string]$Definition.siteUrl
        }

        if (($Definition.PSObject.Properties.Name -contains 'riskTier') -and -not [string]::IsNullOrWhiteSpace([string]$Definition.riskTier)) {
            $riskTier = [string]$Definition.riskTier
        }

        if (($Definition.PSObject.Properties.Name -contains 'displayName') -and ($Definition.displayName -match '^Access Review - (?<siteUrl>https?://.+?) \[(?<riskTier>[^\]]+)\]$')) {
            if ([string]::IsNullOrWhiteSpace($siteUrl)) {
                $siteUrl = [string]$Matches['siteUrl']
            }
            if ([string]::IsNullOrWhiteSpace($riskTier)) {
                $riskTier = [string]$Matches['riskTier']
            }
        }
    }

    return [pscustomobject]@{
        siteUrl = $siteUrl
        riskTier = $riskTier
    }
}

function Get-SampleReviewDecision {
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

function Get-ReviewDecision {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object]$GraphContext
    )

    if ($null -ne $GraphContext -and $GraphContext.Mode -ne 'placeholder') {
        try {
            $definitions = ConvertTo-ObjectArray -InputObject (Invoke-CopilotGovGraphRequest -Context $GraphContext `
                -Uri '/identityGovernance/accessReviews/definitions' `
                -Method 'GET' `
                -AllPages)

            if ($definitions.Count -eq 0) {
                Write-Verbose 'No access review definitions were returned from Microsoft Graph.'
                return @()
            }

            $allDecisions = @()
            foreach ($definition in $definitions) {
                $definitionContext = Get-DefinitionContext -Definition $definition
                try {
                    $instances = ConvertTo-ObjectArray -InputObject (Invoke-CopilotGovGraphRequest -Context $GraphContext `
                        -Uri "/identityGovernance/accessReviews/definitions/$($definition.id)/instances" `
                        -Method 'GET' `
                        -AllPages)

                    if ($instances.Count -eq 0) {
                        Write-Verbose "No instances returned for definition '$($definition.id)'."
                        continue
                    }

                    foreach ($instance in $instances) {
                        try {
                            $decisions = ConvertTo-ObjectArray -InputObject (Invoke-CopilotGovGraphRequest -Context $GraphContext `
                                -Uri "/identityGovernance/accessReviews/definitions/$($definition.id)/instances/$($instance.id)/decisions" `
                                -Method 'GET' `
                                -AllPages)

                            if ($decisions.Count -eq 0) {
                                Write-Verbose "No decisions returned for definition '$($definition.id)' instance '$($instance.id)'."
                                continue
                            }

                            foreach ($decision in $decisions) {
                                $principal = if ($null -ne $decision) { $decision.principal } else { $null }
                                $reviewedBy = if (($null -ne $decision) -and ($null -ne $decision.reviewedBy)) { $decision.reviewedBy.displayName } else { $null }
                                $allDecisions += [pscustomobject]@{
                                    reviewDefinitionId = $definition.id
                                    instanceId = $instance.id
                                    decisionId = $decision.id
                                    userId = if ($null -ne $principal) { $principal.id } else { $null }
                                    userDisplayName = if ($null -ne $principal) { $principal.displayName } else { $null }
                                    userPrincipalName = if ($null -ne $principal) { $principal.userPrincipalName } else { $null }
                                    decision = $decision.decision
                                    reviewedBy = $reviewedBy
                                    reviewedAt = $decision.reviewedDateTime
                                    justification = $decision.justification
                                    siteUrl = $definitionContext.siteUrl
                                    riskTier = $definitionContext.riskTier
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
    return Get-SampleReviewDecision
}

function Test-ApproachingExpiry {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object[]]$Decisions = @(),

        [Parameter()]
        [int]$ThresholdHours = 48
    )

    if (@($Decisions).Count -eq 0) {
        return @()
    }

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

$configuration = Get-Configuration -ConfigurationTier $ConfigurationTier
$escalationEnabled = [bool]$configuration.enableEscalation
$configuredThresholdHours = if ($configuration.ContainsKey('escalationThresholdHours')) { [int]$configuration.escalationThresholdHours } else { 48 }
$effectiveThresholdHours = if ($EscalationThresholdHours -ge 0) { $EscalationThresholdHours } else { $configuredThresholdHours }

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
elseif (-not [string]::IsNullOrWhiteSpace($ClientId) -and ($null -ne $ClientSecret)) {
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

$decisions = Get-ReviewDecision -GraphContext $graphContext
$escalationItems = if ($escalationEnabled) {
    @(Test-ApproachingExpiry -Decisions $decisions -ThresholdHours $effectiveThresholdHours)
}
else {
    @()
}

$outputRoot = [System.IO.Path]::GetFullPath($OutputPath)
$null = New-Item -Path $outputRoot -ItemType Directory -Force

$decisionsFile = Join-Path $outputRoot 'review-decisions.json'
$decisions | ConvertTo-Json -Depth 10 | Set-Content -Path $decisionsFile -Encoding utf8

if (@($escalationItems).Count -gt 0) {
    $escalationFile = Join-Path $outputRoot 'escalation-alerts.json'
    $escalationItems | ConvertTo-Json -Depth 10 | Set-Content -Path $escalationFile -Encoding utf8
}

$pendingCount = @($decisions | Where-Object { $_.status -eq 'pending' }).Count
$completedCount = @($decisions | Where-Object { $_.status -eq 'completed' }).Count

[pscustomobject]@{
    TenantId = $TenantId
    ConfigurationTier = $ConfigurationTier
    TotalDecisions = @($decisions).Count
    PendingDecisions = $pendingCount
    CompletedDecisions = $completedCount
    EscalationEnabled = $escalationEnabled
    EscalationThresholdHours = if ($escalationEnabled) { $effectiveThresholdHours } else { $null }
    EscalationAlerts = @($escalationItems).Count
    DecisionsOutputPath = $decisionsFile
}
