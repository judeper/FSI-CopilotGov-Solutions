<#
.SYNOPSIS
    Collects Copilot Studio agent lifecycle observations using a documentation-first stub.

.DESCRIPTION
    Loads CSLT configuration for the selected tier and produces a lifecycle compliance
    snapshot covering agent inventory, publishing approval evidence, version history,
    and deprecation records. The repository implementation uses a local stub data source;
    Power Platform admin API integration is required for live tenant collection. The
    script remains testable without external connectivity.

.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.

.PARAMETER OutputPath
    Path for compliance snapshots and monitoring artifacts.

.PARAMETER PassThru
    Returns the compliance status object after writing the monitoring snapshot.

.EXAMPLE
    .\Monitor-Compliance.ps1 -ConfigurationTier recommended -Verbose

.NOTES
    Solution: Copilot Studio Agent Lifecycle Tracker (CSLT)
    Version: v0.1.0
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts'),

    [Parameter()]
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'CsltConfig.psm1') -Force

$script:StubWarning = 'Lifecycle output came from the local CSLT stub and does not confirm live Power Platform admin API collection.'

function Get-AgentInventoryStub {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Environments
    )

    $records = @()
    $now = (Get-Date).ToUniversalTime()
    foreach ($env in $Environments) {
        $records += [pscustomobject]@{
            agentId = "sample-agent-$env"
            displayName = "Sample Copilot Studio Agent ($env)"
            environment = $env
            owner = 'sample.owner@contoso.com'
            businessSponsor = 'sample.sponsor@contoso.com'
            currentVersion = '1.0.0'
            lastPublishedAt = $now.AddDays(-15).ToString('o')
            lastReviewedAt = $now.AddDays(-45).ToString('o')
            lifecycleStage = 'publishing'
            sourceEndpoint = 'local-cslt-stub'
        }
    }
    return $records
}

function Get-PublishingApprovalStub {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration
    )

    $minApprovers = if ($Configuration.publishingApprovalLog.Contains('minimumApprovers')) { [int]$Configuration.publishingApprovalLog.minimumApprovers } else { 0 }
    $approvers = @()
    if ($minApprovers -ge 1) { $approvers += 'sample.approver1@contoso.com' }
    if ($minApprovers -ge 2) { $approvers += 'sample.approver2@contoso.com' }

    return ,([pscustomobject]@{
        agentId = 'sample-agent-production'
        version = '1.0.0'
        submittedBy = 'sample.author@contoso.com'
        submittedAt = (Get-Date).ToUniversalTime().AddDays(-16).ToString('o')
        approvers = $approvers
        approvedAt = (Get-Date).ToUniversalTime().AddDays(-15).ToString('o')
        changeSummary = 'Initial publish of sample agent.'
        tierApprovalRequirementMet = (-not $Configuration.publishingApprovalRequired) -or ($approvers.Count -ge [Math]::Max(1, $minApprovers))
    })
}

function Get-LifecycleReviewFindings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Inventory,

        [Parameter(Mandatory)]
        [int]$CadenceDays
    )

    $findings = @()
    $threshold = (Get-Date).ToUniversalTime().AddDays(-$CadenceDays)
    foreach ($agent in $Inventory) {
        $lastReviewed = [datetime]::Parse($agent.lastReviewedAt).ToUniversalTime()
        if ($lastReviewed -lt $threshold) {
            $findings += [pscustomobject]@{
                agentId = $agent.agentId
                lastReviewedAt = $agent.lastReviewedAt
                cadenceDays = $CadenceDays
                finding = 'overdue-lifecycle-review'
            }
        }
    }
    return $findings
}

Write-Verbose ("Loading CSLT configuration for tier [{0}]." -f $ConfigurationTier)
$configuration = Get-CsltConfiguration -Tier $ConfigurationTier
Test-CsltConfiguration -Configuration $configuration

$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$null = New-Item -ItemType Directory -Path $resolvedOutputPath -Force

Write-Warning $script:StubWarning

$inventory = Get-AgentInventoryStub -Environments @($configuration.defaults.monitoredEnvironments)
$approvals = Get-PublishingApprovalStub -Configuration $configuration
$findings = Get-LifecycleReviewFindings -Inventory $inventory -CadenceDays $configuration.lifecycleReviewCadenceDays

$status = [pscustomobject]@{
    solution = $configuration.solution
    tier = $ConfigurationTier
    capturedAt = (Get-Date).ToString('o')
    sourceEndpoint = 'local-cslt-stub'
    inventoryCount = $inventory.Count
    approvalCount = $approvals.Count
    overdueReviewCount = $findings.Count
    publishingApprovalRequired = $configuration.publishingApprovalRequired
    dualApproverRequired = $configuration.dualApproverRequired
    inventory = $inventory
    approvals = $approvals
    findings = $findings
}

$snapshotPath = Join-Path $resolvedOutputPath ("23-copilot-studio-lifecycle-tracker-monitor-{0}.json" -f $ConfigurationTier)
$status | ConvertTo-Json -Depth 10 | Set-Content -Path $snapshotPath -Encoding utf8
Write-Verbose ("Monitoring snapshot written to {0}." -f $snapshotPath)

Write-Host (
    "CSLT monitor [{0}]: {1} agents inventoried, {2} approval records, {3} overdue lifecycle reviews." -f
    $ConfigurationTier,
    $status.inventoryCount,
    $status.approvalCount,
    $status.overdueReviewCount
)

if ($PassThru) {
    return $status
}
