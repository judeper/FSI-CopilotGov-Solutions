<#
.SYNOPSIS
    Deploys the Microsoft Purview Communication Compliance Configurator for Microsoft 365 Copilot governance.

.DESCRIPTION
    Tier-aware deployment script that configures Microsoft Purview communication
    compliance policies for Copilot-assisted financial communications. Supports
    FINRA 2210/3110, SEC Reg BI, and FCA SYSC 10 compliance postures.

    This script:
    - Validates prerequisites and configuration
    - Generates policy templates aligned to the selected tier
    - Creates the deployment manifest for manual Purview portal deployment
    - Documents reviewer workflow assignments
    - Outputs deployment summary for evidence

.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.
    baseline: Core Copilot communication monitoring policies
    recommended: + Insider risk correlation + escalation tracking
    regulated: + Full FINRA/SEC/FCA examination-ready policy set + lexicon management

.PARAMETER OutputPath
    Path for deployment artifacts.

.PARAMETER TenantId
    Microsoft Entra ID tenant ID.

.EXAMPLE
    .\Deploy-Solution.ps1 -ConfigurationTier regulated -TenantId '00000000-0000-0000-0000-000000000000' -WhatIf

    Generates the deployment manifest preview without writing files.

.OUTPUTS
    PSCustomObject. Deployment summary with manifest and template paths.

.NOTES
    Solution: Microsoft Purview Communication Compliance Configurator (CCC)
    Controls:  2.10, 3.4, 3.5, 3.6, 3.9
    Regulations: FINRA 2210, FINRA 3110, SEC Reg BI, FCA SYSC 10
    Version: v0.2.1

    IMPORTANT: Microsoft Purview Communication Compliance policy deployment requires manual steps
    in the Microsoft Purview compliance portal. This script generates the policy
    configuration templates and validates prerequisites only.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\deployment'),

    [Parameter()]
    [AllowEmptyString()]
    [string]$TenantId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'CCC-Common.psm1') -Force

function New-PolicyCatalog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    $catalog = Get-PolicyCatalogDefinitions -Config $Config

    $selectedTemplates = @()
    foreach ($templateId in $Config['policyTemplates']) {
        if (-not $catalog.ContainsKey($templateId)) {
            throw ('Unknown policy template ID: {0}' -f $templateId)
        }

        $templateDefinition = @{}
        foreach ($key in $catalog[$templateId].Keys) {
            $templateDefinition[$key] = $catalog[$templateId][$key]
        }

        $templateDefinition['tier'] = $Config['tier']
        $templateDefinition['lexiconWords'] = $Config['lexiconWords']
        $templateDefinition['samplingRate'] = [double]$Config['samplingRate']
        $templateDefinition['reviewerSlaHours'] = [int]$Config['reviewerSlaHours']
        $templateDefinition['requiresManualPortalStep'] = [bool]$Config['manualPortalDeploymentRequired']
        $templateDefinition['version'] = $Config['version']
        $templateDefinition['publishState'] = 'draft'

        $selectedTemplates += [pscustomobject]$templateDefinition
    }

    return $selectedTemplates
}

function New-ReviewerWorkflowSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    $defaults = $Config['reviewerWorkflowDefaults']
    $hasDualReview = $Config.ContainsKey('requireDualReview') -and [bool]$Config['requireDualReview']
    $hasEscalationThreshold = $Config.ContainsKey('escalationThresholdHours')

    return [pscustomobject]@{
        defaultReviewerGroup = $defaults['defaultReviewerGroup']
        escalationReviewerGroup = $defaults['escalationReviewerGroup']
        legalReviewGroup = $defaults['legalReviewGroup']
        reviewerSlaHours = [int]$Config['reviewerSlaHours']
        samplingRate = [double]$Config['samplingRate']
        escalationEnabled = [bool]$Config['escalationEnabled']
        escalationThresholdHours = if ($hasEscalationThreshold) { [int]$Config['escalationThresholdHours'] } else { [int]$Config['reviewerSlaHours'] }
        requireDualReview = $hasDualReview
        dualReviewApprovers = if ($Config.ContainsKey('dualReviewApprovers')) { [int]$Config['dualReviewApprovers'] } else { 1 }
        dispositions = $defaults['dispositions']
        escalationTriggers = $defaults['escalationTriggers']
        dependency = '04-finra-supervision-workflow'
    }
}

