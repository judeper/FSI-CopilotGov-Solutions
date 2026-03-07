<#
.SYNOPSIS
    Deploys the Communication Compliance Configurator for Microsoft 365 Copilot governance.

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
    Azure AD tenant ID.

.EXAMPLE
    .\Deploy-Solution.ps1 -ConfigurationTier regulated -TenantId '00000000-0000-0000-0000-000000000000' -WhatIf

    Generates the deployment manifest preview without writing files.

.OUTPUTS
    PSCustomObject. Deployment summary with manifest and template paths.

.NOTES
    Solution: Communication Compliance Configurator (CCC)
    Controls:  2.10, 3.4, 3.5, 3.6, 3.9
    Regulations: FINRA 2210, FINRA 3110, SEC Reg BI, FCA SYSC 10
    Version: v0.1.0

    IMPORTANT: Communication Compliance policy deployment requires manual steps
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

function ConvertTo-Hashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$InputObject
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $dictionary = @{}
        foreach ($key in $InputObject.Keys) {
            $dictionary[$key] = ConvertTo-Hashtable -InputObject $InputObject[$key]
        }

        return $dictionary
    }

    if ($InputObject -is [pscustomobject]) {
        $dictionary = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $dictionary[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
        }

        return $dictionary
    }

    if (($InputObject -is [System.Collections.IEnumerable]) -and -not ($InputObject -is [string])) {
        $items = @()
        foreach ($item in $InputObject) {
            $items += ,(ConvertTo-Hashtable -InputObject $item)
        }

        return $items
    }

    return $InputObject
}

function Merge-Hashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Base,

        [Parameter(Mandatory)]
        [hashtable]$Overlay
    )

    $merged = @{}
    foreach ($key in $Base.Keys) {
        $merged[$key] = $Base[$key]
    }

    foreach ($key in $Overlay.Keys) {
        if ($merged.ContainsKey($key) -and ($merged[$key] -is [hashtable]) -and ($Overlay[$key] -is [hashtable])) {
            $merged[$key] = Merge-Hashtable -Base $merged[$key] -Overlay $Overlay[$key]
        }
        else {
            $merged[$key] = $Overlay[$key]
        }
    }

    return $merged
}

function Get-SolutionConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigRoot,

        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    $defaultConfigPath = Join-Path $ConfigRoot 'default-config.json'
    $tierConfigPath = Join-Path $ConfigRoot ('{0}.json' -f $Tier)

    if (-not (Test-Path -Path $defaultConfigPath)) {
        throw 'Default configuration file not found.'
    }

    if (-not (Test-Path -Path $tierConfigPath)) {
        throw 'Configuration tier file not found.'
    }

    $defaultConfig = ConvertTo-Hashtable -InputObject ((Get-Content -Path $defaultConfigPath -Raw) | ConvertFrom-Json)
    $tierConfig = ConvertTo-Hashtable -InputObject ((Get-Content -Path $tierConfigPath -Raw) | ConvertFrom-Json)
    $mergedConfig = Merge-Hashtable -Base $defaultConfig -Overlay $tierConfig
    $mergedConfig['tier'] = $Tier

    return $mergedConfig
}

