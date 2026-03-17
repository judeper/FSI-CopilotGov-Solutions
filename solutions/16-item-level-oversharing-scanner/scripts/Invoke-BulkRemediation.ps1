<#
.SYNOPSIS
Applies approval-gated remediation for overshared items.

.DESCRIPTION
Reads the risk-scored report from Export-OversharedItems.ps1 and applies
remediation actions based on the remediation policy configuration. HIGH-risk
items always require approval and are written to pending-approvals.json
without taking action. MEDIUM and LOW items follow the mode defined in
remediation-policy.json, which defaults to approval-gate.

Supported remediation actions include removing sharing links, removing
external user permissions, and downgrading organization links from Edit
to View access.

Scripts use representative sample data and do not connect to live Microsoft 365
services in their repository form.

.PARAMETER InputPath
Path to the risk-scored report CSV produced by Export-OversharedItems.ps1.

.PARAMETER OutputPath
Directory where remediation logs and pending approvals will be written.

.PARAMETER ConfigPath
Path to the remediation-policy.json configuration file.

.PARAMETER TenantUrl
SharePoint tenant admin URL used for PnP connection during remediation.

.EXAMPLE
.\Invoke-BulkRemediation.ps1 -InputPath .\artifacts\scored\risk-scored-report.csv -OutputPath .\artifacts\remediation -TenantUrl "https://tenant-admin.sharepoint.com"

.EXAMPLE
.\Invoke-BulkRemediation.ps1 -InputPath .\artifacts\scored\risk-scored-report.csv -OutputPath .\artifacts\remediation -ConfigPath .\config\remediation-policy.json -TenantUrl "https://tenant-admin.sharepoint.com"
#>
#Requires -Modules PnP.PowerShell
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$InputPath,

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\remediation'),

    [Parameter()]
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\config\remediation-policy.json'),

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantUrl
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\GraphAuth.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

function Get-RemediationAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ShareType
    )

    switch ($ShareType) {
        'AnyoneLink' { return 'Remove anonymous sharing link' }
        'ExternalUser' { return 'Remove external user permission' }
        'OrgLink' { return 'Downgrade organization link from Edit to View' }
        'BroadGroup' { return 'Remove broad group permission and apply targeted sharing' }
        default { return 'Review and remediate manually' }
    }
}

try {
    $policy = (Get-Content -Path $ConfigPath -Raw) | ConvertFrom-Json
}
catch {
    Write-Warning "Failed to load remediation policy from $ConfigPath. Using approval-gate defaults."
    $policy = [pscustomobject]@{
        HIGH = [pscustomobject]@{ mode = 'approval-gate' }
        MEDIUM = [pscustomobject]@{ mode = 'approval-gate' }
        LOW = [pscustomobject]@{ mode = 'approval-gate' }
        autoRemediationEnabled = $false
    }
}

try {
    $scoredItems = Import-Csv -Path $InputPath -Encoding UTF8
}
catch {
    throw "Failed to read risk-scored report from $InputPath : $_"
}

$outputRoot = [System.IO.Path]::GetFullPath($OutputPath)
$null = New-Item -Path $outputRoot -ItemType Directory -Force

$pendingApprovals = @()
$remediationLog = @()
$actionIndex = 1

foreach ($item in $scoredItems) {
    $riskTier = $item.RiskTier
    $action = Get-RemediationAction -ShareType $item.ShareType

    $tierPolicy = switch ($riskTier) {
        'HIGH' { $policy.HIGH }
        'MEDIUM' { $policy.MEDIUM }
        'LOW' { $policy.LOW }
        default { [pscustomobject]@{ mode = 'approval-gate' } }
    }

    $mode = if ($tierPolicy -is [hashtable]) { $tierPolicy['mode'] } else { $tierPolicy.mode }
    if ($null -eq $mode) { $mode = 'approval-gate' }

    $actionId = 'IOS-{0:D4}' -f $actionIndex

    if ($riskTier -eq 'HIGH' -or $mode -eq 'approval-gate') {
        $pendingApprovals += [pscustomobject]@{
            actionId = $actionId
            siteUrl = $item.SiteUrl
            itemPath = $item.ItemPath
            shareType = $item.ShareType
            riskTier = $riskTier
            weightedScore = $item.WeightedScore
            action = $action
            status = 'pending-approval'
            approvalRequired = $true
            approvedBy = $null
            executedAt = $null
            notes = "Awaiting compliance/legal approval before remediation."
        }

        $remediationLog += [pscustomobject]@{
            actionId = $actionId
            siteUrl = $item.SiteUrl
            itemPath = $item.ItemPath
            shareType = $item.ShareType
            riskTier = $riskTier
            action = $action
            status = 'pending-approval'
            approvalRequired = $true
            approvedBy = $null
            executedAt = $null
            notes = "Routed to approval gate. No action taken."
        }
    }
    elseif ($mode -eq 'auto-remediate') {
        try {
            Write-Verbose "Auto-remediation stub: $action for $($item.ItemPath)"

            $remediationLog += [pscustomobject]@{
                actionId = $actionId
                siteUrl = $item.SiteUrl
                itemPath = $item.ItemPath
                shareType = $item.ShareType
                riskTier = $riskTier
                action = $action
                status = 'completed-stub'
                approvalRequired = $false
                approvedBy = 'auto'
                executedAt = (Get-Date).ToString('o')
                notes = "Auto-remediation stub executed. Replace with live PnP calls for production."
            }
        }
        catch {
            Write-Warning "Remediation failed for $($item.ItemPath): $_"

            $remediationLog += [pscustomobject]@{
                actionId = $actionId
                siteUrl = $item.SiteUrl
                itemPath = $item.ItemPath
                shareType = $item.ShareType
                riskTier = $riskTier
                action = $action
                status = 'failed'
                approvalRequired = $false
                approvedBy = $null
                executedAt = $null
                notes = "Remediation failed: $_"
            }
        }
    }

    $actionIndex++
}

$pendingApprovalsPath = Join-Path $outputRoot 'pending-approvals.json'
$remediationLogPath = Join-Path $outputRoot 'remediation-log.json'

@($pendingApprovals) | ConvertTo-Json -Depth 5 | Set-Content -Path $pendingApprovalsPath -Encoding UTF8
@($remediationLog) | ConvertTo-Json -Depth 5 | Set-Content -Path $remediationLogPath -Encoding UTF8

[pscustomobject]@{
    TotalItems = @($scoredItems).Count
    PendingApprovals = @($pendingApprovals).Count
    ActionsLogged = @($remediationLog).Count
    PendingApprovalsPath = $pendingApprovalsPath
    RemediationLogPath = $remediationLogPath
}
