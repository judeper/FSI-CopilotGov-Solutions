<#
.SYNOPSIS
Exports evidence for Risk-Tiered Rollout Automation.

.DESCRIPTION
Builds control-status evidence and writes supporting artifact files for wave readiness, approval
history, and rollout health. The script then packages the evidence by using the shared
Export-SolutionEvidencePackage function so the output aligns to the repository-wide evidence schema.

.PARAMETER ConfigurationTier
Governance tier to export. Valid values are baseline, recommended, and regulated.

.PARAMETER OutputPath
Directory where the evidence package and supporting artifacts are written.

.EXAMPLE
pwsh -File .\Export-Evidence.ps1 -ConfigurationTier recommended

.EXAMPLE
pwsh -File .\Export-Evidence.ps1 -ConfigurationTier regulated -OutputPath .\artifacts
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:RuntimeMode = 'documentation-first-stub'
$script:ExportWarning = 'Artifacts are generated from representative rollout logic and staged manifests; no live license assignment or workflow execution occurs in this repository state.'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force
Import-Module (Join-Path $solutionRoot 'scripts\RolloutConfig.psm1') -Force

function Get-ControlStatuses {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Tier
    )

    switch ($Tier) {
        'baseline' {
            return @(
                [pscustomobject]@{ controlId = '1.9'; status = 'partial'; notes = 'Wave-based seat reservation and cohort manifests support phased Copilot license planning for lower-risk pilot users, but Microsoft Graph license execution is outside this repository.' }
                [pscustomobject]@{ controlId = '1.11'; status = 'partial'; notes = 'Wave 0 and Wave 1 definitions document pilot management and controlled expansion for Tier 1 users, but rollout telemetry remains representative sample data.' }
                [pscustomobject]@{ controlId = '1.12'; status = 'monitor-only'; notes = 'Gate criteria are logged, but baseline deployments rely on summary approval handling rather than a live approval workflow.' }
                [pscustomobject]@{ controlId = '4.12'; status = 'monitor-only'; notes = 'Rollout blockers and rollback placeholders are tracked, but formal change-system integration remains outside the baseline repository scope.' }
            )
        }
        'recommended' {
            return @(
                [pscustomobject]@{ controlId = '1.9'; status = 'partial'; notes = 'Seat reservation, wave manifests, and assignment staging support structured Copilot license planning across Tier 1 and Tier 2 cohorts, but live assignment execution is customer-run.' }
                [pscustomobject]@{ controlId = '1.11'; status = 'partial'; notes = 'Three-wave sequencing and health monitoring support phased rollout planning, but health metrics remain derived from representative sample logic.' }
                [pscustomobject]@{ controlId = '1.12'; status = 'partial'; notes = 'Expansion gates and approval history support documented approval before Tier 2 rollout expansion, but Power Automate routing remains documentation-first.' }
                [pscustomobject]@{ controlId = '4.12'; status = 'monitor-only'; notes = 'Dashboard outputs and approval records support change tracking, while live change-system integration remains outside this repository.' }
            )
        }
        'regulated' {
            return @(
                [pscustomobject]@{ controlId = '1.9'; status = 'partial'; notes = 'Seat inventory, reserved rollback buffer, and wave-specific manifests support disciplined license planning across all risk tiers, but live assignment remains outside repository automation.' }
                [pscustomobject]@{ controlId = '1.11'; status = 'partial'; notes = 'Four-wave sequencing, including a dedicated Tier 3 release, supports phased rollout discipline for higher-risk users, but cohort evidence remains sample-derived.' }
                [pscustomobject]@{ controlId = '1.12'; status = 'partial'; notes = 'Gate criteria, approval capture, and CAB review are modeled in exported artifacts, but repository approval history remains documentation-first.' }
                [pscustomobject]@{ controlId = '4.12'; status = 'partial'; notes = 'Audit trail references, DORA resilience review markers, and retained approval history support change-management planning, but live change-system integration is not implemented here.' }
            )
        }
    }
}

