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
    Version: v0.1.3

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
            affectedRegulation = @('SEC 17a-4', 'FINRA 4511', 'SOX 404')
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
            description = 'M365 Roadmap item 561492 launched in June 2026 and is rolling out full review-set indexing for Loop and Copilot Pages plus HTML export from search. Keep tenant-level verification and case notes until rollout is confirmed in production.'
            affectedCapability = 'Purview eDiscovery review-set indexing rollout validation'
            affectedRegulation = @('SEC 17a-4', 'FINRA 4511')
            severity = 'medium'
            status = 'validation-required'
            discoveredAt = $generatedAt.AddDays(-21).ToString('o')
            platformUpdateRequired = $false
            gapCategory = 'ediscovery-review-set-rollout-validation'
            owner = 'Microsoft Purview eDiscovery Operations'
            recommendedCompensatingControl = 'Validate tenant rollout status for review-set keyword search and HTML export, then capture case-level evidence showing whether manual workaround procedures are still needed.'
            reviewFrequencyDays = [int]$DefaultConfiguration.gapReviewFrequencyDays
        }
        [pscustomobject]@{
            gapId = 'PNGM-GAP-003'
            description = 'Copilot Notebooks create .pod files in the same user-owned SharePoint Embedded container as Copilot Pages and Loop My workspace. There is no end-user recycle bin recovery for individually deleted notebooks, so lifecycle and audit visibility controls remain open.'
            affectedCapability = 'Notebook lifecycle, audit visibility, and recovery limitation'
            affectedRegulation = @('SEC 17a-4', 'FINRA 4511', 'SOX 404')
            severity = 'high'
            status = 'open'
            discoveredAt = $generatedAt.AddDays(-14).ToString('o')
            platformUpdateRequired = $true
            gapCategory = 'notebooks-audit-and-recovery-limitation'
            owner = 'Compliance Operations'
            recommendedCompensatingControl = 'Record .page/.pod audit checks, confirm notebook storage and retention scope, and preserve examiner-ready exports for deleted-notebook scenarios that cannot be recovered natively.'
            reviewFrequencyDays = [int]$DefaultConfiguration.gapReviewFrequencyDays
        }
        [pscustomobject]@{
            gapId = 'PNGM-GAP-004'
            description = 'Conditional Access applies at the Microsoft 365 Copilot app level, and Information Barriers are not supported for SharePoint Embedded containers. Access boundaries for Copilot Pages and Notebooks require manual governance checks.'
            affectedCapability = 'Access boundaries (Conditional Access app-level and Information Barriers limitation)'
            affectedRegulation = @('FINRA 4511', 'SOX 404')
            severity = 'high'
            status = 'open'
            discoveredAt = $generatedAt.AddDays(-7).ToString('o')
            platformUpdateRequired = $true
            gapCategory = 'pages-access-boundary-limitation'
            owner = 'Collaboration Governance'
            recommendedCompensatingControl = 'Restrict site membership, validate app-level Conditional Access coverage, and record monthly sharing and access-boundary reviews in the control log.'
            reviewFrequencyDays = [int]$DefaultConfiguration.gapReviewFrequencyDays
        }
        [pscustomobject]@{
            gapId = 'PNGM-GAP-005'
            description = 'Purview custodian data-source picker support for user-owned SharePoint Embedded containers is rolling out (expected early August 2026). Until validated in tenant, legal hold still requires manual container inclusion and retention-label handling remains partially manual.'
            affectedCapability = 'Legal hold container picker rollout and retention-label manual limits'
            affectedRegulation = @('SEC 17a-4', 'FINRA 4511')
            severity = 'medium'
            status = 'validation-required'
            discoveredAt = $generatedAt.AddDays(-28).ToString('o')
            platformUpdateRequired = $false
            gapCategory = 'legal-hold-and-retention-label-rollout'
            owner = 'Records Management'
            recommendedCompensatingControl = 'Document manual container inclusion until picker rollout is verified, capture legal-hold evidence per case, and track retention-label manual limits in preservation exception reviews.'
            reviewFrequencyDays = [int]$DefaultConfiguration.gapReviewFrequencyDays
        }
    )
}

$configuration = Get-PngmConfiguration -Tier $ConfigurationTier
$defaultConfig = $configuration.Default
$tierConfig = $configuration.Tier
$tierDefinition = Get-CopilotGovTierDefinition -Tier $ConfigurationTier
$knownGaps = Get-KnownGapBaseline -DefaultConfiguration $defaultConfig
$dependencyStatus = Get-PngmDependencyStatus -RepoRoot $repoRoot -Dependencies @($defaultConfig.dependencies)

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
    frameworkIds = @($defaultConfig.framework_ids)
    dependencies = @($defaultConfig.dependencies)
    dependencyStatus = $dependencyStatus
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
    frameworkIds = @($defaultConfig.framework_ids)
    tier = $ConfigurationTier
    exportedAt = (Get-Date).ToString('o')
    gapCount = $knownGaps.Count
    dependencyStatus = $dependencyStatus
    gaps = $knownGaps
}

if ($dependencyStatus.hasMissingDependencies) {
    $missing = @($dependencyStatus.dependencies | Where-Object { $_.status -eq 'missing' } | ForEach-Object { $_.dependency })
    Write-Warning ('Missing dependency scaffolds detected: {0}. Deploy remains documentation-first until dependency content is restored.' -f ($missing -join ', '))
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
    dependencyMissingCount = $dependencyStatus.missingDependencyCount
    deploymentApplied = $deploymentApplied
    manifestPath = $manifestPath
    gapRegisterPath = $gapRegisterPath
}
