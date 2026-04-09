<#
.SYNOPSIS
Evaluates the current compliance state of Agent Lifecycle and Deployment Governance.

.DESCRIPTION
Compares the current agent inventory to the approved baseline, identifies new or
unapproved agents, checks approval workflow SLA adherence, evaluates sharing policy
compliance, and prepares an operational status report. When requested, the script
creates an alert preview for newly detected agents that require review.

.PARAMETER ConfigurationTier
Governance tier to evaluate.

.PARAMETER AlertOnNewAgents
When supplied, generates a Teams notification preview when new agents are detected.

.PARAMETER OutputPath
Directory that contains prior deployment artifacts and where the compliance status file
should be written.

.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier regulated -AlertOnNewAgents -OutputPath ..\artifacts

.NOTES
This script supports compliance with FINRA 3110, OCC 2011-12, and DORA by highlighting
inventory drift, sharing policy changes, and overdue approval actions.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [switch]$AlertOnNewAgents,

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\TeamsNotification.psm1') -Force

function Get-AgentGovernanceConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SolutionRoot,

        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    return [pscustomobject]@{
        Default = Get-Content -Path (Join-Path $SolutionRoot 'config\default-config.json') -Raw | ConvertFrom-Json -Depth 20
        Baseline = Get-Content -Path (Join-Path $SolutionRoot 'config\baseline.json') -Raw | ConvertFrom-Json -Depth 20
        Tier = Get-Content -Path (Join-Path $SolutionRoot ("config\{0}.json" -f $Tier)) -Raw | ConvertFrom-Json -Depth 20
    }
}

function Get-ArtifactContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [scriptblock]$FallbackFactory
    )

    if (Test-Path -Path $Path) {
        return @(Get-Content -Path $Path -Raw | ConvertFrom-Json -Depth 20)
    }

    return @(& $FallbackFactory)
}

function Measure-AgentRisk {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Agent,

        [Parameter(Mandatory)]
        [pscustomobject]$DefaultConfig
    )

    if ($Agent.PSObject.Properties.Name -contains 'riskCategory' -and $Agent.riskCategory) {
        return $Agent.riskCategory
    }

    if ($DefaultConfig.blockedAgentIds -contains $Agent.agentId) {
        return 'blocked'
    }

    if ($Agent.publisherType -eq 'microsoftPublished') {
        return 'microsoftPublished'
    }

    if ($Agent.publisherType -eq 'itDeveloped') {
        return 'itDeveloped'
    }

    return 'userCreated'
}

function Get-UnapprovedAgents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$CurrentInventory,

        [Parameter(Mandatory)]
        [string[]]$ApprovedBaselineAgentIds,

        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$ConfigurationTier,

        [Parameter(Mandatory)]
        [pscustomobject]$DefaultConfig
    )

    $unapproved = foreach ($agent in $CurrentInventory) {
        $riskCategory = Measure-AgentRisk -Agent $agent -DefaultConfig $DefaultConfig
        $approvalStatus = if ($agent.PSObject.Properties.Name -contains 'approvalStatus' -and $agent.approvalStatus) {
            $agent.approvalStatus
        }
        elseif ($ConfigurationTier -eq 'regulated') {
            'pending-regulated-review'
        }
        elseif ($ApprovedBaselineAgentIds -contains $agent.agentId -and $riskCategory -eq 'microsoftPublished') {
            'approved'
        }
        else {
            'pending-review'
        }

        $isNewAgent = $ApprovedBaselineAgentIds -notcontains $agent.agentId
        if ($approvalStatus -ne 'approved' -or $isNewAgent) {
            [pscustomobject]@{
                agentId = $agent.agentId
                displayName = $agent.displayName
                riskCategory = $riskCategory
                approvalStatus = $approvalStatus
                isNewAgent = $isNewAgent
                sharingScope = if ($agent.PSObject.Properties.Name -contains 'sharingScope') { $agent.sharingScope } else { 'unknown' }
            }
        }
    }

    return @($unapproved)
}

