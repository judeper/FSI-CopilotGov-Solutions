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
Optional SharePoint tenant admin URL reserved for tenant-specific PnP remediation scaffolding.

.EXAMPLE
.\Invoke-BulkRemediation.ps1 -InputPath .\artifacts\scored\risk-scored-report.csv -OutputPath .\artifacts\remediation -TenantUrl "https://tenant-admin.sharepoint.com"

.EXAMPLE
.\Invoke-BulkRemediation.ps1 -InputPath .\artifacts\scored\risk-scored-report.csv -OutputPath .\artifacts\remediation -ConfigPath .\config\remediation-policy.json -TenantUrl "https://tenant-admin.sharepoint.com"
#>
# PnP.PowerShell is required for live SharePoint operations.
# Scripts fall back to representative sample data when PnP is unavailable.
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$InputPath,

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\remediation'),

    [Parameter()]
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\config\remediation-policy.json'),

    [Parameter()]
    [AllowEmptyString()]
    [string]$TenantUrl = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# TenantUrl accepted for future PnP/Graph connection wiring; not yet referenced in scaffold path.
$null = $TenantUrl

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

function Get-PolicyValue {
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
$null = New-Item -Path $outputRoot -ItemType Directory -Force -WhatIf:$false

$globalAutoRemediationEnabled = $false
$autoRemediationSetting = Get-PolicyValue -InputObject $policy -Name 'autoRemediationEnabled' -DefaultValue $null
if ($null -ne $autoRemediationSetting) {
    try {
        $globalAutoRemediationEnabled = [bool]$autoRemediationSetting
    }
    catch {
        $globalAutoRemediationEnabled = $false
    }
}

if (-not $globalAutoRemediationEnabled) {
    Write-Verbose "Global autoRemediationEnabled is disabled or absent. Forcing approval-gate behavior for all tiers."
}

$pendingApprovals = @()
$remediationLog = @()
$actionIndex = 1

foreach ($item in $scoredItems) {
    $riskTier = [string]$item.RiskTier
    if ([string]::IsNullOrWhiteSpace($riskTier)) {
        $riskTier = 'LOW'
    }
    $riskTier = $riskTier.ToUpperInvariant()

    if ([string]$item.ShareType -eq 'AnyoneLink' -and $riskTier -ne 'HIGH') {
        Write-Warning "Item $($item.ItemPath) is AnyoneLink but reported as $riskTier. Enforcing HIGH risk approval handling."
        $riskTier = 'HIGH'
    }

    $action = Get-RemediationAction -ShareType $item.ShareType

    $tierPolicy = switch ($riskTier) {
        'HIGH' { $policy.HIGH }
        'MEDIUM' { $policy.MEDIUM }
        'LOW' { $policy.LOW }
        default { [pscustomobject]@{ mode = 'approval-gate' } }
    }

    $configuredMode = [string](Get-PolicyValue -InputObject $tierPolicy -Name 'mode' -DefaultValue 'approval-gate')
    if ([string]::IsNullOrWhiteSpace($configuredMode)) {
        $configuredMode = 'approval-gate'
    }

    $effectiveMode = $configuredMode
    $policyNotes = @()

    if (-not $globalAutoRemediationEnabled) {
        if ($configuredMode -eq 'auto-remediate') {
            $policyNotes += 'Global autoRemediationEnabled is false or absent; forced approval-gate.'
        }
        $effectiveMode = 'approval-gate'
    }

    if ($riskTier -eq 'HIGH') {
        if ($configuredMode -eq 'auto-remediate') {
            $policyNotes += 'HIGH risk always requires approval; auto-remediate mode ignored.'
        }
        $effectiveMode = 'approval-gate'
    }

    $actionId = 'IOS-{0:D4}' -f $actionIndex

    if ($effectiveMode -eq 'approval-gate') {
        $approvalNote = if (@($policyNotes).Count -gt 0) {
            (@($policyNotes) -join ' ')
        }
        else {
            'Routed to approval gate. No action taken.'
        }

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
            notes = $approvalNote
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
            notes = $approvalNote
        }
    }
    elseif ($effectiveMode -eq 'auto-remediate') {
        try {
            $target = if ([string]::IsNullOrWhiteSpace([string]$item.SiteUrl)) {
                [string]$item.ItemPath
            }
            else {
                '{0} :: {1}' -f $item.SiteUrl, $item.ItemPath
            }

            if ($PSCmdlet.ShouldProcess($target, "Apply auto-remediation action '$action'")) {
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
            else {
                Write-Verbose "WhatIf/ShouldProcess prevented auto-remediation for $($item.ItemPath). Logged as planned only."

                $remediationLog += [pscustomobject]@{
                    actionId = $actionId
                    siteUrl = $item.SiteUrl
                    itemPath = $item.ItemPath
                    shareType = $item.ShareType
                    riskTier = $riskTier
                    action = $action
                    status = 'planned-whatif'
                    approvalRequired = $false
                    approvedBy = $null
                    executedAt = $null
                    notes = 'WhatIf/ShouldProcess prevented mutation. Planned action only.'
                }
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
    else {
        Write-Warning "Unsupported remediation mode '$effectiveMode' for $($item.ItemPath). Item logged as skipped."

        $remediationLog += [pscustomobject]@{
            actionId = $actionId
            siteUrl = $item.SiteUrl
            itemPath = $item.ItemPath
            shareType = $item.ShareType
            riskTier = $riskTier
            action = $action
            status = 'skipped-unsupported-mode'
            approvalRequired = $false
            approvedBy = $null
            executedAt = $null
            notes = "Unsupported remediation mode '$effectiveMode'. No action taken."
        }
    }

    $actionIndex++
}

$pendingApprovalsPath = Join-Path $outputRoot 'pending-approvals.json'
$remediationLogPath = Join-Path $outputRoot 'remediation-log.json'

$pendingApprovalsJson = ConvertTo-Json -InputObject @($pendingApprovals) -Depth 5
$remediationLogJson = ConvertTo-Json -InputObject @($remediationLog) -Depth 5

Set-Content -Path $pendingApprovalsPath -Value $pendingApprovalsJson -Encoding UTF8 -WhatIf:$false
Set-Content -Path $remediationLogPath -Value $remediationLogJson -Encoding UTF8 -WhatIf:$false

[pscustomobject]@{
    TotalItems = @($scoredItems).Count
    PendingApprovals = @($pendingApprovals).Count
    ActionsLogged = @($remediationLog).Count
    PlannedNoChange = @($remediationLog | Where-Object { $_.status -eq 'planned-whatif' }).Count
    GlobalAutoRemediationEnabled = $globalAutoRemediationEnabled
    PendingApprovalsPath = $pendingApprovalsPath
    RemediationLogPath = $remediationLogPath
}