function Get-SyntheticReadinessPercent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Tier,

        [Parameter(Mandatory)]
        [int]$WaveNumber
    )

    $map = @{
        baseline = @{ 0 = 96; 1 = 92 }
        recommended = @{ 0 = 97; 1 = 95; 2 = 91 }
        regulated = @{ 0 = 98; 1 = 96; 2 = 94; 3 = 90 }
    }

    return [int]$map[$Tier][$WaveNumber]
}

function New-WaveReadinessLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration,

        [Parameter(Mandatory)]
        [string]$Tier
    )

    $entries = @()

    foreach ($wave in $Configuration.waveDefinitions) {
        $readinessPercent = Get-SyntheticReadinessPercent -Tier $Tier -WaveNumber ([int]$wave.waveNumber)
        $blockedUsers = switch ([int]$wave.waveNumber) {
            0 { 1 }
            1 { 3 }
            2 { 6 }
            3 { 2 }
            default { 0 }
        }

        $entries += [pscustomobject]@{
            waveNumber = [int]$wave.waveNumber
            waveName = $wave.name
            includedRiskTiers = @($wave.includedRiskTiers)
            targetUsers = [int]$wave.maxUsers
            readinessPercent = $readinessPercent
            blockedUsers = $blockedUsers
            dependencyArtifact = $Configuration.dependencies.readinessScanner.requiredArtifactPath
            gateReady = if ([int]$wave.waveNumber -eq 0) {
                ($readinessPercent -ge [double]$Configuration.gateThresholds.minimumPilotReadinessPercent)
            } else {
                ($readinessPercent -ge [double]$Configuration.gateThresholds.minimumExpansionReadinessPercent)
            }
            generatedAt = (Get-Date).ToString('o')
            runtimeMode = $script:RuntimeMode
            dataSourceMode = 'representative-sample'
            warning = $script:ExportWarning
        }
    }

    return $entries
}

function New-ApprovalHistory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration
    )

    $history = @()

    foreach ($wave in $Configuration.waveDefinitions) {
        $approverRole = switch ($wave.approvalMode) {
            'business-owner' { 'Business Owner' }
            'control-owner' { 'Control Owner' }
            'rollout-board' { 'Rollout Governance Board' }
            'cab' { 'Change Advisory Board' }
            default { 'Rollout Owner' }
        }

        $history += [pscustomobject]@{
            waveNumber = [int]$wave.waveNumber
            approvalStage = $wave.approvalMode
            approverRole = $approverRole
            decision = 'approved'
            decisionTimestamp = (Get-Date).AddHours(-1 * ([int]$wave.waveNumber + 1)).ToString('o')
            ticketId = 'CAB-RTR-{0:000}' -f ([int]$wave.waveNumber + 1)
            notes = "Approval recorded for $($wave.name) after gate review and blocker assessment."
            runtimeMode = $script:RuntimeMode
            warning = $script:ExportWarning
        }
    }

    return $history
}

function New-RolloutHealthDashboard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$ReadinessLog,

        [Parameter(Mandatory)]
        [object[]]$ApprovalHistory,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration
    )

    $overallHealthScore = [math]::Round((($ReadinessLog.readinessPercent | Measure-Object -Average).Average), 2)
    $blockedUsers = ($ReadinessLog.blockedUsers | Measure-Object -Sum).Sum

    return [pscustomobject]@{
        dashboardName = $Configuration.powerBI.dashboard
        datasetName = $Configuration.powerBI.dataset
        overallHealthScore = $overallHealthScore
        status = if ($overallHealthScore -ge 90) { 'partial' } else { 'monitor-only' }
        pendingAssignments = 0
        blockedUsers = $blockedUsers
        openFindings = @($ReadinessLog | Where-Object { $_.blockedUsers -gt 0 }).Count
        pendingApprovals = @($ApprovalHistory | Where-Object { $_.decision -ne 'approved' }).Count
        waves = @(
            $ReadinessLog | ForEach-Object {
                [pscustomobject]@{
                    waveNumber = $_.waveNumber
                    readinessPercent = $_.readinessPercent
                    blockedUsers = $_.blockedUsers
                    gateReady = $_.gateReady
                }
            }
        )
        refreshedAt = (Get-Date).ToString('o')
        runtimeMode = $script:RuntimeMode
        warning = $script:ExportWarning
    }
}

