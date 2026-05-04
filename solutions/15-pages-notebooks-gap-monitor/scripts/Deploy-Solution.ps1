<#
.SYNOPSIS
    Deploys the Copilot Pages and Notebooks Compliance Gap Monitor.

.DESCRIPTION
    Initializes the compliance gap register for Copilot Pages and Notebooks,
    documenting known platform limitations and their regulatory implications.
    Supports compliance with SEC 17a-4, FINRA 4511, and SOX 404 evidence
    expectations by creating a tier-aware deployment manifest and an initial
    gap register for review.

    This script:
    - Validates prerequisite configuration files
    - Loads the default and tier-specific solution configuration
    - Initializes the gap register with supported-but-validate checks and documented platform limitations
    - Creates the deployment manifest
    - Outputs the initial gap baseline for review

.PARAMETER ConfigurationTier
    baseline: Gap discovery and documentation only
    recommended: Gap documentation plus compensating control registration
    regulated: Gap documentation plus preservation exception tracking and
    legal review requirements

.PARAMETER OutputPath
    Directory where the deployment manifest and initial gap register are written.

.OUTPUTS
    PSCustomObject. Deployment summary with the selected tier, gap count, and
    output file locations.

.EXAMPLE
    pwsh -File .\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended

.EXAMPLE
    pwsh -File .\scripts\Deploy-Solution.ps1 -ConfigurationTier regulated -OutputPath .\artifacts\deployment -WhatIf

.NOTES
    Solution: Copilot Pages and Notebooks Compliance Gap Monitor (PNGM)
    Controls: 2.11, 3.2, 3.3, 3.11
    Regulations: SEC 17a-4, FINRA 4511, SOX 404
    Version: v0.1.1

    NOTE: This solution documents compliance gaps. It does NOT automatically
    remediate retention or Microsoft Purview eDiscovery configurations. All gap remediations
    require human review and approval by compliance personnel.
#>
[CmdletBinding(SupportsShouldProcess)]
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
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force

Import-Module (Join-Path $PSScriptRoot 'PngmShared.psm1') -Force

function Get-KnownGapBaseline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$DefaultConfiguration
    )

    $generatedAt = Get-Date

    return @(
        [pscustomobject]@{
            gapId = 'PNGM-GAP-001'
            description = 'Purview retention policies configured for All SharePoint Sites are supported for Copilot Pages and Copilot Notebooks; tenant policy scope and evidence should be validated for regulated records.'
            affectedCapability = 'Copilot Pages and Notebooks retention policy validation'
            regulations = @('SEC 17a-4', 'FINRA 4511', 'SOX 404')
            severity = 'medium'
            status = 'validation-required'
            discoveredAt = $generatedAt.AddDays(-30).ToString('o')
            platformUpdateRequired = $false
            gapCategory = 'pages-retention-policy-validation'
            owner = 'Records Management'
            recommendedCompensatingControl = 'Confirm All SharePoint Sites retention policy scope or documented container-specific configuration and record validation evidence.'
            reviewFrequencyDays = [int]$DefaultConfiguration.gapReviewFrequencyDays
        }
        [pscustomobject]@{
            gapId = 'PNGM-GAP-002'
            description = 'Purview eDiscovery supports search, collection, review, and export for Pages, Notebooks, and Loop, but full-text search within .page and .loop files in review sets is not available.'
            affectedCapability = 'Purview eDiscovery review-set full-text search'
            regulations = @('SEC 17a-4', 'FINRA 4511')
            severity = 'high'
            status = 'open'
            discoveredAt = $generatedAt.AddDays(-21).ToString('o')
            platformUpdateRequired = $true
            gapCategory = 'ediscovery-review-set-full-text-limitation'
            owner = 'Microsoft Purview eDiscovery Operations'
            recommendedCompensatingControl = 'Record case scope, container URLs, collection/export steps, and review-set full-text limitations in the investigation record.'
            reviewFrequencyDays = [int]$DefaultConfiguration.gapReviewFrequencyDays
        }
        [pscustomobject]@{
            gapId = 'PNGM-GAP-003'
            description = 'Copilot Notebooks create .pod files in SharePoint Embedded containers; notebook storage, retention policy scope, and export evidence require tenant validation.'
            affectedCapability = 'Notebooks preservation verification'
            regulations = @('FINRA 4511', 'SOX 404')
            severity = 'medium'
            status = 'validation-required'
            discoveredAt = $generatedAt.AddDays(-14).ToString('o')
            platformUpdateRequired = $false
            gapCategory = 'notebooks-preservation-verification'
            owner = 'Compliance Operations'
            recommendedCompensatingControl = 'Validate notebook storage location, retention label inheritance, and export steps during quarterly control reviews.'
            reviewFrequencyDays = [int]$DefaultConfiguration.gapReviewFrequencyDays
        }
        [pscustomobject]@{
            gapId = 'PNGM-GAP-004'
            description = 'Copilot Pages security and sharing settings require manual review, and Information Barriers are not supported for SharePoint Embedded content.'
            affectedCapability = 'Copilot Pages security, sharing, and Information Barriers'
            regulations = @('FINRA 4511', 'SOX 404')
            severity = 'high'
            status = 'open'
            discoveredAt = $generatedAt.AddDays(-7).ToString('o')
            platformUpdateRequired = $true
            gapCategory = 'sharepoint-embedded-information-barriers-limitation'
            owner = 'Collaboration Governance'
            recommendedCompensatingControl = 'Restrict site membership, disable external sharing where required, and record monthly sharing reviews in the control log.'
            reviewFrequencyDays = [int]$DefaultConfiguration.gapReviewFrequencyDays
        }
        [pscustomobject]@{
            gapId = 'PNGM-GAP-005'
            description = 'Legal hold for Copilot Pages, Copilot Notebooks, and Loop My workspace content requires manual SharePoint Embedded container addition per user, and retention labels have limited manual support.'
            affectedCapability = 'Legal hold and retention label limitations'
            regulations = @('SEC 17a-4', 'FINRA 4511')
            severity = 'high'
            status = 'open'
            discoveredAt = $generatedAt.AddDays(-28).ToString('o')
            platformUpdateRequired = $true
            gapCategory = 'legal-hold-container-scope'
            owner = 'Records Management'
            recommendedCompensatingControl = 'Register a formal preservation exception when legal hold or retention-label limits affect regulated records, document manual container addition, and schedule quarterly reviews.'
            reviewFrequencyDays = [int]$DefaultConfiguration.gapReviewFrequencyDays
        }
    )
}