function New-PolicyCatalog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    $catalog = @{
        CopilotAIDisclosure = [ordered]@{
            templateId = 'CopilotAIDisclosure'
            policyName = 'CCC-Copilot-AI-Disclosure'
            policyType = 'AI disclosure review'
            scope = $Config['supervisedCommunicationTypes']
            keywords = @('generated by copilot', 'ai-assisted draft', 'drafted with copilot')
            conditions = @(
                'Customer-facing communication contains AI attribution or draft disclaimer.',
                'Reviewer validates that the disclosure is retained before release.'
            )
            controlMappings = @('3.4', '3.9')
            regulatoryMappings = @('FINRA 2210', 'SEC Reg BI')
            severity = 'Medium'
            notes = 'Supports compliance with AI disclosure and transparency expectations for Copilot-assisted communications.'
        }
        FinancialAdviceReview = [ordered]@{
            templateId = 'FinancialAdviceReview'
            policyName = 'CCC-Financial-Advice-Review'
            policyType = 'financial advice review'
            scope = $Config['supervisedCommunicationTypes']
            keywords = @('portfolio allocation', 'personalized recommendation', 'risk tolerance', 'suitable for you')
            conditions = @(
                'Communication references investor profile, recommendations, or suitability language.',
                'Reviewer validates that advice language aligns to approved supervisory standards.'
            )
            controlMappings = @('3.4', '3.5', '3.6')
            regulatoryMappings = @('FINRA 2210', 'FINRA 3110', 'SEC Reg BI')
            severity = 'High'
            notes = 'Supports compliance with supervisory review requirements for Copilot-assisted financial advice content.'
        }
        PromotionalLanguageReview = [ordered]@{
            templateId = 'PromotionalLanguageReview'
            policyName = 'CCC-Promotional-Language-Review'
            policyType = 'promotional content review'
            scope = $Config['supervisedCommunicationTypes']
            keywords = @('guaranteed returns', 'outperform the market', 'safe investment', 'risk free')
            conditions = @(
                'Communication includes promotional phrasing that may trigger FINRA 2210 review.',
                'Reviewer validates balanced presentation of risks and disclosures.'
            )
            controlMappings = @('3.4', '3.5')
            regulatoryMappings = @('FINRA 2210')
            severity = 'High'
            notes = 'Supports compliance with FINRA 2210 marketing and promotional content review expectations.'
        }
        BestInterestDisclosure = [ordered]@{
            templateId = 'BestInterestDisclosure'
            policyName = 'CCC-Best-Interest-Disclosure'
            policyType = 'best interest disclosure review'
            scope = $Config['supervisedCommunicationTypes']
            keywords = @('best interest', 'rollover recommendation', 'fee comparison', 'material limitation')
            conditions = @(
                'Communication references a recommendation that may require best-interest disclosure.',
                'Reviewer validates that required supporting disclosures are present.'
            )
            controlMappings = @('3.6', '3.9')
            regulatoryMappings = @('SEC Reg BI', 'FINRA 3110')
            severity = 'High'
            notes = 'Supports compliance with disclosure monitoring for recommendations and supervisory follow-up.'
        }
        ConflictOfInterestReview = [ordered]@{
            templateId = 'ConflictOfInterestReview'
            policyName = 'CCC-Conflict-Of-Interest-Review'
            policyType = 'conflict review'
            scope = $Config['supervisedCommunicationTypes']
            keywords = @('proprietary product', 'higher commission', 'revenue sharing', 'sales contest')
            conditions = @(
                'Communication indicates a possible conflict of interest or incentive alignment issue.',
                'Reviewer validates escalation to supervision or legal review when required.'
            )
            controlMappings = @('3.6', '3.9')
            regulatoryMappings = @('FCA SYSC 10', 'SEC Reg BI')
            severity = 'High'
            notes = 'Supports compliance with conflict-of-interest monitoring and oversight expectations.'
        }
        InsiderRiskCorrelation = [ordered]@{
            templateId = 'InsiderRiskCorrelation'
            policyName = 'CCC-Insider-Risk-Correlation'
            policyType = 'insider risk correlation'
            scope = $Config['supervisedCommunicationTypes']
            keywords = @('material non-public information', 'watch list account', 'deal room', 'private placement')
            conditions = @(
                'Communication includes insider risk indicators that may require cross-solution escalation.',
                'Reviewer coordinates with Insider Risk Management if an elevated pattern is detected.'
            )
            controlMappings = @('2.10', '3.6')
            regulatoryMappings = @('FINRA 3110', 'FCA SYSC 10')
            severity = 'High'
            notes = 'Supports compliance with insider risk detection planning when integrated with Insider Risk Management.'
        }
        RetailCommunicationEscalation = [ordered]@{
            templateId = 'RetailCommunicationEscalation'
            policyName = 'CCC-Retail-Communication-Escalation'
            policyType = 'supervisory escalation'
            scope = $Config['supervisedCommunicationTypes']
            keywords = @('principal approval', 'escalate to supervision', 'hold for review', 'legal approval required')
            conditions = @(
                'Communication has triggered review and now requires documented supervisory escalation.',
                'Reviewer validates linkage to the FINRA supervision workflow dependency.'
            )
            controlMappings = @('3.5', '3.6')
            regulatoryMappings = @('FINRA 2210', 'FINRA 3110')
            severity = 'High'
            notes = 'Supports compliance with reviewer escalation and documented supervision procedures.'
        }
        DualReviewSupervision = [ordered]@{
            templateId = 'DualReviewSupervision'
            policyName = 'CCC-Dual-Review-Supervision'
            policyType = 'dual review supervision'
            scope = $Config['supervisedCommunicationTypes']
            keywords = @('legal review', 'secondary reviewer', 'supervisor sign-off', 'retain for exam')
            conditions = @(
                'High-risk communication requires dual review before release or retention closeout.',
                'Reviewer validates secondary approval and evidence retention.'
            )
            controlMappings = @('3.6')
            regulatoryMappings = @('FINRA 3110', 'SEC Reg BI')
            severity = 'High'
            notes = 'Supports compliance with heightened supervision and examination support workflows.'
        }
    }

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
