<#
.SYNOPSIS
Builds a deployment manifest for the License Governance and ROI Tracker solution.

.DESCRIPTION
Loads tier-specific settings for solution 08-license-governance-roi, validates the planned
Microsoft Graph connectivity requirements, prepares a license inventory stub, and documents
the Dataverse and Power BI baseline needed for deployment. The resulting manifest supports
compliance-oriented deployment reviews for financial-services environments.

.PARAMETER ConfigurationTier
Governance tier to deploy. Valid values are baseline, recommended, and regulated.

.PARAMETER OutputPath
Directory where the deployment manifest JSON file will be written.

.PARAMETER TenantId
Microsoft Entra tenant identifier used to build the Graph connectivity plan.

.PARAMETER Environment
Target deployment environment label. The default value is NonProd.

.EXAMPLE
PS> .\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId '00000000-0000-0000-0000-000000000000' -OutputPath '.\artifacts\deploy'
Creates a recommended-tier deployment manifest for a non-production environment.

.EXAMPLE
PS> .\Deploy-Solution.ps1 -ConfigurationTier regulated -TenantId '00000000-0000-0000-0000-000000000000' -Environment Prod -WhatIf
Displays the regulated deployment plan without writing the manifest to disk.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts'),

    [Parameter()]
    [string]$TenantId,

    [Parameter()]
    [ValidateSet('NonProd', 'Prod')]
    [string]$Environment = 'NonProd'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\GraphAuth.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\DataverseHelpers.psm1') -Force

. (Join-Path $PSScriptRoot 'SolutionConfig.ps1')

function Test-GraphConnectivity {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$TenantId,

        [Parameter(Mandatory)]
        [string[]]$Scopes
    )

    $context = if ($TenantId) {
        New-CopilotGovGraphContext -TenantId $TenantId -Scopes $Scopes
    }
    else {
        [pscustomobject]@{
            TenantId = 'tenant-id-not-specified'
            Scopes = $Scopes
            ConnectedAt = (Get-Date).ToString('o')
        }
    }

    return [pscustomobject]@{
        status = if ($TenantId) { 'validated-for-planning' } else { 'planned' }
        scopes = $Scopes
        endpoints = @(
            '/v1.0/users?$select=id,displayName,userPrincipalName,department,assignedLicenses,accountEnabled'
            '/v1.0/subscribedSkus'
            "/v1.0/copilot/reports/getMicrosoft365CopilotUsageUserDetail(period='D30')"
            "/v1.0/copilot/reports/getMicrosoft365CopilotUserCountSummary(period='D30')"
        )
        graphContext = $context
        notes = 'This script validates the required connectivity plan. Replace the stub with live Connect-MgGraph or equivalent tenant-auth logic during implementation.'
    }
}

function Get-LicenseInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,

        [Parameter(Mandatory)]
        [psobject]$GraphConnectivity
    )

    $plannedSeats = switch ($Configuration.tier) {
        'regulated' { 250 }
        'recommended' { 180 }
        default { 120 }
    }

    $consumedSeats = switch ($Configuration.tier) {
        'regulated' { 212 }
        'recommended' { 144 }
        default { 82 }
    }

    foreach ($sku in $Configuration.defaults.licenseSkus) {
        [pscustomobject]@{
            skuName = $sku
            totalPurchasedSeats = $plannedSeats
            assignedSeats = $consumedSeats
            availableSeats = ($plannedSeats - $consumedSeats)
            utilizationPct = [math]::Round(($consumedSeats / $plannedSeats) * 100, 2)
            sourceEndpoint = '/v1.0/subscribedSkus'
            graphStatus = $GraphConnectivity.status
            notes = 'Structured deployment stub for Microsoft Graph license inventory collection.'
        }
    }
}

