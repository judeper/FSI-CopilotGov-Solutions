<#
.SYNOPSIS
Exports evidence for Agent Lifecycle and Deployment Governance.

.DESCRIPTION
Creates documentation-led agent registry, approval register, and sharing policy audit
artifacts for the selected governance tier, writes SHA-256 companion files for every emitted
artifact, and packages the export by using the shared repository evidence contract.

.PARAMETER ConfigurationTier
Governance tier to report in the evidence package.

.PARAMETER OutputPath
Directory where the evidence package and companion artifacts are written.

.EXAMPLE
.\Export-Evidence.ps1 -ConfigurationTier regulated -OutputPath ..\artifacts
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
$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

function Read-JsonAsHashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return Get-Content -Path $Path -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable
}

function Merge-Hashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Base,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Overlay
    )

    $result = [ordered]@{}
    foreach ($key in $Base.Keys) {
        $result[$key] = $Base[$key]
    }

    foreach ($key in $Overlay.Keys) {
        if ($result.Contains($key) -and ($result[$key] -is [System.Collections.IDictionary]) -and ($Overlay[$key] -is [System.Collections.IDictionary])) {
            $result[$key] = Merge-Hashtable -Base $result[$key] -Overlay $Overlay[$key]
            continue
        }

        $result[$key] = $Overlay[$key]
    }

    return $result
}

function Get-AlgConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    $defaultConfig = Read-JsonAsHashtable -Path (Join-Path $solutionRoot 'config\default-config.json')
    $tierConfig = Read-JsonAsHashtable -Path (Join-Path $solutionRoot ("config\{0}.json" -f $Tier))
    return (Merge-Hashtable -Base $defaultConfig -Overlay $tierConfig)
}

function Write-ArtifactDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [object]$Content
    )

    $Content | ConvertTo-Json -Depth 20 | Set-Content -Path $Path -Encoding utf8
    $hashInfo = Write-CopilotGovSha256File -Path $Path

    return [pscustomobject]@{
        name = $Name
        type = 'json'
        path = $Path
        hash = $hashInfo.Hash
    }
}

$config = Get-AlgConfiguration -Tier $ConfigurationTier
$resolvedOutputPath = [IO.Path]::GetFullPath($OutputPath)
$null = New-Item -ItemType Directory -Path $resolvedOutputPath -Force
$exportedAt = (Get-Date).ToString('o')

$agentRegistry = @(
    [pscustomobject]@{
        agentId = 'microsoft-365-copilot'
        displayName = 'Microsoft 365 Copilot'
        publisher = 'Microsoft'
        publisherType = 'microsoftPublished'
        riskCategory = 'microsoftPublished'
        approvalStatus = if (@($config.approvalModel.autoApprovedAgentIds) -contains 'microsoft-365-copilot') { 'approved' } else { 'pending-security-review' }
        sharingScope = 'org-wide'
        deploymentRing = 'production'
        agentType = 'microsoft-built'
        createdBy = 'Microsoft'
        lastSeen = $exportedAt
        classificationReason = 'Microsoft-published agent operating within documented service boundaries.'
    }
    [pscustomobject]@{
        agentId = 'contoso-helpdesk-agent'
        displayName = 'Contoso IT Helpdesk Agent'
        publisher = 'Contoso IT'
        publisherType = 'itDeveloped'
        riskCategory = 'itDeveloped'
        approvalStatus = 'pending-security-review'
        sharingScope = 'org-wide'
        deploymentRing = 'pilot'
        agentType = 'copilot-studio'
        createdBy = 'it-engineering@contoso.com'
        lastSeen = $exportedAt
        classificationReason = 'IT-developed agent subject to internal development governance.'
    }
    [pscustomobject]@{
        agentId = 'dept-productivity-agent'
        displayName = 'Sales Department Productivity Agent'
        publisher = 'Sales Team'
        publisherType = 'userCreated'
        riskCategory = 'userCreated'
        approvalStatus = 'pending-business-owner-attestation'
        sharingScope = 'org-wide'
        deploymentRing = 'none'
        agentType = 'copilot-studio'
        createdBy = 'sales-lead@contoso.com'
        lastSeen = $exportedAt
        classificationReason = 'User-created Copilot Studio agent that requires supervisory review before broader distribution.'
    }
    [pscustomobject]@{
        agentId = 'unapproved-third-party-agent'
        displayName = 'Unapproved External Agent'
        publisher = 'Unknown Publisher'
        publisherType = 'blocked'
        riskCategory = 'blocked'
        approvalStatus = 'blocked'
        sharingScope = 'org-wide'
        deploymentRing = 'none'
        agentType = 'third-party'
        createdBy = 'unknown'
        lastSeen = $exportedAt
        classificationReason = 'Agent is explicitly prohibited by tenant policy for regulated Copilot use.'
    }
)

