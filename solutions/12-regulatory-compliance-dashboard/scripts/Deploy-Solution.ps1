<#
.SYNOPSIS
Deploys the Regulatory Compliance Dashboard solution scaffold for the selected governance tier.
.DESCRIPTION
Loads tier configuration, validates dependency solutions, inventories upstream evidence packages,
documents the Dataverse table contracts used by the dashboard, generates an initial control status
snapshot, and writes a deployment manifest plus seed files for implementation. The script follows
the documentation-first rule for Power BI assets and therefore documents report expectations instead
of creating a binary Power BI file.
.PARAMETER ConfigurationTier
Governance tier to deploy. Valid values are baseline, recommended, and regulated.
.PARAMETER OutputPath
Directory used for generated deployment artifacts, including the control status snapshot and manifest.
.PARAMETER TenantId
Microsoft Entra tenant identifier recorded in the deployment manifest.
.PARAMETER Environment
Power Platform environment name recorded in the deployment manifest.
.PARAMETER DataverseUrl
Dataverse URL for the target environment.
.EXAMPLE
pwsh .\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId '00000000-0000-0000-0000-000000000000' -Environment 'fsi-copilotgov-dev' -DataverseUrl 'https://contoso.crm.dynamics.com'
.EXAMPLE
pwsh .\Deploy-Solution.ps1 -ConfigurationTier regulated -OutputPath 'C:\Temp\rcd' -WhatIf
.NOTES
Use -WhatIf to review the Dataverse and manifest actions before writing files.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts'),

    [Parameter()]
    [string]$TenantId = '00000000-0000-0000-0000-000000000000',

    [Parameter()]
    [string]$Environment = 'fsi-copilotgov-dev',

    [Parameter()]
    [string]$DataverseUrl = 'https://contoso.crm.dynamics.com'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:SolutionSlug = '12-regulatory-compliance-dashboard'
$script:SolutionCode = 'RCD'
$script:SolutionName = 'Regulatory Compliance Dashboard'
$script:ControlIds = @('3.7', '3.8', '3.12', '3.13', '4.5', '4.7')
$script:Dependencies = @('06-audit-trail-manager', '11-risk-tiered-rollout')
$script:RuntimeMode = 'documentation-first-seed'
$script:RuntimeWarning = 'Deploy-Solution.ps1 writes Dataverse and Power BI seed artifacts only; it does not stand up a live dashboard or aggregation flow.'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\DataverseHelpers.psm1') -Force

function Get-SolutionEvidenceInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryRoot,

        [Parameter(Mandatory)]
        [string]$CurrentSolutionSlug
    )

    $solutionsPath = Join-Path $RepositoryRoot 'solutions'
    $solutionDirectories = @(Get-ChildItem -Path $solutionsPath -Directory | Where-Object { $_.Name -ne $CurrentSolutionSlug } | Sort-Object Name)

    $inventory = foreach ($solutionDirectory in $solutionDirectories) {
        $exportScriptPath = Join-Path $solutionDirectory.FullName 'scripts\Export-Evidence.ps1'
        $evidenceFiles = @(
            Get-ChildItem -Path $solutionDirectory.FullName -Filter '*-evidence.json' -File -Recurse -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTimeUtc -Descending
        )
        $latestEvidence = $evidenceFiles | Select-Object -First 1

        [pscustomobject]@{
            solutionSlug = $solutionDirectory.Name
            exportScriptAvailable = (Test-Path -Path $exportScriptPath)
            evidencePath = if ($latestEvidence) { $latestEvidence.FullName } else { $null }
            lastEvidenceDate = if ($latestEvidence) { $latestEvidence.LastWriteTimeUtc.ToString('o') } else { $null }
            availability = if ($latestEvidence) { 'available' } elseif (Test-Path -Path $exportScriptPath) { 'ready-no-export' } else { 'not-configured' }
        }
    }

    return $inventory
}