function Set-LicenseGovernanceBaseline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,

        [Parameter(Mandatory)]
        [pscustomobject]$TierDefinition,

        [Parameter(Mandatory)]
        [object[]]$LicenseInventory,

        [Parameter(Mandatory)]
        [string]$Environment
    )

    $baselineTableName = New-CopilotGovTableName -SolutionSlug 'lgr' -Purpose 'baseline'
    $findingTableName = New-CopilotGovTableName -SolutionSlug 'lgr' -Purpose 'finding'
    $evidenceTableName = New-CopilotGovTableName -SolutionSlug 'lgr' -Purpose 'evidence'

    $dataverseContracts = @(
        (New-DataverseTableContract -SchemaName $baselineTableName -Columns @('ConfigurationTier', 'InactivityThresholdDays', 'NotificationMode', 'ReallocationTriggerUtilizationPct', 'ReportingPeriodDays', 'ApprovedBy'))
        (New-DataverseTableContract -SchemaName $findingTableName -Columns @('UserPrincipalName', 'Department', 'LastActivityDate', 'UtilizationPct', 'RiskTier', 'RecommendedAction', 'FindingStatus'))
        (New-DataverseTableContract -SchemaName $evidenceTableName -Columns @('EvidenceType', 'PackagePath', 'Sha256Hash', 'PeriodStart', 'PeriodEnd', 'ExportedAt', 'Reviewer'))
    )

    return [pscustomobject]@{
        environment = $Environment
        tier = $TierDefinition.Label
        baselineSettings = [ordered]@{
            inactivityThresholdDays = $Configuration.inactivityThresholdDays
            notificationMode = $Configuration.notificationMode
            reallocationTriggerUtilizationPct = $Configuration.reallocationTriggerUtilizationPct
            vivaInsightsEnabled = $Configuration.vivaInsightsEnabled
            evidenceRetentionDays = $Configuration.evidenceRetentionDays
            auditTrailMode = $Configuration.auditTrailMode
        }
        dataverseTables = $dataverseContracts
        powerBiDataset = [ordered]@{
            documentedAssetOnly = $true
            workspaceRequirement = 'Customer-managed Power BI workspace'
            logicalTables = @(
                'LicenseInventorySnapshot'
                'CopilotUsageDetail'
                'VivaImpactSignals'
                'RiskTierAssignments'
                'ReallocationRecommendations'
            )
            measures = @(
                'UtilizationPct'
                'InactiveSeatCount'
                'EstimatedRecoverableSpendUsd'
                'ROISignalCoveragePct'
                'ProtectedSeatCount'
            )
        }
        reviewWorkflow = [ordered]@{
            dependency = '11-risk-tiered-rollout'
            escalationRule = 'Protected and high-risk users require manual review before reallocation.'
            notificationChannel = $Configuration.defaults.notificationChannel
        }
        inventorySummary = $LicenseInventory
    }
}

try {
    $configuration = Get-SolutionConfiguration -Tier $ConfigurationTier
    $tierDefinition = Get-CopilotGovTierDefinition -Tier $ConfigurationTier
    $graphScopes = @('Reports.Read.All', 'LicenseAssignment.Read.All', 'User.Read.All')
    $graphConnectivity = Test-GraphConnectivity -TenantId $TenantId -Scopes $graphScopes
    $licenseInventory = @(Get-LicenseInventory -Configuration $configuration -GraphConnectivity $graphConnectivity)
    $baseline = Set-LicenseGovernanceBaseline -Configuration $configuration -TierDefinition $tierDefinition -LicenseInventory $licenseInventory -Environment $Environment

    $manifestObject = [pscustomobject][ordered]@{
        solution = '08-license-governance-roi'
        solutionCode = 'LGR'
        displayName = 'License Governance and ROI Tracker'
        version = $configuration.version
        generatedAt = (Get-Date).ToString('o')
        tenantId = if ($TenantId) { $TenantId } else { 'current-context' }
        configurationTier = $ConfigurationTier
        environment = $Environment
        controls = $configuration.controls
        dependencies = @('11-risk-tiered-rollout')
        graphConnectivity = $graphConnectivity
        baseline = $baseline
    }

    if ($PSCmdlet.ShouldProcess($manifestObject.displayName, 'Write deployment manifest JSON')) {
        $null = New-Item -ItemType Directory -Path $OutputPath -Force
        $resolvedOutputPath = (Resolve-Path $OutputPath).Path
        $manifestPath = Join-Path $resolvedOutputPath '08-license-governance-roi-deployment.json'
        $manifestObject | ConvertTo-Json -Depth 8 | Set-Content -Path $manifestPath -Encoding utf8
        $manifestObject | Add-Member -NotePropertyName manifestPath -NotePropertyValue $manifestPath -Force
    }
    else {
        $manifestObject | Add-Member -NotePropertyName manifestPath -NotePropertyValue $null -Force
    }

    Write-Output $manifestObject
}
catch {
    $message = "Deployment planning failed for 08-license-governance-roi: {0}" -f $_.Exception.Message
    Write-Error $message
    throw
}
