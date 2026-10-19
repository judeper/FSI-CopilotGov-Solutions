#Requires -Version 7.0
<#
.SYNOPSIS
Deploys Copilot Interaction Audit Trail Manager configuration.

.DESCRIPTION
Validates Unified Audit Log expectations, generates a retention policy configuration manifest,
prepares Microsoft Purview eDiscovery readiness stubs, and creates a deployment manifest. The script does not
modify retention policies directly; it outputs configuration for Purview portal application.

.PARAMETER ConfigurationTier
Specifies the governance tier to prepare. Valid values are baseline, recommended, and regulated.

.PARAMETER OutputPath
Specifies the folder where deployment manifests are written.

.PARAMETER TenantId
Specifies the Microsoft 365 tenant identifier to annotate in the manifests.

.EXAMPLE
PS> .\Deploy-Solution.ps1 -ConfigurationTier regulated -OutputPath .\artifacts\deployment -TenantId 00000000-0000-0000-0000-000000000000

.NOTES
This script supports compliance with SEC 17a-3, SEC 17a-4, FINRA 4511, CFTC 1.31, and SOX 404
by generating deployment evidence and configuration guidance.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\deployment'),

    [Parameter()]
    [string]$TenantId = 'not-specified'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'AtmShared.psm1') -Force

$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force

$defaultConfig = Read-AtmJsonFile -Path (Join-Path $solutionRoot 'config\default-config.json')
$tierConfig = Read-AtmJsonFile -Path (Join-Path $solutionRoot ("config\{0}.json" -f $ConfigurationTier))

$ualStatusFlag = if ($defaultConfig.defaults.PSObject.Properties.Name -contains 'unifiedAuditLogEnabled') {
    $defaultConfig.defaults.unifiedAuditLogEnabled
} else {
    'check'
}

if ([string]::IsNullOrWhiteSpace([string]$ualStatusFlag)) {
    throw 'The default configuration must declare a Unified Audit Log status check flag.'
}

$regulationNames = [ordered]@{
    SEC_17a4 = 'SEC 17a-4'
    FINRA_4511 = 'FINRA 4511'
    CFTC_1_31 = 'CFTC 1.31'
    SOX_404 = 'SOX 404'
}

$outputFolder = Resolve-AtmOutputPath -Path $OutputPath
$tierDefinition = Get-CopilotGovTierDefinition -Tier $ConfigurationTier
$timestamp = (Get-Date).ToString('o')

$retentionPolicies = foreach ($property in $defaultConfig.defaults.retentionPeriods.byRegulation.PSObject.Properties) {
    $regKey = $property.Name
    $minimumDays = [int]$property.Value
    $configuredDays = [int]$tierConfig.retentionPeriods.byRegulation.$regKey

    if ($configuredDays -lt $minimumDays) {
        Write-Warning ("Tier '{0}' retention for {1} is {2} days, below the {3}-day regulatory minimum." -f $ConfigurationTier, $regKey, $configuredDays, $minimumDays)
    }

    [ordered]@{
        policyName = "ATM-$ConfigurationTier-$regKey"
        regulation = $regulationNames[$regKey]
        requiredMinimumDays = $minimumDays
        configuredDays = $configuredDays
        meetsMinimum = ($configuredDays -ge $minimumDays)
        workloads = @('Exchange', 'SharePoint', 'Teams', 'Microsoft Copilot experiences')
        targetArtifacts = @('Copilot user prompts and responses', 'Exchange email', 'SharePoint files', 'Teams chat and channel messages')
        retentionLabelRequired = [bool]$tierConfig.retentionLabelRequired
        policyApplication = 'Illustrative content retention guidance, not audit log retention or evidence of tenant configuration. Review separate policies by location in Microsoft Purview. Microsoft Copilot experiences use New-AppRetentionCompliancePolicy, Set-AppRetentionCompliancePolicy, New-AppRetentionComplianceRule, and Set-AppRetentionComplianceRule. Exchange mailboxes and SharePoint sites use New-RetentionCompliancePolicy, Set-RetentionCompliancePolicy, New-RetentionComplianceRule, and Set-RetentionComplianceRule. Teams chats without Copilot interactions use the newer AppRetentionCompliance cmdlet family; Teams channel messages and the legacy Teams chats and Copilot interactions location use the older RetentionCompliance cmdlet family. Verify the exact location before any application: https://learn.microsoft.com/purview/retention-cmdlets and https://learn.microsoft.com/purview/retention-policies-copilot.'
        wormNote = if ($regKey -eq 'SEC_17a4') {
            if ($tierConfig.PSObject.Properties.Name -contains 'wormDocumentationRequired' -and $tierConfig.wormDocumentationRequired) {
                'Document non-rewriteable, non-erasable storage support through a third-party archive or Azure Immutable Storage.'
            } else {
                'Document whether immutable storage is required for the target record set.'
            }
        } else {
            'No additional immutable storage note.'
        }
    }
}