function New-ControlStatusSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$EvidenceInventory,

        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    $controlPlan = @(
        [ordered]@{
            controlId = '3.7'
            controlTitle = 'Compliance Posture Reporting and Executive Dashboards'
            status = 'partial'
            sourceSolutions = @('06-audit-trail-manager', '11-risk-tiered-rollout')
            notes = 'Seeded dashboard posture artifacts document the intended RAG and executive scorecard model, but live aggregation remains outside the repository.'
        }
        [ordered]@{
            controlId = '3.8'
            controlTitle = 'Regulatory Examination Readiness Reporting'
            status = 'partial'
            sourceSolutions = @('06-audit-trail-manager', '11-risk-tiered-rollout')
            notes = 'Supports readiness package assembly when upstream evidence exports are current and accessible, but repository outputs remain implementation seeds.'
        }
        [ordered]@{
            controlId = '3.12'
            controlTitle = 'Evidence Collection and Audit Attestation'
            status = 'monitor-only'
            sourceSolutions = @('06-audit-trail-manager')
            notes = 'Tracks evidence freshness, package hashes, and attestation references while source systems remain responsible for collection.'
        }
        [ordered]@{
            controlId = '3.13'
            controlTitle = 'Third-Party Audit and Regulatory Reporting'
            status = 'monitor-only'
            sourceSolutions = @('06-audit-trail-manager')
            notes = 'Consolidates audit reporting context and exported evidence references for downstream third-party review.'
        }
        [ordered]@{
            controlId = '4.5'
            controlTitle = 'Copilot Usage Analytics and Adoption Reporting'
            status = 'monitor-only'
            sourceSolutions = @('11-risk-tiered-rollout')
            notes = 'Surfaces usage and adoption telemetry from upstream solutions without changing the underlying telemetry controls.'
        }
        [ordered]@{
            controlId = '4.7'
            controlTitle = 'Governance Maturity Scoring and Benchmarking'
            status = 'monitor-only'
            sourceSolutions = @('06-audit-trail-manager', '11-risk-tiered-rollout')
            notes = 'Calculates weighted maturity scoring from aggregated evidence and benchmark inputs supplied by upstream solutions.'
        }
    )

    $snapshot = foreach ($control in $controlPlan) {
        $matchingEvidence = @(
            $EvidenceInventory |
                Where-Object {
                    ($_.solutionSlug -in $control.sourceSolutions) -and
                    ($_.availability -eq 'available') -and
                    -not [string]::IsNullOrWhiteSpace([string]$_.lastEvidenceDate)
                }
        )
        $latestEvidence = $matchingEvidence | Sort-Object lastEvidenceDate -Descending | Select-Object -First 1
        $notes = $control.notes

        if (-not $latestEvidence) {
            $notes = '{0} No upstream evidence package was discovered during deployment seeding.' -f $control.notes
        }

        [pscustomobject]@{
            controlId = $control.controlId
            controlTitle = $control.controlTitle
            tier = $Tier
            status = $control.status
            score = [int](Get-CopilotGovStatusScore -Status $control.status)
            lastEvidenceDate = if ($latestEvidence) { $latestEvidence.lastEvidenceDate } else { $null }
            solutionSlug = $script:SolutionCode
            sourceSolutions = @($control.sourceSolutions)
            availableEvidenceSources = $matchingEvidence.Count
            dataSourceMode = 'deployment-seed'
            notes = $notes
        }
    }

    return $snapshot
}

function Initialize-DashboardDataverse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TargetEnvironment,

        [Parameter(Mandatory)]
        [string]$TargetDataverseUrl
    )

    $solutionToken = $script:SolutionCode.ToLowerInvariant()
    $baselineTableName = New-CopilotGovTableName -SolutionSlug $solutionToken -Purpose 'baseline'
    $findingTableName = New-CopilotGovTableName -SolutionSlug $solutionToken -Purpose 'finding'
    $evidenceTableName = New-CopilotGovTableName -SolutionSlug $solutionToken -Purpose 'evidence'

    return [pscustomobject]@{
        environment = $TargetEnvironment
        dataverseUrl = $TargetDataverseUrl
        tables = @(
            (New-DataverseTableContract -SchemaName $baselineTableName -Columns @(
                    'fsi_controlid',
                    'fsi_controltitle',
                    'fsi_status',
                    'fsi_score',
                    'fsi_lastevidencedate',
                    'fsi_solutionslug',
                    'fsi_tier',
                    'fsi_notes'
                )),
            (New-DataverseTableContract -SchemaName $findingTableName -Columns @(
                    'fsi_findingid',
                    'fsi_frameworkid',
                    'fsi_controlid',
                    'fsi_severity',
                    'fsi_gapdescription',
                    'fsi_ownersolution',
                    'fsi_targetdate'
                )),
            (New-DataverseTableContract -SchemaName $evidenceTableName -Columns @(
                    'fsi_evidenceid',
                    'fsi_solutionslug',
                    'fsi_evidencetype',
                    'fsi_exportedat',
                    'fsi_hash',
                    'fsi_storagepath',
                    'fsi_isfresh',
                    'fsi_frameworklist'
                ))
        )
    }
}