$approvalRegister = @(
    foreach ($agent in @($agentRegistry | Where-Object { $_.approvalStatus -ne 'approved' })) {
        $slaHours = [int]$config.approvalSLAHours[$agent.riskCategory]
        [pscustomobject]@{
            requestId = ('ALG-{0}' -f $agent.agentId.ToUpperInvariant())
            agentId = $agent.agentId
            displayName = $agent.displayName
            riskCategory = $agent.riskCategory
            requestedAt = $exportedAt
            dueBy = (Get-Date).AddHours($slaHours).ToString('o')
            approver = if ($agent.riskCategory -eq 'userCreated') { 'CISO-Review' } else { 'Security-Review-Queue' }
            stages = if (($agent.riskCategory -eq 'userCreated') -and $config.approvalModel.ContainsKey('userCreatedReviewStages')) {
                @($config.approvalModel.userCreatedReviewStages)
            }
            else {
                @($config.approvalModel.mandatoryReviewStages)
            }
            status = if ($agent.approvalStatus -eq 'blocked') { 'denied' } else { 'submitted' }
            notes = if ($agent.approvalStatus -eq 'blocked') {
                'Agent remains blocked because it targets a prohibited publisher or data access boundary.'
            }
            else {
                'Approval workflow retains review timing and decision notes for supervisory review.'
            }
        }
    }
)

$sharingPolicyAudit = @(
    [pscustomobject]@{
        auditId = 'ALG-SP-ORGWIDE'
        policyDimension = 'orgWideSharingRestriction'
        currentSetting = 'admin-approval-required'
        expectedSetting = $config.sharingPolicyControls.orgWideSharingRestriction
        isCompliant = $true
        auditedOn = $exportedAt
        auditedBy = 'ALG-SharingPolicyAudit'
        notes = 'Org-wide sharing restriction is set to require admin approval before agents can be shared with the entire organization.'
    }
    [pscustomobject]@{
        auditId = 'ALG-SP-EXTERNAL'
        policyDimension = 'externalSharingPolicy'
        currentSetting = 'disabled'
        expectedSetting = $config.sharingPolicyControls.externalSharingPolicy
        isCompliant = $true
        auditedOn = $exportedAt
        auditedBy = 'ALG-SharingPolicyAudit'
        notes = 'External sharing is disabled for Copilot Studio agents in the tenant.'
    }
    [pscustomobject]@{
        auditId = 'ALG-SP-CATALOG'
        policyDimension = 'catalogVisibility'
        currentSetting = 'admin-managed'
        expectedSetting = $config.sharingPolicyControls.catalogVisibility
        isCompliant = $true
        auditedOn = $exportedAt
        auditedBy = 'ALG-SharingPolicyAudit'
        notes = 'Agent catalog visibility is managed by administrators with controlled agent publishing.'
    }
)

$registryArtifact = Write-ArtifactDocument -Path (Join-Path $resolvedOutputPath 'agent-registry.json') -Name 'agent-registry' -Content $agentRegistry
$approvalArtifact = Write-ArtifactDocument -Path (Join-Path $resolvedOutputPath 'approval-register.json') -Name 'approval-register' -Content $approvalRegister
$sharingArtifact = Write-ArtifactDocument -Path (Join-Path $resolvedOutputPath 'sharing-policy-audit.json') -Name 'sharing-policy-audit' -Content $sharingPolicyAudit

$controls = @(
    [pscustomobject]@{
        controlId = '1.13'
        status = 'partial'
        notes = 'Agent inventory and risk classification are exported, but agent-level due diligence still requires manual review.'
    }
    [pscustomobject]@{
        controlId = '2.13'
        status = 'implemented'
        notes = 'Agent deployment boundaries and sharing policy audit records document approved agent distribution scope.'
    }
    [pscustomobject]@{
        controlId = '2.14'
        status = 'implemented'
        notes = 'Approval-register export captures reviewer routing, SLA timing, and escalation stages for agent enablement.'
    }
    [pscustomobject]@{
        controlId = '4.1'
        status = 'partial'
        notes = 'Agent deployment gating integrates with feature management controls, but rollout ring enforcement requires solution 09.'
    }
    [pscustomobject]@{
        controlId = '4.13'
        status = 'partial'
        notes = 'Operational monitoring records blocked and pending agents and sharing policy drift, while DORA register reconciliation remains a manual control.'
    }
)

$artifacts = @($registryArtifact, $approvalArtifact, $sharingArtifact)
$package = Export-SolutionEvidencePackage `
    -Solution '19-agent-lifecycle-governance' `
    -SolutionCode 'ALG' `
    -Tier $ConfigurationTier `
    -OutputPath $resolvedOutputPath `
    -Summary @{
        overallStatus = 'partial'
        recordCount = ($agentRegistry.Count + $approvalRegister.Count + $sharingPolicyAudit.Count)
        findingCount = @($approvalRegister | Where-Object { $_.status -ne 'approved' }).Count
        exceptionCount = @($sharingPolicyAudit | Where-Object { -not $_.isCompliant }).Count
        manualActionsRequired = @(
            'Reconcile approved agents with third-party dependencies to the DORA ICT third-party register.',
            'Complete manual supervisory review for user-created Copilot Studio agents before production rollout.',
            'Verify sharing policy settings in Copilot Studio admin center match governance tier expectations.'
        )
    } `
    -Controls $controls `
    -Artifacts $artifacts

[pscustomobject]@{
    Package = $package
    Controls = $controls
    Artifacts = $artifacts
}
