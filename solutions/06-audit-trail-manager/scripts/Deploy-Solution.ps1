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
        targetArtifacts = @($defaultConfig.defaults.auditEventTypes)
        retentionLabelRequired = [bool]$tierConfig.retentionLabelRequired
        policyApplication = 'Apply through the Microsoft Purview portal or Security & Compliance PowerShell cmdlets such as New-RetentionCompliancePolicy, Set-RetentionCompliancePolicy, and New/Set-RetentionComplianceRule.'
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
        validationCommand = 'Check-AuditLogCompleteness'
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
        'Review retention-policy-manifest.json and apply policies through Microsoft Purview.',
        'Run Check-AuditLogCompleteness after audit settings propagation.',
        'Confirm Microsoft Purview eDiscovery cases, holds, and custodians match the selected tier.',
        'Document Power BI dashboard refresh ownership and Power Automate alert ownership.',
        'Run Export-Evidence.ps1 after baseline validation to capture evidence.'
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