<#
.SYNOPSIS
Applies completed access review decisions and logs all actions to evidence.

.DESCRIPTION
Applies completed review decisions using
POST /identityGovernance/accessReviews/definitions/{id}/instances/{id}/decisions/apply.
For deny decisions, removes user from SharePoint site. Logs all applied decisions to an
evidence file for audit preparation.
Scripts use representative sample data and do not connect to live Microsoft 365 services.

.PARAMETER TenantId
Azure AD tenant GUID.

.PARAMETER ClientId
Application (client) ID for app-only authentication.

.PARAMETER ClientSecret
Client secret for app-only authentication.

.PARAMETER UseMgGraph
When set, uses Connect-MgGraph for delegated authentication instead of client credentials.

.PARAMETER ReviewDefinitionId
The access review definition ID whose decisions should be applied.

.PARAMETER OutputPath
Directory where applied actions output will be written.

.EXAMPLE
.\Apply-ReviewDecisions.ps1 -TenantId 00000000-0000-0000-0000-000000000000 -ReviewDefinitionId ear-site-001-review -OutputPath .\artifacts\reviews

.EXAMPLE
.\Apply-ReviewDecisions.ps1 -TenantId 00000000-0000-0000-0000-000000000000 -UseMgGraph -ReviewDefinitionId ear-site-001-review
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

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ReviewDefinitionId,

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\reviews')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\GraphAuth.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

function Get-SampleApplyResults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DefinitionId
    )

    $now = Get-Date
    return @(
        [pscustomobject]@{
            reviewDefinitionId = $DefinitionId
            instanceId = 'instance-001'
            userId = 'user-002'
            userDisplayName = 'External Contractor'
            userPrincipalName = 'contractor@external.com'
            decision = 'Deny'
            action = 'remove-access'
            siteUrl = 'https://contoso.sharepoint.com/sites/TradingDesk'
            appliedAt = $now.ToString('o')
            appliedBy = 'system-automation'
            status = 'sample-data'
            notes = 'Representative sample: deny decision would remove user from SharePoint site members.'
        }
        [pscustomobject]@{
            reviewDefinitionId = $DefinitionId
            instanceId = 'instance-001'
            userId = 'user-001'
            userDisplayName = 'Jane Doe'
            userPrincipalName = 'jane.doe@contoso.com'
            decision = 'Approve'
            action = 'maintain-access'
            siteUrl = 'https://contoso.sharepoint.com/sites/TradingDesk'
            appliedAt = $now.ToString('o')
            appliedBy = 'system-automation'
            status = 'sample-data'
            notes = 'Representative sample: approve decision maintains current access.'
        }
    )
}

function Invoke-ApplyDecisions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DefinitionId,

        [Parameter()]
        [object]$GraphContext
    )

    if ($null -ne $GraphContext -and $GraphContext.Mode -ne 'placeholder') {
        try {
            $instances = Invoke-CopilotGovGraphRequest -Context $GraphContext `
                -Uri "/identityGovernance/accessReviews/definitions/$DefinitionId/instances" `
                -Method 'GET' `
                -AllPages

            $appliedActions = @()
            foreach ($instance in $instances) {
                try {
                    Invoke-CopilotGovGraphRequest -Context $GraphContext `
                        -Uri "/identityGovernance/accessReviews/definitions/$DefinitionId/instances/$($instance.id)/decisions/apply" `
                        -Method 'POST' | Out-Null

                    $decisions = Invoke-CopilotGovGraphRequest -Context $GraphContext `
                        -Uri "/identityGovernance/accessReviews/definitions/$DefinitionId/instances/$($instance.id)/decisions" `
                        -Method 'GET' `
                        -AllPages

                    foreach ($decision in $decisions) {
                        $action = if ($decision.decision -eq 'Deny') { 'remove-access' } else { 'maintain-access' }

                        $appliedActions += [pscustomobject]@{
                            reviewDefinitionId = $DefinitionId
                            instanceId = $instance.id
                            userId = $decision.principal.id
                            userDisplayName = $decision.principal.displayName
                            userPrincipalName = $decision.principal.userPrincipalName
                            decision = $decision.decision
                            action = $action
                            appliedAt = (Get-Date).ToString('o')
                            appliedBy = 'system-automation'
                            status = 'applied'
                            notes = "Decision applied for review instance $($instance.id)."
                        }
                    }
                }
                catch {
                    Write-Warning "Failed to apply decisions for instance '$($instance.id)': $($_.Exception.Message)"
                }
            }

            return $appliedActions
        }
        catch {
            Write-Warning "Failed to apply review decisions: $($_.Exception.Message). Using sample data."
        }
    }

    Write-Warning 'Using representative sample data. Connect to Graph API for production use.'
    return Get-SampleApplyResults -DefinitionId $DefinitionId
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

$appliedActions = Invoke-ApplyDecisions -DefinitionId $ReviewDefinitionId -GraphContext $graphContext

$outputRoot = [System.IO.Path]::GetFullPath($OutputPath)
$null = New-Item -Path $outputRoot -ItemType Directory -Force
$outputFile = Join-Path $outputRoot 'applied-actions.json'
$appliedActions | ConvertTo-Json -Depth 10 | Set-Content -Path $outputFile -Encoding utf8

$denyCount = @($appliedActions | Where-Object { $_.decision -eq 'Deny' }).Count
$approveCount = @($appliedActions | Where-Object { $_.decision -eq 'Approve' }).Count

[pscustomobject]@{
    TenantId = $TenantId
    ReviewDefinitionId = $ReviewDefinitionId
    TotalActions = @($appliedActions).Count
    DenyActions = $denyCount
    ApproveActions = $approveCount
    OutputPath = $outputFile
}
