<#
.SYNOPSIS
Deploys the Copilot Feature Management Controller operating model.

.DESCRIPTION
Loads the selected governance tier, establishes a stub Microsoft Graph context,
collects the current Copilot feature inventory, captures a feature-state baseline,
plans rollout ring assignments, and documents Power Automate flow deployment
intent for the Copilot Feature Management Controller solution.

The script is documentation-first for Power Automate assets. It writes deployment
artifacts that describe the baseline, rollout plan, and flow metadata so the
implementation team can complete tenant-specific enablement after change approval.

.PARAMETER ConfigurationTier
The governance tier to deploy. Valid values are baseline, recommended, and regulated.

.PARAMETER OutputPath
Directory where deployment artifacts are written.

.PARAMETER TenantId
Tenant identifier or primary tenant domain used for the Graph connection context.

.PARAMETER Environment
Target environment label such as Sandbox, UAT, or Production.

.PARAMETER BaselineOnly
When specified, captures baseline state and documents flows without planning
active rollout ring changes.

.EXAMPLE
.\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId 'contoso.onmicrosoft.com' -Environment 'Production' -OutputPath .\artifacts\FMC

.EXAMPLE
.\Deploy-Solution.ps1 -ConfigurationTier baseline -TenantId 'contoso.onmicrosoft.com' -Environment 'Sandbox' -BaselineOnly -WhatIf

.NOTES
This script supports compliance with SEC Reg FD and FINRA 3110 by preserving a
repeatable baseline, ring plan, and change record for Copilot feature enablement.
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

    [Parameter()]
    [string]$Environment = 'Production',

    [Parameter()]
    [switch]$BaselineOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\GraphAuth.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\DataverseHelpers.psm1') -Force

function Get-FmcConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    $defaultPath = Join-Path $PSScriptRoot '..\config\default-config.json'
    $tierPath = Join-Path $PSScriptRoot ("..\config\{0}.json" -f $Tier)

    if (-not (Test-Path -Path $defaultPath)) {
        throw "Default configuration file not found: $defaultPath"
    }

    if (-not (Test-Path -Path $tierPath)) {
        throw "Tier configuration file not found: $tierPath"
    }

    $defaultConfig = Get-Content -Path $defaultPath -Raw | ConvertFrom-Json -AsHashtable
    $tierConfig = Get-Content -Path $tierPath -Raw | ConvertFrom-Json -AsHashtable

    return [ordered]@{
        solution                     = $defaultConfig.solution
        solutionCode                 = $defaultConfig.solutionCode
        displayName                  = $defaultConfig.displayName
        tier                         = $tierConfig.tier
        controls                     = $defaultConfig.controls
        regulations                  = $defaultConfig.regulations
        graph                        = $defaultConfig.graph
        dataverse                    = $defaultConfig.dataverse
        featureCategories            = $defaultConfig.featureCategories
        rolloutRings                 = if ($tierConfig.ContainsKey('rolloutRings')) { $tierConfig.rolloutRings } else { $defaultConfig.rolloutRings }
        powerAutomate                = $defaultConfig.powerAutomate
        driftAlertThreshold          = if ($tierConfig.ContainsKey('driftAlertThreshold')) { [int]$tierConfig.driftAlertThreshold } else { [int]$defaultConfig.driftAlertThreshold }
        driftMonitoring              = $tierConfig.driftMonitoring
        features                     = $tierConfig.features
        appCoverage                  = $tierConfig.appCoverage
        strictChangeApprovalRequired = [bool]$tierConfig.strictChangeApprovalRequired
        changeApprovalMode           = $tierConfig.changeApprovalMode
        scopeDescription             = $tierConfig.scopeDescription
        evidenceOutputs              = $defaultConfig.evidenceOutputs
        evidenceRetentionDays        = [int]$tierConfig.evidenceRetentionDays
        ringManagementEnabled        = [bool]$tierConfig.ringManagementEnabled
    }
}