$configRoot = Join-Path $solutionRoot 'config'
$config = Get-SolutionConfiguration -ConfigRoot $configRoot -Tier $ConfigurationTier
$tierDefinition = Get-CopilotGovTierDefinition -Tier $ConfigurationTier

if ($config['solutionCode'] -ne 'CCC') {
    throw 'Configuration validation failed: solutionCode must be CCC.'
}

$policyTemplates = New-PolicyCatalog -Config $config
$reviewerWorkflow = New-ReviewerWorkflowSettings -Config $config
$policyTemplatePath = Join-Path $OutputPath 'policy-templates'
$manifestPath = Join-Path $OutputPath 'communication-compliance-config-deployment-manifest.json'

$deploymentManifest = [ordered]@{
    solution = $config['solution']
    solutionCode = $config['solutionCode']
    displayName = $config['displayName']
    version = $config['version']
    generatedAt = (Get-Date).ToString('o')
    tier = $ConfigurationTier
    tierLabel = $tierDefinition.Label
    tierValue = $tierDefinition.Value
    tenantId = if ([string]::IsNullOrWhiteSpace($TenantId)) { 'not-provided' } else { $TenantId }
    controls = $config['controls']
    regulations = $config['regulations']
    dependencies = $config['dependencies']
    supervisedCommunicationTypes = $config['supervisedCommunicationTypes']
    dataverseTables = $config['dataverseTables']
    connectionReferences = $config['connectionReferences']
    environmentVariables = $config['environmentVariables']
    reviewerWorkflow = $reviewerWorkflow
    policyTemplates = $policyTemplates
    manualPortalDeploymentRequired = [bool]$config['manualPortalDeploymentRequired']
    deploymentMode = 'documentation-first'
    manualSteps = @(
        'Generate templates and deployment manifest by using this script.',
        'Create or update each policy in the Microsoft Purview compliance portal.',
        'Assign reviewers and escalation contacts by using the reviewer workflow section.',
        'Publish approved lexicon words after Legal and Compliance review.',
        'Record publication details for evidence export and future examination support.'
    )
}

if ($PSCmdlet.ShouldProcess($OutputPath, 'Create deployment artifact directories')) {
    $null = New-Item -ItemType Directory -Path $OutputPath, $policyTemplatePath -Force
}

foreach ($policyTemplate in $policyTemplates) {
    $policyTemplateFile = Join-Path $policyTemplatePath ('{0}.json' -f $policyTemplate.templateId)
    if ($PSCmdlet.ShouldProcess($policyTemplateFile, 'Write policy template file')) {
        $policyTemplate | ConvertTo-Json -Depth 8 | Set-Content -Path $policyTemplateFile -Encoding utf8
    }
}

if ($PSCmdlet.ShouldProcess($manifestPath, 'Write deployment manifest')) {
    $deploymentManifest | ConvertTo-Json -Depth 8 | Set-Content -Path $manifestPath -Encoding utf8
}

[pscustomobject]@{
    Solution = $config['displayName']
    SolutionCode = $config['solutionCode']
    Tier = $ConfigurationTier
    TierLabel = $tierDefinition.Label
    TierValue = $tierDefinition.Value
    TenantId = if ([string]::IsNullOrWhiteSpace($TenantId)) { 'not-provided' } else { $TenantId }
    PolicyTemplateCount = $policyTemplates.Count
    ReviewerSlaHours = [int]$reviewerWorkflow.reviewerSlaHours
    SamplingRate = [double]$reviewerWorkflow.samplingRate
    PolicyTemplatePath = $policyTemplatePath
    ManifestPath = $manifestPath
    ManualPortalDeploymentRequired = [bool]$config['manualPortalDeploymentRequired']
    Dependency = ($config['dependencies'] -join ', ')
}