$retentionManifest = [ordered]@{
    solution = $defaultConfig.solution
    solutionCode = $defaultConfig.solutionCode
    displayName = $defaultConfig.displayName
    tier = $ConfigurationTier
    tenantId = $TenantId
    generatedAt = $timestamp
    policies = $retentionPolicies
}

$auditRequirements = [ordered]@{
    solution = $defaultConfig.solution
    solutionCode = $defaultConfig.solutionCode
    displayName = $defaultConfig.displayName
    tier = $ConfigurationTier
    tenantId = $TenantId
    generatedAt = $timestamp
    unifiedAuditLog = [ordered]@{
        checkRequired = $true
        statusIndicator = $ualStatusFlag
        validationCommand = 'Not executable: Check-AuditLogCompleteness is an unimplemented placeholder. Separately validate audit ingestion and event coverage using documented Microsoft Purview Audit search procedures: https://learn.microsoft.com/purview/audit-search.'
        requiredAuditLevel = $tierConfig.auditLevel
        allowedAuditLevels = @($defaultConfig.defaults.auditLevelRequired)
        requiredEventTypes = @($defaultConfig.defaults.auditEventTypes)
        graphPermissions = @($defaultConfig.defaults.graphPermissions)
        latencyNote = 'Microsoft does not guarantee a specific audit record return time; core services typically appear within 60-90 minutes, while other services can take longer.'
    }
}

$deploymentManifest = [ordered]@{
    solution = $defaultConfig.solution
    solutionCode = $defaultConfig.solutionCode
    displayName = $defaultConfig.displayName
    tier = $ConfigurationTier
    tierValue = $tierDefinition.Value
    status = 'documentation-first'
    tenantId = $TenantId
    generatedAt = $timestamp
    outputFiles = @(
        'retention-policy-manifest.json',
        'audit-requirements.json',
        'deployment-manifest.json'
    )
    dataverseTables = [ordered]@{
        baseline = (New-CopilotGovTableName -SolutionSlug 'atm' -Purpose 'baseline')
        assessmentHistory = (New-CopilotGovTableName -SolutionSlug 'atm' -Purpose 'assessmenthistory')
        finding = (New-CopilotGovTableName -SolutionSlug 'atm' -Purpose 'finding')
        evidence = (New-CopilotGovTableName -SolutionSlug 'atm' -Purpose 'evidence')
    }
    ediscoveryStub = [ordered]@{
        mode = $tierConfig.ediscovery.mode
        caseTemplate = $tierConfig.ediscovery.caseTemplate
        holdRequired = [bool]$tierConfig.ediscovery.holdRequired
        custodianScope = $tierConfig.ediscovery.custodianScope
        preservationStatus = $tierConfig.ediscovery.preservationStatus
    }
    nextSteps = @(
        'Review the illustrative retention-policy-manifest.json by content location before any separately authorized Microsoft Purview policy application; this script does not apply policies or configure audit log retention.',
        'Check-AuditLogCompleteness is an unimplemented placeholder, not executable. Separately validate audit ingestion and event coverage after propagation using https://learn.microsoft.com/purview/audit-search.',
        'Confirm Microsoft Purview eDiscovery cases, holds, and custodians match the selected tier.',
        'Document Power BI dashboard refresh ownership and Power Automate alert ownership.',
        'Run Export-Evidence.ps1 to generate local sample evidence for format validation, not tenant observations.'
    )
}

$retentionPath = Join-Path $outputFolder 'retention-policy-manifest.json'
$auditPath = Join-Path $outputFolder 'audit-requirements.json'
$deploymentPath = Join-Path $outputFolder 'deployment-manifest.json'

if ($PSCmdlet.ShouldProcess($outputFolder, 'Write ATM deployment manifests')) {
    $null = New-Item -ItemType Directory -Path $outputFolder -Force
    Write-AtmJsonFile -Path $retentionPath -InputObject $retentionManifest | Out-Null
    Write-AtmJsonFile -Path $auditPath -InputObject $auditRequirements | Out-Null
    Write-AtmJsonFile -Path $deploymentPath -InputObject $deploymentManifest | Out-Null

    Write-Host ('Generated retention manifest: {0}' -f $retentionPath)
    Write-Host ('Generated audit requirements: {0}' -f $auditPath)
    Write-Host ('Generated deployment manifest: {0}' -f $deploymentPath)
    Write-Host 'Next steps:'
    $deploymentManifest.nextSteps | ForEach-Object { Write-Host ('- {0}' -f $_) }

    [pscustomobject]@{
        Solution = $defaultConfig.solution
        Tier = $ConfigurationTier
        TenantId = $TenantId
        RetentionManifestPath = $retentionPath
        AuditRequirementsPath = $auditPath
        DeploymentManifestPath = $deploymentPath
        NextSteps = $deploymentManifest.nextSteps
    }
}