function Connect-FmcGraphContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter(Mandatory)]
        [hashtable]$GraphConfig,

        [Parameter(Mandatory)]
        [string]$Environment
    )

    $context = New-CopilotGovGraphContext -TenantId $TenantId -Scopes $GraphConfig.requiredScopes

    return [pscustomobject]@{
        tenantId    = $context.TenantId
        scopes      = $context.Scopes
        connectedAt = $context.ConnectedAt
        endpoint    = $GraphConfig.endpoint
        environment = $Environment
        mode        = 'stub'
        notes       = 'Stub Graph context prepared for rollout policy collection.'
    }
}

function Get-CopilotFeatureInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,

        [Parameter(Mandatory)]
        [psobject]$GraphContext,

        [Parameter(Mandatory)]
        [string]$Environment
    )

    $inventory = foreach ($feature in $Configuration.features) {
        [pscustomobject]@{
            featureId               = [string]$feature.featureId
            displayName             = [string]$feature.displayName
            sourceSystem            = [string]$feature.sourceSystem
            category                = [string]$feature.category
            enabled                 = [bool]$feature.expectedEnabled
            currentRing             = [string]$feature.expectedRing
            environment             = $Environment
            approvalMode            = [string]$Configuration.changeApprovalMode
            graphEndpoint           = [string]$GraphContext.endpoint
            monitoringIntervalHours = [int]$Configuration.driftMonitoring.checkIntervalHours
            riskNote                = [string]$feature.riskNote
            inventoryStatus         = 'captured-from-tier-definition'
        }
    }

    return @($inventory)
}

function Set-FeatureRolloutRing {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [psobject]$Feature,

        [Parameter(Mandatory)]
        [string]$TargetRing,

        [Parameter(Mandatory)]
        [hashtable]$RingDefinition,

        [Parameter(Mandatory)]
        [string]$Environment
    )

    $enabled = if ($RingDefinition.ContainsKey('enabled')) { [bool]$RingDefinition.enabled } else { $true }
    $action = if ($PSCmdlet.ShouldProcess($Feature.displayName, "Assign feature to $TargetRing in $Environment")) { 'planned' } else { 'whatif' }

    return [pscustomobject]@{
        featureId        = $Feature.featureId
        displayName      = $Feature.displayName
        targetRing       = $TargetRing
        targetPercentage = [int]$RingDefinition.targetPercentage
        approvalRequired = [bool]$RingDefinition.approvalRequired
        enabled          = $enabled
        environment      = $Environment
        action           = $action
        notes            = 'Stub rollout assignment recorded for later admin center or Graph execution.'
    }
}

function New-FeatureBaseline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Inventory,

        [Parameter(Mandatory)]
        [hashtable]$Configuration,

        [Parameter(Mandatory)]
        [psobject]$GraphContext,

        [Parameter(Mandatory)]
        [string]$Environment
    )

    $baselineTable = New-CopilotGovTableName -SolutionSlug 'fmc' -Purpose 'baseline'

    return [pscustomobject]@{
        baselineId            = [guid]::NewGuid().Guid
        solution              = $Configuration.solution
        solutionCode          = $Configuration.solutionCode
        tier                  = $Configuration.tier
        environment           = $Environment
        scopeDescription      = $Configuration.scopeDescription
        graphEndpoint         = $GraphContext.endpoint
        capturedAt            = (Get-Date).ToString('o')
        dataverseTable        = $baselineTable
        driftIntervalHours    = [int]$Configuration.driftMonitoring.checkIntervalHours
        evidenceRetentionDays = [int]$Configuration.evidenceRetentionDays
        features              = $Inventory
    }
}

function Get-DataverseContracts {
    [CmdletBinding()]
    param()

    return @(
        (New-DataverseTableContract -SchemaName (New-CopilotGovTableName -SolutionSlug 'fmc' -Purpose 'baseline') -Columns @('featureid', 'displayname', 'sourcesystem', 'expectedring', 'expectedenabled', 'approvalreference', 'capturedat')),
        (New-DataverseTableContract -SchemaName (New-CopilotGovTableName -SolutionSlug 'fmc' -Purpose 'finding') -Columns @('findingid', 'featureid', 'drifttype', 'severity', 'baselinevalue', 'observedvalue', 'status', 'detectedat')),
        (New-DataverseTableContract -SchemaName (New-CopilotGovTableName -SolutionSlug 'fmc' -Purpose 'evidence') -Columns @('packageid', 'artifacttype', 'tier', 'generatedat', 'hash', 'storagepath'))
    )
}