function Test-ApprovalSLA {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$ApprovalRequests
    )

    $now = Get-Date

    $violations = foreach ($request in $ApprovalRequests) {
        if ($request.status -in @('approved', 'denied', 'blocked')) {
            continue
        }

        $dueBy = if ($request.PSObject.Properties.Name -contains 'dueBy' -and $request.dueBy) {
            [datetime]$request.dueBy
        }
        else {
            ([datetime]$request.requestedAt).AddHours(24)
        }

        if ($dueBy -lt $now) {
            [pscustomobject]@{
                requestId = $request.requestId
                agentId = $request.agentId
                displayName = $request.displayName
                approver = $request.approver
                overdueHours = [math]::Round(($now - $dueBy).TotalHours, 2)
                currentStage = if ($request.PSObject.Properties.Name -contains 'status') { $request.status } else { 'submitted' }
            }
        }
    }

    return @($violations)
}

function Test-SharingPolicyCompliance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$SharingPolicyAudit
    )

    $nonCompliant = foreach ($record in $SharingPolicyAudit) {
        if (-not $record.isCompliant) {
            [pscustomobject]@{
                policyDimension = $record.policyDimension
                currentSetting = $record.currentSetting
                expectedSetting = $record.expectedSetting
                notes = $record.notes
            }
        }
    }

    return @($nonCompliant)
}

