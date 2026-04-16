<#
.SYNOPSIS
Builds the deployment manifest for Copilot Connector and Plugin Governance.

.DESCRIPTION
Models the Power Platform Admin API inventory path, simulates connector and
plugin enumeration, applies risk classification for the selected governance tier, seeds
approval requests, and generates data-flow attestation records. The script is intentionally
documentation-first for the Power Automate and Dataverse assets that support this solution
and supports WhatIf so regulated environments can preview changes before operational rollout.

.PARAMETER ConfigurationTier
Governance tier to apply. Valid values are baseline, recommended, and regulated.

.PARAMETER OutputPath
Directory where the deployment manifest and supporting JSON artifacts will be written.

.PARAMETER TenantId
Microsoft Entra tenant identifier used for the inventory connection context.

.PARAMETER Environment
Power Platform environment name or environment identifier that hosts the Copilot connectors
and plugins in scope.

.PARAMETER DataverseUrl
Target Dataverse environment URL where the documented CPG tables are hosted.

.PARAMETER ApproverEmail
Security reviewer mailbox or distribution group that receives approval workflow tasks.

.PARAMETER BlockHighRiskConnectors
When supplied, the deployment manifest includes proposed enforcement actions for high-risk
or blocked connectors.

.EXAMPLE
.\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId <tenant> -Environment <env> `
  -DataverseUrl https://contoso.crm.dynamics.com -ApproverEmail cpg-reviewers@contoso.com

.NOTES
This script supports compliance with FINRA 3110, OCC 2011-12, and DORA by documenting
connector inventory, approval routing, and boundary decisions.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts'),

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$')]
    [string]$TenantId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Environment,

    [Parameter(Mandatory)]
    [ValidatePattern('^https://[\w\-\.]+\.dynamics\.com/?$')]
    [string]$DataverseUrl,

    [Parameter(Mandatory)]
    [ValidatePattern('^[^@\s]+@[^@\s]+\.[^@\s]+$')]
    [string]$ApproverEmail,

    [Parameter()]
    [switch]$BlockHighRiskConnectors
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\DataverseHelpers.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\TeamsNotification.psm1') -Force

function Get-ConnectorGovernanceConfiguration {
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
        [ValidateSet('low', 'medium', 'high', 'blocked')]
        [string]$RiskLevel
    )

    if ($TierConfig.approvalSLAHours.PSObject.Properties.Name -contains $RiskLevel) {
        return [int]$TierConfig.approvalSLAHours.$RiskLevel
    }

    if ($DefaultConfig.approvalSLAHours.PSObject.Properties.Name -contains $RiskLevel) {
        return [int]$DefaultConfig.approvalSLAHours.$RiskLevel
    }

    return 0
}

function Get-ConnectorInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter(Mandatory)]
        [string]$Environment
    )

    $discoveredAt = Get-Date

    return @(
        [pscustomobject]@{
            connectorId = 'shared_sharepointonline'
            displayName = 'SharePoint'
            publisher = 'Microsoft'
            publisherType = 'microsoft'
            certification = 'Microsoft'
            assetType = 'connector'
            dataFlowBoundaries = @('internal-m365')
            allowsExternalEgress = $false
            supportsFinancialData = $false
            requestedBusinessOwner = 'Knowledge Management'
            inventorySource = 'Power Platform Admin API'
            environment = $Environment
            tenantId = $TenantId
            lastSeen = $discoveredAt.AddMinutes(-15).ToString('o')
        }
        [pscustomobject]@{
            connectorId = 'shared_teams'
            displayName = 'Microsoft Teams'
            publisher = 'Microsoft'
            publisherType = 'microsoft'
            certification = 'Microsoft'
            assetType = 'connector'
            dataFlowBoundaries = @('internal-m365')
            allowsExternalEgress = $false
            supportsFinancialData = $false
            requestedBusinessOwner = 'Employee Collaboration'
            inventorySource = 'Power Platform Admin API'
            environment = $Environment
            tenantId = $TenantId
            lastSeen = $discoveredAt.AddMinutes(-10).ToString('o')
        }
        [pscustomobject]@{
            connectorId = 'shared_salesforce'
            displayName = 'Salesforce'
            publisher = 'Salesforce'
            publisherType = 'third-party'
            certification = 'Certified'
            assetType = 'connector'
            dataFlowBoundaries = @('certified-third-party')
            allowsExternalEgress = $true
            supportsFinancialData = $false
            requestedBusinessOwner = 'Client Operations'
            inventorySource = 'Power Platform Admin API'
            environment = $Environment
            tenantId = $TenantId
            lastSeen = $discoveredAt.AddHours(-1).ToString('o')
        }
        [pscustomobject]@{
            connectorId = 'shared_servicenow'
            displayName = 'ServiceNow'
            publisher = 'ServiceNow'
            publisherType = 'third-party'
            certification = 'Certified'
            assetType = 'plugin'
            dataFlowBoundaries = @('certified-third-party')
            allowsExternalEgress = $true
            supportsFinancialData = $false
            requestedBusinessOwner = 'Enterprise Service Desk'
            inventorySource = 'Microsoft Graph'
            environment = $Environment
            tenantId = $TenantId
            lastSeen = $discoveredAt.AddHours(-2).ToString('o')
        }
        [pscustomobject]@{
            connectorId = 'custom_corebanking'
            displayName = 'Core Banking Custom Connector'
            publisher = 'Contoso Capital Markets'
            publisherType = 'custom'
            certification = 'Uncertified'
            assetType = 'connector'
            dataFlowBoundaries = @('regulated-financial-systems')
            allowsExternalEgress = $true
            supportsFinancialData = $true
            requestedBusinessOwner = 'Treasury Operations'
            inventorySource = 'Power Platform Admin API'
            environment = $Environment
            tenantId = $TenantId
            lastSeen = $discoveredAt.AddHours(-3).ToString('o')
        }
        [pscustomobject]@{
            connectorId = 'shared_dropbox'
            displayName = 'Dropbox Business'
            publisher = 'Dropbox'
            publisherType = 'third-party'
            certification = 'Certified'
            assetType = 'plugin'
            dataFlowBoundaries = @('personal-or-public-services')
            allowsExternalEgress = $true
            supportsFinancialData = $false
            requestedBusinessOwner = 'Unknown'
            inventorySource = 'Microsoft Graph'
            environment = $Environment
            tenantId = $TenantId
            lastSeen = $discoveredAt.AddHours(-4).ToString('o')
        }
    )
}

function Set-ConnectorRiskClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Connector,

        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$ConfigurationTier,

        [Parameter(Mandatory)]
        [pscustomobject]$DefaultConfig,

        [Parameter(Mandatory)]
        [pscustomobject]$TierConfig,

        [Parameter(Mandatory)]
        [string[]]$BaselineApprovedConnectorIds
    )

    $isBlocked = $DefaultConfig.blockedConnectorIds -contains $Connector.connectorId
    $reviewStages = @()
    $approvalStatus = 'pending-review'
    $riskLevel = 'high'
    $reason = ''

    if ($isBlocked) {
        $riskLevel = 'blocked'
        $approvalStatus = 'blocked'
        $reviewStages = @('policy-block')
        $reason = 'Connector is explicitly prohibited by tenant policy for regulated Copilot use.'
    }
    elseif ($Connector.publisherType -eq 'microsoft' -and -not $Connector.allowsExternalEgress) {
        $riskLevel = 'low'
        $reason = 'Microsoft-built connector without external data egress.'
    }
    elseif ($Connector.publisherType -eq 'third-party' -and $Connector.certification -eq 'Certified' -and -not $Connector.supportsFinancialData) {
        $riskLevel = 'medium'
        $reason = 'Certified third-party connector with limited external data movement.'
    }
    else {
        $riskLevel = 'high'
        $reason = 'Custom or cross-boundary integration that reaches regulated or higher-risk data paths.'
    }

    if (-not $isBlocked) {
        switch ($ConfigurationTier) {
            'baseline' {
                if (($BaselineApprovedConnectorIds -contains $Connector.connectorId) -or ($TierConfig.approvalModel.autoApproveMicrosoftBuilt -and $riskLevel -eq 'low')) {
                    $approvalStatus = 'approved'
                    $reviewStages = @('inventory-only')
                }
                else {
                    $approvalStatus = 'pending-security-review'
                    $reviewStages = @($TierConfig.approvalModel.mandatoryReviewStages)
                }
            }
            'recommended' {
                if ($riskLevel -eq 'low' -and $TierConfig.approvalModel.autoApproveLowRisk) {
                    $approvalStatus = 'approved'
                    $reviewStages = @('inventory-only')
                }
                elseif ($riskLevel -eq 'medium') {
                    $approvalStatus = 'pending-security-review'
                    $reviewStages = @($TierConfig.approvalModel.mediumRiskReviewStages)
                }
                else {
                    $approvalStatus = 'pending-ciso-dlp-review'
                    $reviewStages = @($TierConfig.approvalModel.highRiskReviewStages)
                }
            }
            'regulated' {
                if ($riskLevel -eq 'high') {
                    $approvalStatus = 'pending-regulated-review'
                    $reviewStages = @($TierConfig.approvalModel.highRiskReviewStages)
                }
                else {
                    $approvalStatus = 'pending-regulated-review'
                    $reviewStages = @($TierConfig.approvalModel.mandatoryReviewStages)
                }
            }
        }
    }

    $requiresDataFlowAttestation = (@($Connector.dataFlowBoundaries | Where-Object { $_ -ne 'internal-m365' }).Count -gt 0) -or $Connector.supportsFinancialData
    $approvalSlaHours = Get-ApprovalSlaHours -DefaultConfig $DefaultConfig -TierConfig $TierConfig -RiskLevel $riskLevel

    return [pscustomobject]@{
        connectorId = $Connector.connectorId
        displayName = $Connector.displayName
        publisher = $Connector.publisher
        publisherType = $Connector.publisherType
        certification = $Connector.certification
        assetType = $Connector.assetType
        dataFlowBoundaries = @($Connector.dataFlowBoundaries)
        allowsExternalEgress = $Connector.allowsExternalEgress
        supportsFinancialData = $Connector.supportsFinancialData
        requestedBusinessOwner = $Connector.requestedBusinessOwner
        inventorySource = $Connector.inventorySource
        lastSeen = $Connector.lastSeen
        riskLevel = $riskLevel
        approvalStatus = $approvalStatus
        approvalSLAHours = $approvalSlaHours
        requiredReviewStages = @($reviewStages)
        classificationReason = $reason
        baselineApproved = $BaselineApprovedConnectorIds -contains $Connector.connectorId
        requiresDataFlowAttestation = $requiresDataFlowAttestation
    }
}

function New-ConnectorApprovalRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$ConnectorAssessment,

        [Parameter(Mandatory)]
        [string]$ApproverEmail
    )

    if ($ConnectorAssessment.approvalStatus -eq 'approved') {
        return $null
    }

    $requestedAt = Get-Date
    $dueBy = if ($ConnectorAssessment.approvalSLAHours -gt 0) {
        $requestedAt.AddHours($ConnectorAssessment.approvalSLAHours)
    }
    else {
        $requestedAt
    }

    return [pscustomobject]@{
        requestId = ('CPG-{0}' -f ([guid]::NewGuid().ToString('N').Substring(0, 12).ToUpperInvariant()))
        connectorId = $ConnectorAssessment.connectorId
        displayName = $ConnectorAssessment.displayName
        riskLevel = $ConnectorAssessment.riskLevel
        requestedAt = $requestedAt.ToString('o')
        dueBy = $dueBy.ToString('o')
        approver = $ApproverEmail
        stages = @($ConnectorAssessment.requiredReviewStages)
        status = if ($ConnectorAssessment.approvalStatus -eq 'blocked') { 'denied' } else { 'submitted' }
        dataFlowAttestationRequired = $ConnectorAssessment.requiresDataFlowAttestation
        notes = $ConnectorAssessment.classificationReason
    }
}

try {
    Write-Verbose 'Loading connector governance configuration.'
    $config = Get-ConnectorGovernanceConfiguration -SolutionRoot $solutionRoot -Tier $ConfigurationTier
    $tierDefinition = Get-CopilotGovTierDefinition -Tier $ConfigurationTier
    $baselineApprovedConnectorIds = @($config.Baseline.approvalModel.autoApprovedConnectorIds)

    Write-Verbose 'Connecting to the Power Platform Admin API inventory path.'
    $adminApiConnection = [pscustomobject]@{
        service = 'Power Platform Admin API'
        tenantId = $TenantId
        environment = $Environment
        status = 'documented-stub'
    }

    $graphInventory = [pscustomobject]@{
        service = 'Microsoft Graph'
        tenantId = $TenantId
        scope = 'App registrations and plugin inventory'
        status = 'documented-stub'
    }

    $connectorInventory = Get-ConnectorInventory -TenantId $TenantId -Environment $Environment
    $connectorAssessments = @(foreach ($connector in $connectorInventory) {
        Set-ConnectorRiskClassification `
            -Connector $connector `
            -ConfigurationTier $ConfigurationTier `
            -DefaultConfig $config.Default `
            -TierConfig $config.Tier `
            -BaselineApprovedConnectorIds $baselineApprovedConnectorIds
    })

    $approvalRequests = @(
        $connectorAssessments |
            ForEach-Object { New-ConnectorApprovalRequest -ConnectorAssessment $_ -ApproverEmail $ApproverEmail } |
            Where-Object { $null -ne $_ }
    )

    $dataFlowAttestations = @(foreach ($assessment in $connectorAssessments | Where-Object { $_.requiresDataFlowAttestation }) {
        [pscustomobject]@{
            attestationId = ('ATTEST-{0}' -f ([guid]::NewGuid().ToString('N').Substring(0, 10).ToUpperInvariant()))
            connectorId = $assessment.connectorId
            displayName = $assessment.displayName
            sourceBoundary = 'copilot-request-plane'
            destinationBoundary = ($assessment.dataFlowBoundaries -join ',')
            businessJustification = 'Documented business justification is required before production enablement.'
            reviewedBy = $ApproverEmail
            attestedOn = (Get-Date).ToString('o')
            expirationDate = if ($ConfigurationTier -eq 'regulated') { (Get-Date).AddDays(365).ToString('o') } else { (Get-Date).AddDays(180).ToString('o') }
            status = if ($assessment.approvalStatus -eq 'approved') { 'approved' } elseif ($assessment.approvalStatus -eq 'blocked') { 'exception' } else { 'pending' }
        }
    })

    $proposedBlocks = @()
    if ($BlockHighRiskConnectors.IsPresent) {
        foreach ($assessment in $connectorAssessments | Where-Object { $_.riskLevel -in @('high', 'blocked') }) {
            if ($PSCmdlet.ShouldProcess($assessment.displayName, 'Queue high-risk connector block action')) {
                $proposedBlocks += [pscustomobject]@{
                    connectorId = $assessment.connectorId
                    displayName = $assessment.displayName
                    action = 'proposed-block'
                    reason = $assessment.classificationReason
                }
            }
        }
    }

    $tableContracts = @(
        New-DataverseTableContract -SchemaName (New-CopilotGovTableName -SolutionSlug 'cpg' -Purpose 'baseline') -Columns @('connectorId', 'displayName', 'publisher', 'riskLevel', 'approvalStatus', 'dataFlowBoundaries', 'lastReviewedOn')
        New-DataverseTableContract -SchemaName (New-CopilotGovTableName -SolutionSlug 'cpg' -Purpose 'finding') -Columns @('connectorId', 'findingType', 'riskLevel', 'remediationStatus', 'owner', 'openedOn', 'dueOn')
        New-DataverseTableContract -SchemaName (New-CopilotGovTableName -SolutionSlug 'cpg' -Purpose 'evidence') -Columns @('artifactType', 'connectorId', 'attestedBy', 'attestedOn', 'retentionDays', 'exportPath')
    )

    $notificationPreview = if (@($approvalRequests).Count -gt 0) {
        New-TeamsMessageCard -Title 'CPG approval queue' -Summary ("{0} connector or plugin requests require review in environment {1}." -f @($approvalRequests).Count, $Environment)
    }
    else {
        $null
    }

    $outputFiles = [ordered]@{
        manifest = Join-Path $OutputPath 'cpg-deployment-manifest.json'
        inventory = Join-Path $OutputPath 'cpg-connector-inventory.json'
        approvalRegister = Join-Path $OutputPath 'cpg-approval-register.json'
        dataFlowAttestations = Join-Path $OutputPath 'cpg-data-flow-attestations.json'
    }

    $manifest = [ordered]@{
        solution = '10-connector-plugin-governance'
        solutionCode = 'CPG'
        displayName = 'Copilot Connector and Plugin Governance'
        generatedAt = (Get-Date).ToString('o')
        configurationTier = $ConfigurationTier
        tierDefinition = $tierDefinition
        tenantId = $TenantId
        environment = $Environment
        dataverseUrl = $DataverseUrl
        dependency = @{
            solution = '09-feature-management-controller'
            integration = 'Approved connectors should still be gated by feature management before production rollout.'
        }
        discovery = @{
            powerPlatformAdminApi = $adminApiConnection
            microsoftGraph = $graphInventory
        }
        powerAutomateFlows = @($config.Default.powerAutomateFlows)
        dataverseTables = $tableContracts
        notificationPreview = $notificationPreview
        connectors = $connectorAssessments
        approvalRequests = $approvalRequests
        dataFlowAttestations = $dataFlowAttestations
        proposedBlocks = $proposedBlocks
        summary = @{
            totalConnectors = @($connectorAssessments).Count
            approved = @($connectorAssessments | Where-Object { $_.approvalStatus -eq 'approved' }).Count
            pendingReview = @($connectorAssessments | Where-Object { $_.approvalStatus -like 'pending*' }).Count
            blocked = @($connectorAssessments | Where-Object { $_.approvalStatus -eq 'blocked' }).Count
            highRisk = @($connectorAssessments | Where-Object { $_.riskLevel -eq 'high' }).Count
            attestationRequired = @($connectorAssessments | Where-Object { $_.requiresDataFlowAttestation }).Count
        }
        generatedFiles = $outputFiles
    }

    if ($PSCmdlet.ShouldProcess($OutputPath, 'Write connector governance deployment artifacts')) {
        $null = New-Item -ItemType Directory -Path $OutputPath -Force
        $manifest | ConvertTo-Json -Depth 20 | Set-Content -Path $outputFiles.manifest -Encoding utf8
        $connectorAssessments | ConvertTo-Json -Depth 20 | Set-Content -Path $outputFiles.inventory -Encoding utf8
        $approvalRequests | ConvertTo-Json -Depth 20 | Set-Content -Path $outputFiles.approvalRegister -Encoding utf8
        $dataFlowAttestations | ConvertTo-Json -Depth 20 | Set-Content -Path $outputFiles.dataFlowAttestations -Encoding utf8
    }

    Write-Output ([pscustomobject]$manifest)
}
catch {
    Write-Error -Message ("Connector governance deployment failed: {0}" -f $_.Exception.Message)
    throw
}
