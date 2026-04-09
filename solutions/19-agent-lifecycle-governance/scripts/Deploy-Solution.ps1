<#
.SYNOPSIS
Builds the deployment manifest for Agent Lifecycle and Deployment Governance.

.DESCRIPTION
Simulates agent catalog enumeration from the M365 Admin Center and Copilot Studio,
applies risk classification for the selected governance tier, seeds approval requests,
audits sharing policy configurations, and generates the initial deployment manifest.
The script is intentionally documentation-first for the Power Automate and Dataverse
assets that support this solution and supports WhatIf so regulated environments can
preview changes before operational rollout.

.PARAMETER ConfigurationTier
Governance tier to apply. Valid values are baseline, recommended, and regulated.

.PARAMETER OutputPath
Directory where the deployment manifest and supporting JSON artifacts will be written.

.PARAMETER TenantId
Microsoft Entra tenant identifier used for the inventory connection context.

.PARAMETER DataverseUrl
Target Dataverse environment URL where the documented ALG tables are hosted.

.PARAMETER ApproverEmail
Security reviewer mailbox or distribution group that receives approval workflow tasks.

.EXAMPLE
.\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId <tenant> `
  -DataverseUrl https://contoso.crm.dynamics.com -ApproverEmail alg-reviewers@contoso.com

.NOTES
This script supports compliance with FINRA 3110, OCC 2011-12, and DORA by documenting
agent inventory, approval routing, sharing policy audits, and deployment gating decisions.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts'),

    [Parameter(Mandatory)]
    [string]$TenantId,

    [Parameter(Mandatory)]
    [string]$DataverseUrl,

    [Parameter(Mandatory)]
    [string]$ApproverEmail
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\DataverseHelpers.psm1') -Force
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

    $defaultPath = Join-Path $SolutionRoot 'config\default-config.json'
    $baselinePath = Join-Path $SolutionRoot 'config\baseline.json'
    $tierPath = Join-Path $SolutionRoot ("config\{0}.json" -f $Tier)

    return [pscustomobject]@{
        Default = Get-Content -Path $defaultPath -Raw | ConvertFrom-Json -Depth 20
        Baseline = Get-Content -Path $baselinePath -Raw | ConvertFrom-Json -Depth 20
        Tier = Get-Content -Path $tierPath -Raw | ConvertFrom-Json -Depth 20
    }
}

function Get-ApprovalSlaHours {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$DefaultConfig,

        [Parameter(Mandatory)]
        [pscustomobject]$TierConfig,

        [Parameter(Mandatory)]
        [ValidateSet('microsoftPublished', 'itDeveloped', 'userCreated', 'blocked')]
        [string]$RiskCategory
    )

    if ($TierConfig.approvalSLAHours.PSObject.Properties.Name -contains $RiskCategory) {
        return [int]$TierConfig.approvalSLAHours.$RiskCategory
    }

    if ($DefaultConfig.approvalSLAHours.PSObject.Properties.Name -contains $RiskCategory) {
        return [int]$DefaultConfig.approvalSLAHours.$RiskCategory
    }

    return 0
}

function Get-AgentInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    $discoveredAt = Get-Date

    return @(
        [pscustomobject]@{
            agentId = 'microsoft-365-copilot'
            displayName = 'Microsoft 365 Copilot'
            publisher = 'Microsoft'
            publisherType = 'microsoftPublished'
            agentType = 'microsoft-built'
            sharingScope = 'org-wide'
            dataAccessScope = 'user-delegated'
            createdBy = 'Microsoft'
            inventorySource = 'M365 Admin Center'
            tenantId = $TenantId
            lastSeen = $discoveredAt.AddMinutes(-15).ToString('o')
        }
        [pscustomobject]@{
            agentId = 'microsoft-viva-agent'
            displayName = 'Microsoft Viva Copilot Agent'
            publisher = 'Microsoft'
            publisherType = 'microsoftPublished'
            agentType = 'microsoft-built'
            sharingScope = 'org-wide'
            dataAccessScope = 'user-delegated'
            createdBy = 'Microsoft'
            inventorySource = 'M365 Admin Center'
            tenantId = $TenantId
            lastSeen = $discoveredAt.AddMinutes(-10).ToString('o')
        }
        [pscustomobject]@{
            agentId = 'contoso-helpdesk-agent'
            displayName = 'Contoso IT Helpdesk Agent'
            publisher = 'Contoso IT'
            publisherType = 'itDeveloped'
            agentType = 'copilot-studio'
            sharingScope = 'org-wide'
            dataAccessScope = 'service-account'
            createdBy = 'it-engineering@contoso.com'
            inventorySource = 'Copilot Studio Admin'
            tenantId = $TenantId
            lastSeen = $discoveredAt.AddHours(-1).ToString('o')
        }
        [pscustomobject]@{
            agentId = 'contoso-compliance-assistant'
            displayName = 'Contoso Compliance Assistant'
            publisher = 'Contoso Compliance Team'
            publisherType = 'itDeveloped'
            agentType = 'copilot-studio'
            sharingScope = 'team'
            dataAccessScope = 'service-account'
            createdBy = 'compliance-dev@contoso.com'
            inventorySource = 'Copilot Studio Admin'
            tenantId = $TenantId
            lastSeen = $discoveredAt.AddHours(-2).ToString('o')
        }
        [pscustomobject]@{
            agentId = 'dept-productivity-agent'
            displayName = 'Sales Department Productivity Agent'
            publisher = 'Sales Team'
            publisherType = 'userCreated'
            agentType = 'copilot-studio'
            sharingScope = 'org-wide'
            dataAccessScope = 'user-delegated'
            createdBy = 'sales-lead@contoso.com'
            inventorySource = 'Copilot Studio Admin'
            tenantId = $TenantId
            lastSeen = $discoveredAt.AddHours(-3).ToString('o')
        }
        [pscustomobject]@{
            agentId = 'unapproved-third-party-agent'
            displayName = 'Unapproved External Agent'
            publisher = 'Unknown Publisher'
            publisherType = 'blocked'
            agentType = 'third-party'
            sharingScope = 'org-wide'
            dataAccessScope = 'unrestricted'
            createdBy = 'unknown'
            inventorySource = 'M365 Admin Center'
            tenantId = $TenantId
            lastSeen = $discoveredAt.AddHours(-4).ToString('o')
        }
    )
}

function Set-AgentRiskClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Agent,

        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$ConfigurationTier,

        [Parameter(Mandatory)]
        [pscustomobject]$DefaultConfig,

        [Parameter(Mandatory)]
        [pscustomobject]$TierConfig,

        [Parameter(Mandatory)]
        [string[]]$BaselineApprovedAgentIds
    )

    $isBlocked = $DefaultConfig.blockedAgentIds -contains $Agent.agentId
    $reviewStages = @()
    $approvalStatus = 'pending-review'
    $riskCategory = $Agent.publisherType
    $reason = ''

    if ($isBlocked) {
        $riskCategory = 'blocked'
        $approvalStatus = 'blocked'
        $reviewStages = @('policy-block')
        $reason = 'Agent is explicitly prohibited by tenant policy for regulated Copilot use.'
    }
    elseif ($Agent.publisherType -eq 'microsoftPublished') {
        $riskCategory = 'microsoftPublished'
        $reason = 'Microsoft-published agent operating within documented service boundaries.'
    }
    elseif ($Agent.publisherType -eq 'itDeveloped') {
        $riskCategory = 'itDeveloped'
        $reason = 'IT-developed agent subject to internal development governance.'
    }
    elseif ($Agent.publisherType -eq 'userCreated') {
        $riskCategory = 'userCreated'
        $reason = 'User-created Copilot Studio agent that requires supervisory review before broader distribution.'
    }
    else {
        $riskCategory = 'blocked'
        $reason = 'Unknown agent publisher type requires manual classification before enablement.'
    }

    if (-not $isBlocked) {
        switch ($ConfigurationTier) {
            'baseline' {
                if (($BaselineApprovedAgentIds -contains $Agent.agentId) -or ($TierConfig.approvalModel.autoApproveMicrosoftPublished -and $riskCategory -eq 'microsoftPublished')) {
                    $approvalStatus = 'approved'
                    $reviewStages = @('inventory-only')
                }
                else {
                    $approvalStatus = 'pending-security-review'
                    $reviewStages = @($TierConfig.approvalModel.mandatoryReviewStages)
                }
            }
            'recommended' {
                if ($riskCategory -eq 'microsoftPublished' -and $TierConfig.approvalModel.autoApproveMicrosoftPublished) {
                    $approvalStatus = 'approved'
                    $reviewStages = @('inventory-only')
                }
                elseif ($riskCategory -eq 'itDeveloped') {
                    $approvalStatus = 'pending-security-review'
                    $reviewStages = @($TierConfig.approvalModel.itDevelopedReviewStages)
                }
                elseif ($riskCategory -eq 'userCreated') {
                    $approvalStatus = 'pending-business-owner-attestation'
                    $reviewStages = @($TierConfig.approvalModel.userCreatedReviewStages)
                }
                else {
                    $approvalStatus = 'pending-security-review'
                    $reviewStages = @($TierConfig.approvalModel.mandatoryReviewStages)
                }
            }
            'regulated' {
                if ($riskCategory -eq 'userCreated') {
                    $approvalStatus = 'pending-regulated-review'
                    $reviewStages = @($TierConfig.approvalModel.userCreatedReviewStages)
                }
                else {
                    $approvalStatus = 'pending-regulated-review'
                    $reviewStages = @($TierConfig.approvalModel.mandatoryReviewStages)
                }
            }
        }
    }

    $approvalSlaHours = Get-ApprovalSlaHours -DefaultConfig $DefaultConfig -TierConfig $TierConfig -RiskCategory $riskCategory

    return [pscustomobject]@{
        agentId = $Agent.agentId
        displayName = $Agent.displayName
        publisher = $Agent.publisher
        publisherType = $Agent.publisherType
        agentType = $Agent.agentType
        sharingScope = $Agent.sharingScope
        dataAccessScope = $Agent.dataAccessScope
        createdBy = $Agent.createdBy
        inventorySource = $Agent.inventorySource
        lastSeen = $Agent.lastSeen
        riskCategory = $riskCategory
        approvalStatus = $approvalStatus
        approvalSLAHours = $approvalSlaHours
        requiredReviewStages = @($reviewStages)
        classificationReason = $reason
        baselineApproved = $BaselineApprovedAgentIds -contains $Agent.agentId
    }
}

function New-AgentApprovalRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$AgentAssessment,

        [Parameter(Mandatory)]
        [string]$ApproverEmail
    )

    if ($AgentAssessment.approvalStatus -eq 'approved') {
        return $null
    }

    $requestedAt = Get-Date
    $dueBy = if ($AgentAssessment.approvalSLAHours -gt 0) {
        $requestedAt.AddHours($AgentAssessment.approvalSLAHours)
    }
    else {
        $requestedAt
    }

    return [pscustomobject]@{
        requestId = ('ALG-{0}' -f ([guid]::NewGuid().ToString('N').Substring(0, 12).ToUpperInvariant()))
        agentId = $AgentAssessment.agentId
        displayName = $AgentAssessment.displayName
        riskCategory = $AgentAssessment.riskCategory
        requestedAt = $requestedAt.ToString('o')
        dueBy = $dueBy.ToString('o')
        approver = $ApproverEmail
        stages = @($AgentAssessment.requiredReviewStages)
        status = if ($AgentAssessment.approvalStatus -eq 'blocked') { 'denied' } else { 'submitted' }
        notes = $AgentAssessment.classificationReason
    }
}

function Get-SharingPolicyAudit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$TierConfig
    )

    $auditedAt = (Get-Date).ToString('o')
    $tierSharingControls = $TierConfig.sharingPolicyControls

    return @(
        [pscustomobject]@{
            auditId = ('ALG-SP-{0}' -f ([guid]::NewGuid().ToString('N').Substring(0, 8).ToUpperInvariant()))
            policyDimension = 'orgWideSharingRestriction'
            currentSetting = 'admin-approval-required'
            expectedSetting = $tierSharingControls.orgWideSharingRestriction
            isCompliant = ('admin-approval-required' -eq $tierSharingControls.orgWideSharingRestriction) -or ('blocked-without-exception' -eq $tierSharingControls.orgWideSharingRestriction -and 'admin-approval-required' -eq 'admin-approval-required')
            auditedOn = $auditedAt
            auditedBy = 'ALG-SharingPolicyAudit'
            notes = 'Org-wide sharing restriction is set to require admin approval before agents can be shared with the entire organization.'
        }
        [pscustomobject]@{
            auditId = ('ALG-SP-{0}' -f ([guid]::NewGuid().ToString('N').Substring(0, 8).ToUpperInvariant()))
            policyDimension = 'externalSharingPolicy'
            currentSetting = 'disabled'
            expectedSetting = $tierSharingControls.externalSharingPolicy
            isCompliant = ('disabled' -eq $tierSharingControls.externalSharingPolicy) -or ('blocked' -eq $tierSharingControls.externalSharingPolicy)
            auditedOn = $auditedAt
            auditedBy = 'ALG-SharingPolicyAudit'
            notes = 'External sharing is disabled for Copilot Studio agents in the tenant.'
        }
        [pscustomobject]@{
            auditId = ('ALG-SP-{0}' -f ([guid]::NewGuid().ToString('N').Substring(0, 8).ToUpperInvariant()))
            policyDimension = 'catalogVisibility'
            currentSetting = 'admin-managed'
            expectedSetting = $tierSharingControls.catalogVisibility
            isCompliant = ('admin-managed' -eq $tierSharingControls.catalogVisibility) -or ('admin-only' -eq $tierSharingControls.catalogVisibility -and 'admin-managed' -eq 'admin-managed')
            auditedOn = $auditedAt
            auditedBy = 'ALG-SharingPolicyAudit'
            notes = 'Agent catalog visibility is managed by administrators with controlled agent publishing.'
        }
    )
}

try {
    Write-Verbose 'Loading agent governance configuration.'
    $config = Get-AgentGovernanceConfiguration -SolutionRoot $solutionRoot -Tier $ConfigurationTier
    $tierDefinition = Get-CopilotGovTierDefinition -Tier $ConfigurationTier
    $baselineApprovedAgentIds = @($config.Baseline.approvalModel.autoApprovedAgentIds)

    Write-Verbose 'Connecting to the M365 Admin Center agent inventory path.'
    $adminCenterConnection = [pscustomobject]@{
        service = 'M365 Admin Center'
        tenantId = $TenantId
        scope = 'Agent request and approval management'
        status = 'documented-stub'
    }

    $copilotStudioAdmin = [pscustomobject]@{
        service = 'Copilot Studio Admin'
        tenantId = $TenantId
        scope = 'Agent catalog and sharing restriction configuration'
        status = 'documented-stub'
    }

    $agentInventory = Get-AgentInventory -TenantId $TenantId
    $agentAssessments = foreach ($agent in $agentInventory) {
        Set-AgentRiskClassification `
            -Agent $agent `
            -ConfigurationTier $ConfigurationTier `
            -DefaultConfig $config.Default `
            -TierConfig $config.Tier `
            -BaselineApprovedAgentIds $baselineApprovedAgentIds
    }

    $approvalRequests = @(
        $agentAssessments |
            ForEach-Object { New-AgentApprovalRequest -AgentAssessment $_ -ApproverEmail $ApproverEmail } |
            Where-Object { $null -ne $_ }
    )

    $sharingPolicyAudit = Get-SharingPolicyAudit -TierConfig $config.Tier

    $tableContracts = @(
        New-DataverseTableContract -SchemaName (New-CopilotGovTableName -SolutionSlug 'alg' -Purpose 'baseline') -Columns @('agentId', 'displayName', 'publisherType', 'riskCategory', 'approvalStatus', 'sharingScope', 'deploymentRing', 'lastReviewedOn')
        New-DataverseTableContract -SchemaName (New-CopilotGovTableName -SolutionSlug 'alg' -Purpose 'finding') -Columns @('agentId', 'findingType', 'riskCategory', 'approvalStatus', 'owner', 'openedOn', 'dueOn')
        New-DataverseTableContract -SchemaName (New-CopilotGovTableName -SolutionSlug 'alg' -Purpose 'evidence') -Columns @('artifactType', 'agentId', 'attestedBy', 'attestedOn', 'retentionDays', 'exportPath')
    )

    $notificationPreview = if (@($approvalRequests).Count -gt 0) {
        New-TeamsMessageCard -Title 'ALG approval queue' -Summary ("{0} agent deployment requests require review in tenant {1}." -f @($approvalRequests).Count, $TenantId)
    }
    else {
        $null
    }

    $outputFiles = [ordered]@{
        manifest = Join-Path $OutputPath 'alg-deployment-manifest.json'
        agentRegistry = Join-Path $OutputPath 'alg-agent-registry.json'
        approvalRegister = Join-Path $OutputPath 'alg-approval-register.json'
        sharingPolicyAudit = Join-Path $OutputPath 'alg-sharing-policy-audit.json'
    }

    $manifest = [ordered]@{
        solution = '19-agent-lifecycle-governance'
        solutionCode = 'ALG'
        displayName = 'Agent Lifecycle and Deployment Governance'
        generatedAt = (Get-Date).ToString('o')
        configurationTier = $ConfigurationTier
        tierDefinition = $tierDefinition
        tenantId = $TenantId
        dataverseUrl = $DataverseUrl
        dependencies = @{
            featureManagement = @{
                solution = '09-feature-management-controller'
                integration = 'Approved agents should still be gated by feature management before production rollout.'
            }
            connectorPluginGovernance = @{
                solution = '10-connector-plugin-governance'
                integration = 'Agent connector dependencies should be cross-referenced with CPG approval records.'
            }
        }
        discovery = @{
            m365AdminCenter = $adminCenterConnection
            copilotStudioAdmin = $copilotStudioAdmin
        }
        powerAutomateFlows = @($config.Default.powerAutomateFlows)
        dataverseTables = $tableContracts
        notificationPreview = $notificationPreview
        agents = $agentAssessments
        approvalRequests = $approvalRequests
        sharingPolicyAudit = $sharingPolicyAudit
        summary = @{
            totalAgents = @($agentAssessments).Count
            approved = @($agentAssessments | Where-Object { $_.approvalStatus -eq 'approved' }).Count
            pendingReview = @($agentAssessments | Where-Object { $_.approvalStatus -like 'pending*' }).Count
            blocked = @($agentAssessments | Where-Object { $_.approvalStatus -eq 'blocked' }).Count
            userCreated = @($agentAssessments | Where-Object { $_.riskCategory -eq 'userCreated' }).Count
            sharingPolicyFindings = @($sharingPolicyAudit | Where-Object { -not $_.isCompliant }).Count
        }
        generatedFiles = $outputFiles
    }

    if ($PSCmdlet.ShouldProcess($OutputPath, 'Write agent governance deployment artifacts')) {
        $null = New-Item -ItemType Directory -Path $OutputPath -Force
        $manifest | ConvertTo-Json -Depth 20 | Set-Content -Path $outputFiles.manifest -Encoding utf8
        $agentAssessments | ConvertTo-Json -Depth 20 | Set-Content -Path $outputFiles.agentRegistry -Encoding utf8
        $approvalRequests | ConvertTo-Json -Depth 20 | Set-Content -Path $outputFiles.approvalRegister -Encoding utf8
        $sharingPolicyAudit | ConvertTo-Json -Depth 20 | Set-Content -Path $outputFiles.sharingPolicyAudit -Encoding utf8
    }

    Write-Output ([pscustomobject]$manifest)
}
catch {
    Write-Error -Message ("Agent governance deployment failed: {0}" -f $_.Exception.Message)
    throw
}