try {
    $config = Get-AgentGovernanceConfiguration -SolutionRoot $solutionRoot -Tier $ConfigurationTier
    $baselineApprovedAgentIds = @($config.Baseline.approvalModel.autoApprovedAgentIds)

    $agentRegistryPath = Join-Path $OutputPath 'alg-agent-registry.json'
    $approvalRegisterPath = Join-Path $OutputPath 'alg-approval-register.json'
    $sharingPolicyPath = Join-Path $OutputPath 'alg-sharing-policy-audit.json'
    $statusPath = Join-Path $OutputPath 'alg-compliance-status.json'

    $currentInventory = Get-ArtifactContent -Path $agentRegistryPath -FallbackFactory {
        @(
            [pscustomobject]@{
                agentId = 'microsoft-365-copilot'
                displayName = 'Microsoft 365 Copilot'
                publisherType = 'microsoftPublished'
                sharingScope = 'org-wide'
                approvalStatus = if ($ConfigurationTier -eq 'regulated') { 'pending-regulated-review' } else { 'approved' }
            }
            [pscustomobject]@{
                agentId = 'contoso-helpdesk-agent'
                displayName = 'Contoso IT Helpdesk Agent'
                publisherType = 'itDeveloped'
                sharingScope = 'org-wide'
                approvalStatus = 'pending-security-review'
            }
            [pscustomobject]@{
                agentId = 'dept-productivity-agent'
                displayName = 'Sales Department Productivity Agent'
                publisherType = 'userCreated'
                sharingScope = 'org-wide'
                approvalStatus = 'pending-business-owner-attestation'
            }
            [pscustomobject]@{
                agentId = 'unapproved-third-party-agent'
                displayName = 'Unapproved External Agent'
                publisherType = 'blocked'
                sharingScope = 'org-wide'
                approvalStatus = 'blocked'
            }
        )
    }

    $approvalRequests = Get-ArtifactContent -Path $approvalRegisterPath -FallbackFactory {
        @(
            [pscustomobject]@{
                requestId = 'ALG-DEMO-001'
                agentId = 'contoso-helpdesk-agent'
                displayName = 'Contoso IT Helpdesk Agent'
                requestedAt = (Get-Date).AddHours(-18).ToString('o')
                dueBy = (Get-Date).AddHours(30).ToString('o')
                approver = 'alg-reviewers@contoso.com'
                status = 'submitted'
            }
            [pscustomobject]@{
                requestId = 'ALG-DEMO-002'
                agentId = 'dept-productivity-agent'
                displayName = 'Sales Department Productivity Agent'
                requestedAt = (Get-Date).AddHours(-36).ToString('o')
                dueBy = (Get-Date).AddHours(-6).ToString('o')
                approver = 'alg-reviewers@contoso.com'
                status = 'submitted'
            }
        )
    }

    $sharingPolicyAudit = Get-ArtifactContent -Path $sharingPolicyPath -FallbackFactory {
        @(
            [pscustomobject]@{
                policyDimension = 'orgWideSharingRestriction'
                currentSetting = 'admin-approval-required'
                expectedSetting = $config.Tier.sharingPolicyControls.orgWideSharingRestriction
                isCompliant = $true
                notes = 'Org-wide sharing restriction is configured as expected.'
            }
            [pscustomobject]@{
                policyDimension = 'externalSharingPolicy'
                currentSetting = 'disabled'
                expectedSetting = $config.Tier.sharingPolicyControls.externalSharingPolicy
                isCompliant = $true
                notes = 'External sharing is disabled as expected.'
            }
            [pscustomobject]@{
                policyDimension = 'catalogVisibility'
                currentSetting = 'admin-managed'
                expectedSetting = $config.Tier.sharingPolicyControls.catalogVisibility
                isCompliant = $true
                notes = 'Catalog visibility is configured as expected.'
            }
        )
    }

    $unapprovedAgents = Get-UnapprovedAgents `
        -CurrentInventory $currentInventory `
        -ApprovedBaselineAgentIds $baselineApprovedAgentIds `
        -ConfigurationTier $ConfigurationTier `
        -DefaultConfig $config.Default

    $slaViolations = Test-ApprovalSLA -ApprovalRequests $approvalRequests
    $sharingPolicyFindings = Test-SharingPolicyCompliance -SharingPolicyAudit $sharingPolicyAudit
    $newAgentCount = @($unapprovedAgents | Where-Object { $_.isNewAgent }).Count
    $pendingApprovalCount = @($approvalRequests | Where-Object { $_.status -notin @('approved', 'denied', 'blocked') }).Count
    $status = if (@($unapprovedAgents).Count -eq 0 -and @($slaViolations).Count -eq 0 -and @($sharingPolicyFindings).Count -eq 0) { 'implemented' } else { 'partial' }

    $alerts = @()
    if ($AlertOnNewAgents.IsPresent -and $newAgentCount -gt 0) {
        $alerts += New-TeamsMessageCard `
            -Title 'ALG new agent alert' `
            -Summary ("{0} agent records are outside the approved baseline and require review." -f $newAgentCount)
    }

    $report = [pscustomobject]@{
        solution = 'Agent Lifecycle and Deployment Governance'
        solutionCode = 'ALG'
        reviewedAt = (Get-Date).ToString('o')
        tier = $ConfigurationTier
        status = $status
        statusScore = Get-CopilotGovStatusScore -Status $status
        currentAgentCount = @($currentInventory).Count
        unapprovedAgentCount = @($unapprovedAgents).Count
        newAgentCount = $newAgentCount
        pendingApprovalCount = $pendingApprovalCount
        pendingApprovalSlaViolations = @($slaViolations).Count
        sharingPolicyFindingCount = @($sharingPolicyFindings).Count
        dataverseEvidenceTable = $config.Default.dataverseTables.evidence
        unapprovedAgents = $unapprovedAgents
        slaViolations = $slaViolations
        sharingPolicyFindings = $sharingPolicyFindings
        alerts = $alerts
    }

    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $report | ConvertTo-Json -Depth 20 | Set-Content -Path $statusPath -Encoding utf8

    Write-Output $report
}
catch {
    Write-Error -Message ("Agent governance monitoring failed: {0}" -f $_.Exception.Message)
    throw
}
