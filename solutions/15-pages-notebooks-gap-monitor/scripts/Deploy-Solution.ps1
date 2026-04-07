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
    - Initializes the gap register with known platform gaps
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
    Version: v0.1.0

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
            description = 'Copilot Pages stored in Loop-backed workspaces may not consistently inherit tenant retention coverage at the time content is created, so preservation must be verified manually.'
            affectedCapability = 'Copilot Pages retention coverage'
            regulations = @('SEC 17a-4', 'FINRA 4511', 'SOX 404')
            severity = 'high'
            status = 'open'
            discoveredAt = $generatedAt.AddDays(-30).ToString('o')
            platformUpdateRequired = $true
            gapCategory = 'pages-retention-coverage'
            owner = 'Records Management'
            recommendedCompensatingControl = 'Export in-scope Pages content to a governed SharePoint records library and retain reviewer sign-off.'
            reviewFrequencyDays = [int]$DefaultConfiguration.gapReviewFrequencyDays
        }
        [pscustomobject]@{
            gapId = 'PNGM-GAP-002'
            description = 'Loop workspace content referenced by Copilot Pages may not appear consistently in Microsoft Purview eDiscovery workflows across tenant configurations, requiring case-by-case validation.'
            affectedCapability = 'Loop workspace Microsoft Purview eDiscovery scope'
            regulations = @('SEC 17a-4', 'FINRA 4511')
            severity = 'high'
            status = 'open'
            discoveredAt = $generatedAt.AddDays(-21).ToString('o')
            platformUpdateRequired = $true
            gapCategory = 'loop-ediscovery-coverage'
            owner = 'Microsoft Purview eDiscovery Operations'
            recommendedCompensatingControl = 'Capture manual exports and related site URLs in the investigation record until native search coverage is confirmed.'
            reviewFrequencyDays = [int]$DefaultConfiguration.gapReviewFrequencyDays
        }
        [pscustomobject]@{
            gapId = 'PNGM-GAP-003'
            description = 'Notebooks stored in Teams and SharePoint are usually retained, but Copilot-generated notebook context and linked summaries still require manual validation for examiner-ready preservation.'
            affectedCapability = 'Notebooks preservation verification'
            regulations = @('FINRA 4511', 'SOX 404')
            severity = 'medium'
            status = 'open'
            discoveredAt = $generatedAt.AddDays(-14).ToString('o')
            platformUpdateRequired = $false
            gapCategory = 'notebooks-preservation-verification'
            owner = 'Compliance Operations'
            recommendedCompensatingControl = 'Validate notebook storage location, retention label inheritance, and export steps during quarterly control reviews.'
            reviewFrequencyDays = [int]$DefaultConfiguration.gapReviewFrequencyDays
        }
        [pscustomobject]@{
            gapId = 'PNGM-GAP-004'
            description = 'Copilot Pages security and sharing settings can depend on the underlying SharePoint or Loop workspace configuration, which requires manual review for restricted and external access scenarios.'
            affectedCapability = 'Copilot Pages security and sharing'
            regulations = @('FINRA 4511', 'SOX 404')
            severity = 'medium'
            status = 'open'
            discoveredAt = $generatedAt.AddDays(-7).ToString('o')
            platformUpdateRequired = $false
            gapCategory = 'pages-sharing-controls'
            owner = 'Collaboration Governance'
            recommendedCompensatingControl = 'Restrict site membership, disable external sharing where required, and capture monthly sharing reviews in the control log.'
            reviewFrequencyDays = [int]$DefaultConfiguration.gapReviewFrequencyDays
        }
        [pscustomobject]@{
            gapId = 'PNGM-GAP-005'
            description = 'Copilot Pages and Loop-backed content may not satisfy books-and-records preservation requirements natively, requiring formal exceptions with documented compensating controls until platform coverage is confirmed.'
            affectedCapability = 'Books-and-records preservation exceptions'
            regulations = @('SEC 17a-4', 'FINRA 4511')
            severity = 'high'
            status = 'open'
            discoveredAt = $generatedAt.AddDays(-28).ToString('o')
            platformUpdateRequired = $true
            gapCategory = 'books-and-records-exceptions'
            owner = 'Records Management'
            recommendedCompensatingControl = 'Register a formal preservation exception with legal sign-off, document the interim manual export procedure, and schedule quarterly reviews until native WORM-compliant preservation is available.'
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