$configuration = Get-PngmConfiguration -Tier $ConfigurationTier
$defaultConfig = $configuration.Default
$tierConfig = $configuration.Tier
$tierDefinition = Get-CopilotGovTierDefinition -Tier $ConfigurationTier
$knownGaps = Get-KnownGapBaseline -DefaultConfiguration $defaultConfig

$solutionNameForTables = 'pages-notebooks-gap-monitor'
$manifestPath = Join-Path $OutputPath '15-pages-notebooks-gap-monitor-deployment-manifest.json'
$gapRegisterPath = Join-Path $OutputPath '15-pages-notebooks-gap-monitor-gap-register.json'

$deploymentManifest = [ordered]@{
    solution = $defaultConfig.solution
    solutionCode = $defaultConfig.solutionCode
    displayName = $defaultConfig.displayName
    version = $defaultConfig.version
    tier = $ConfigurationTier
    tierDefinition = $tierDefinition
    track = $defaultConfig.track
    priority = $defaultConfig.priority
    phase = $defaultConfig.phase
    controls = @($defaultConfig.controls)
    regulations = @($defaultConfig.regulations)
    dependencies = @($defaultConfig.dependencies)
    evidenceOutputs = @($defaultConfig.evidenceOutputs)
    knownGapCategories = @($defaultConfig.knownGapCategories)
    configuration = [ordered]@{
        default = $defaultConfig
        tier = $tierConfig
    }
    dataverseTables = @(
        (New-CopilotGovTableName -SolutionSlug $solutionNameForTables -Purpose 'baseline'),
        (New-CopilotGovTableName -SolutionSlug $solutionNameForTables -Purpose 'finding'),
        (New-CopilotGovTableName -SolutionSlug $solutionNameForTables -Purpose 'evidence')
    )
    connectionReferences = @(
        'fsi_cr_pages_notebooks_gap_monitor_graph',
        'fsi_cr_pages_notebooks_gap_monitor_dataverse',
        'fsi_cr_pages_notebooks_gap_monitor_messagecenter'
    )
    environmentVariables = @(
        'fsi_ev_pages_notebooks_gap_monitor_gap_review_frequency_days',
        'fsi_ev_pages_notebooks_gap_monitor_platform_update_check_frequency_days',
        'fsi_ev_pages_notebooks_gap_monitor_exception_review_owner'
    )
    initializedAt = (Get-Date).ToString('o')
    gapCount = $knownGaps.Count
    notes = 'This deployment creates a gap register and manifest. It does not change tenant retention or Microsoft Purview eDiscovery settings.'
}

$gapRegister = [ordered]@{
    solution = $defaultConfig.solution
    solutionCode = $defaultConfig.solutionCode
    displayName = $defaultConfig.displayName
    tier = $ConfigurationTier
    exportedAt = (Get-Date).ToString('o')
    gapCount = $knownGaps.Count
    gaps = $knownGaps
}

$deploymentApplied = $false
if ($PSCmdlet.ShouldProcess($defaultConfig.displayName, "Initialize gap register for tier $ConfigurationTier")) {
    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $deploymentManifest | ConvertTo-Json -Depth 8 | Set-Content -Path $manifestPath -Encoding utf8
    $gapRegister | ConvertTo-Json -Depth 8 | Set-Content -Path $gapRegisterPath -Encoding utf8
    $deploymentApplied = $true
}

[pscustomobject]@{
    solution = $defaultConfig.solution
    solutionCode = $defaultConfig.solutionCode
    tier = $ConfigurationTier
    tierLabel = $tierDefinition.Label
    gapCount = $knownGaps.Count
    deploymentApplied = $deploymentApplied
    manifestPath = $manifestPath
    gapRegisterPath = $gapRegisterPath
}