function Get-PowerAutomateFlowPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,

        [Parameter(Mandatory)]
        [string]$Environment,

        [Parameter()]
        [switch]$BaselineOnly
    )

    $flows = foreach ($flow in $Configuration.powerAutomate.flows) {
        $deploymentState = if ($BaselineOnly -and $flow.name -eq 'FMC-RingPromotion') {
            'deferred'
        }
        else {
            'documented'
        }

        [pscustomobject]@{
            name               = $flow.name
            trigger            = $flow.trigger
            purpose            = $flow.purpose
            environment        = $Environment
            deploymentState    = $deploymentState
            documentationFirst = [bool]$Configuration.powerAutomate.documentationFirst
        }
    }

    return @($flows)
}

try {
    $configuration = Get-FmcConfiguration -Tier $ConfigurationTier
    $graphContext = Connect-FmcGraphContext -TenantId $TenantId -GraphConfig $configuration.graph -Environment $Environment
    $inventory = Get-CopilotFeatureInventory -Configuration $configuration -GraphContext $graphContext -Environment $Environment
    $baseline = New-FeatureBaseline -Inventory $inventory -Configuration $configuration -GraphContext $graphContext -Environment $Environment
    $dataverseContracts = Get-DataverseContracts
    $flowPlan = Get-PowerAutomateFlowPlan -Configuration $configuration -Environment $Environment -BaselineOnly:$BaselineOnly

    $rolloutPlan = @()
    if ($BaselineOnly) {
        $rolloutPlan = @(
            [pscustomobject]@{
                action = 'skipped'
                reason = 'BaselineOnly specified. No rollout ring changes were planned.'
            }
        )
    }
    elseif (-not $configuration.ringManagementEnabled) {
        $rolloutPlan = @(
            [pscustomobject]@{
                action = 'skipped'
                reason = 'Ring management is disabled for the selected tier.'
            }
        )
    }
    else {
        foreach ($feature in $inventory) {
            $targetRing = [string]$feature.currentRing
            $ringDefinition = $configuration.rolloutRings[$targetRing]
            if (-not $ringDefinition) {
                throw "Rollout ring definition not found for target ring '$targetRing'."
            }

            $rolloutPlan += Set-FeatureRolloutRing -Feature $feature -TargetRing $targetRing -RingDefinition $ringDefinition -Environment $Environment
        }
    }

    $deploymentSummary = [pscustomobject]@{
        solution               = $configuration.solution
        solutionCode           = $configuration.solutionCode
        displayName            = $configuration.displayName
        tier                   = $configuration.tier
        environment            = $Environment
        deploymentMode         = if ($BaselineOnly) { 'baseline-only' } else { 'full-plan' }
        graphContext           = $graphContext
        featureInventoryCount  = @($inventory).Count
        appCoverage            = $configuration.appCoverage
        baseline               = $baseline
        rolloutPlan            = $rolloutPlan
        dataverseContracts     = $dataverseContracts
        powerAutomateFlows     = $flowPlan
        driftAlertThreshold    = [int]$configuration.driftAlertThreshold
        evidenceOutputs        = $configuration.evidenceOutputs
        plannedOutputPath      = $OutputPath
        strictApprovalRequired = [bool]$configuration.strictChangeApprovalRequired
    }

    if ($PSCmdlet.ShouldProcess($OutputPath, 'Write FMC deployment artifacts')) {
        $null = New-Item -ItemType Directory -Path $OutputPath -Force
        $baselinePath = Join-Path $OutputPath 'feature-state-baseline.json'
        $summaryPath = Join-Path $OutputPath 'fmc-deployment-summary.json'

        $baseline | ConvertTo-Json -Depth 10 | Set-Content -Path $baselinePath -Encoding utf8
        $deploymentSummary | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryPath -Encoding utf8
    }

    Write-Output $deploymentSummary
}
catch {
    $message = "Deploy-Solution.ps1 failed for FMC: $($_.Exception.Message)"
    Write-Error $message
    throw
}