try {
    $defaultConfigPath = Join-Path $PSScriptRoot '..\config\default-config.json'
    $tierConfigPath = Join-Path $PSScriptRoot ("..\config\{0}.json" -f $ConfigurationTier)

    foreach ($requiredPath in @($defaultConfigPath, $tierConfigPath)) {
        if (-not (Test-Path -Path $requiredPath)) {
            throw ('Required configuration file not found: {0}' -f $requiredPath)
        }
    }

    $defaultConfig = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json
    $tierConfig = Get-Content -Path $tierConfigPath -Raw | ConvertFrom-Json

    $dependencyState = foreach ($dependency in $script:Dependencies) {
        $dependencyPath = Join-Path $repoRoot ("solutions\{0}" -f $dependency)
        $dependencyExportScript = Join-Path $dependencyPath 'scripts\Export-Evidence.ps1'

        [pscustomobject]@{
            solutionSlug = $dependency
            solutionPath = $dependencyPath
            solutionFolderPresent = (Test-Path -Path $dependencyPath)
            exportScriptPresent = (Test-Path -Path $dependencyExportScript)
            deployedState = if ((Test-Path -Path $dependencyPath) -and (Test-Path -Path $dependencyExportScript)) { 'repository-present' } else { 'missing' }
        }
    }

    $missingDependencies = @($dependencyState | Where-Object { -not $_.solutionFolderPresent -or -not $_.exportScriptPresent })
    if ($missingDependencies.Count -gt 0) {
        $missingList = ($missingDependencies | ForEach-Object { $_.solutionSlug }) -join ', '
        throw ('Missing dependency solution content: {0}' -f $missingList)
    }

    $evidenceInventory = @(Get-SolutionEvidenceInventory -RepositoryRoot $repoRoot -CurrentSolutionSlug $script:SolutionSlug)
    $controlStatusSnapshot = @(New-ControlStatusSnapshot -EvidenceInventory $evidenceInventory -Tier $ConfigurationTier)
    $dataverseInitialization = Initialize-DashboardDataverse -TargetEnvironment $Environment -TargetDataverseUrl $DataverseUrl

    $generatedAt = (Get-Date).ToString('o')
    $snapshotPath = Join-Path $OutputPath 'rcd-control-status-snapshot.json'
    $baselineSeedPath = Join-Path $OutputPath 'rcd-dataverse-baseline-seed.json'
    $dataverseContractPath = Join-Path $OutputPath 'rcd-dataverse-contract.json'
    $manifestPath = Join-Path $OutputPath 'rcd-deployment-manifest.json'

    $snapshotEnvelope = [ordered]@{
        metadata = [ordered]@{
            solution = $script:SolutionSlug
            solutionCode = $script:SolutionCode
            displayName = $script:SolutionName
            configurationTier = $ConfigurationTier
            generatedAt = $generatedAt
            runtimeMode = $script:RuntimeMode
            warning = $script:RuntimeWarning
        }
        controls = $controlStatusSnapshot
    }

    $baselineSeed = [ordered]@{
        table = 'fsi_cg_rcd_baseline'
        generatedAt = $generatedAt
        runtimeMode = $script:RuntimeMode
        warning = $script:RuntimeWarning
        rows = $controlStatusSnapshot
    }

    $deploymentManifest = [ordered]@{
        metadata = [ordered]@{
            solution = $script:SolutionSlug
            solutionCode = $script:SolutionCode
            displayName = $script:SolutionName
            configurationTier = $ConfigurationTier
            tenantId = $TenantId
            environment = $Environment
            dataverseUrl = $DataverseUrl
            generatedAt = $generatedAt
            runtimeMode = $script:RuntimeMode
            warning = $script:RuntimeWarning
        }
        dependencies = $dependencyState
        defaultConfig = $defaultConfig
        tierConfig = $tierConfig
        evidenceInventory = $evidenceInventory
        dataverse = $dataverseInitialization
        powerBI = [ordered]@{
            documentationLed = $true
            templateName = $defaultConfig.powerBI.templateName
            datasetTables = $defaultConfig.powerBI.datasetTables
            rowLevelSecurityRoles = $defaultConfig.powerBI.rowLevelSecurityRoles
        }
        outputs = [ordered]@{
            controlStatusSnapshot = $snapshotPath
            dataverseBaselineSeed = $baselineSeedPath
            dataverseContract = $dataverseContractPath
            deploymentManifest = $manifestPath
        }
    }

    if ($PSCmdlet.ShouldProcess($script:SolutionName, 'Write Dataverse seed artifacts and deployment manifest')) {
        $null = New-Item -ItemType Directory -Path $OutputPath -Force
        $snapshotEnvelope | ConvertTo-Json -Depth 10 | Set-Content -Path $snapshotPath -Encoding utf8
        $baselineSeed | ConvertTo-Json -Depth 10 | Set-Content -Path $baselineSeedPath -Encoding utf8
        $dataverseInitialization | ConvertTo-Json -Depth 10 | Set-Content -Path $dataverseContractPath -Encoding utf8
        $deploymentManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding utf8
    }

    [pscustomobject]@{
        Solution = $script:SolutionName
        SolutionCode = $script:SolutionCode
        Tier = $ConfigurationTier
        TenantId = $TenantId
        Environment = $Environment
        DataverseUrl = $DataverseUrl
        DependencyCount = $dependencyState.Count
        EvidenceSourcesDiscovered = @($evidenceInventory | Where-Object { $_.availability -eq 'available' }).Count
        SnapshotControlCount = $controlStatusSnapshot.Count
        ManifestPath = $manifestPath
        SnapshotPath = $snapshotPath
        DataverseContractPath = $dataverseContractPath
        RuntimeMode = $script:RuntimeMode
    }
}
catch {
    Write-Error -Message ('Deployment initialization failed: {0}' -f $_.Exception.Message)
    throw
}