function Write-ArtifactFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [object]$Data
    )

    $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding utf8
    $hashInfo = Write-CopilotGovSha256File -Path $Path

    return [pscustomobject]@{
        Path = $Path
        Hash = $hashInfo.Hash
    }
}

try {
    $configuration = Get-RolloutConfiguration -Tier $ConfigurationTier -SolutionRoot $solutionRoot
    $null = New-Item -ItemType Directory -Path $OutputPath -Force

    $waveReadinessLog = New-WaveReadinessLog -Configuration $configuration -Tier $ConfigurationTier
    $approvalHistory = New-ApprovalHistory -Configuration $configuration
    $rolloutHealthDashboard = New-RolloutHealthDashboard -ReadinessLog $waveReadinessLog -ApprovalHistory $approvalHistory -Configuration $configuration

    $readinessArtifact = Write-ArtifactFile -Path (Join-Path $OutputPath 'RTR-wave-readiness-log.json') -Data $waveReadinessLog
    $approvalArtifact = Write-ArtifactFile -Path (Join-Path $OutputPath 'RTR-approval-history.json') -Data $approvalHistory
    $dashboardArtifact = Write-ArtifactFile -Path (Join-Path $OutputPath 'RTR-rollout-health-dashboard.json') -Data $rolloutHealthDashboard

    $controls = Get-ControlStatuses -Tier $ConfigurationTier
    $findings = @($controls | Where-Object { $_.status -ne 'implemented' }).Count
    $overallStatus = if ($findings -gt 0) { 'partial' } else { 'implemented' }

    $artifacts = @(
        [pscustomobject]@{
            name = 'wave-readiness-log'
            type = 'json'
            path = $readinessArtifact.Path
            hash = $readinessArtifact.Hash
            description = 'Per-wave readiness coverage, target sizes, and blocked-user counts derived from the rollout design.'
        }
        [pscustomobject]@{
            name = 'approval-history'
            type = 'json'
            path = $approvalArtifact.Path
            hash = $approvalArtifact.Hash
            description = 'Decision history for wave expansion approvals across business-owner, control-owner, and CAB stages.'
        }
        [pscustomobject]@{
            name = 'rollout-health-dashboard'
            type = 'json'
            path = $dashboardArtifact.Path
            hash = $dashboardArtifact.Hash
            description = 'Dashboard snapshot showing health score, blocked users, and per-wave readiness state.'
        }
    )

    $package = Export-SolutionEvidencePackage `
        -Solution '11-risk-tiered-rollout' `
        -SolutionCode 'RTR' `
        -Tier $ConfigurationTier `
        -OutputPath $OutputPath `
        -Summary @{
            overallStatus = $overallStatus
            recordCount = ($waveReadinessLog.Count + $approvalHistory.Count + $rolloutHealthDashboard.waves.Count)
            findingCount = $findings
            exceptionCount = 0
        } `
        -Controls $controls `
        -Artifacts $artifacts `
        -ExpectedArtifacts @($configuration.evidenceOutputs) `
        -AdditionalMetadata @{
            runtimeMode = $script:RuntimeMode
            warning = $script:ExportWarning
            dataSourceMode = 'representative-sample'
        }

    [pscustomobject]@{
        Package = $package
        Controls = $controls
        Artifacts = $artifacts
        RuntimeMode = $script:RuntimeMode
    }
}
catch {
    $message = "Risk-tiered rollout evidence export failed: $($_.Exception.Message)"
    Write-Error $message
    throw
}
