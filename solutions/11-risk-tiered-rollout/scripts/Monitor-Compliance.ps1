<#
.SYNOPSIS
Monitors the status of a configured rollout wave.

.DESCRIPTION
Loads the selected governance tier, reads the current wave manifest when available, evaluates
gate criteria, identifies users awaiting assignment, records blocked users, and calculates a wave
health score suitable for operational dashboards. This script is a documentation-first monitoring
stub and should be extended with live tenant telemetry during implementation.

.PARAMETER ConfigurationTier
Governance tier to evaluate. Valid values are baseline, recommended, and regulated.

.PARAMETER WaveNumber
Wave to evaluate. Valid values are 0 through 3.

.PARAMETER OutputPath
Directory containing wave manifests and where monitoring snapshots will be written.

.EXAMPLE
pwsh -File .\Monitor-Compliance.ps1 -ConfigurationTier recommended -WaveNumber 1

.EXAMPLE
pwsh -File .\Monitor-Compliance.ps1 -ConfigurationTier regulated -WaveNumber 3 -OutputPath .\artifacts

.NOTES
The health score combines gate completion, assignment progress, and blocker penalties.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [ValidateRange(0, 3)]
    [int]$WaveNumber = 0,

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:RuntimeMode = 'documentation-first-stub'
$script:StatusWarning = 'Wave health is derived from manifest state and representative sample criteria. License assignments remain staged-only until customer-run integrations are added.'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force

function Read-JsonConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw "File was not found: $Path"
    }

    return Get-Content -Path $Path -Raw | ConvertFrom-Json -AsHashtable -Depth 20
}

function Copy-ConfigValue {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $copy = [ordered]@{}
        foreach ($key in $Value.Keys) {
            $copy[$key] = Copy-ConfigValue -Value $Value[$key]
        }

        return $copy
    }

    if (($Value -is [System.Collections.IEnumerable]) -and -not ($Value -is [string])) {
        $items = @()
        foreach ($item in $Value) {
            $items += ,(Copy-ConfigValue -Value $item)
        }

        return $items
    }

    return $Value
}

function Merge-Hashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Base,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Overlay
    )

    $result = [ordered]@{}

    foreach ($key in $Base.Keys) {
        $result[$key] = Copy-ConfigValue -Value $Base[$key]
    }

    foreach ($key in $Overlay.Keys) {
        if (
            $result.Contains($key) -and
            ($result[$key] -is [System.Collections.IDictionary]) -and
            ($Overlay[$key] -is [System.Collections.IDictionary])
        ) {
            $result[$key] = Merge-Hashtable -Base $result[$key] -Overlay $Overlay[$key]
            continue
        }

        $result[$key] = Copy-ConfigValue -Value $Overlay[$key]
    }

    return $result
}

function Get-RolloutConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Tier
    )

    $defaultConfigPath = Join-Path $solutionRoot 'config\default-config.json'
    $tierConfigPath = Join-Path $solutionRoot ("config\{0}.json" -f $Tier)
    $defaultConfig = Read-JsonConfiguration -Path $defaultConfigPath
    $tierConfig = Read-JsonConfiguration -Path $tierConfigPath

    return Merge-Hashtable -Base $defaultConfig -Overlay $tierConfig
}

function Get-WaveStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration,

        [Parameter(Mandatory)]
        [int]$SelectedWaveNumber,

        [Parameter(Mandatory)]
        [string]$ArtifactRoot
    )

    $waveDefinition = @($Configuration.waveDefinitions | Where-Object { [int]$_.waveNumber -eq $SelectedWaveNumber })

    if ($waveDefinition.Count -eq 0) {
        throw "Wave $SelectedWaveNumber is not configured for tier '$ConfigurationTier'."
    }

    $manifestPath = Join-Path $ArtifactRoot ("RTR-wave-{0}-manifest.json" -f $SelectedWaveNumber)

    if (-not (Test-Path -Path $manifestPath)) {
        return [pscustomobject]@{
            HasManifest = $false
            ManifestPath = $manifestPath
            DeploymentState = 'NotStarted'
            WaveDefinition = [pscustomobject]$waveDefinition[0]
            EligibleUserCount = 0
            ReadyUserCount = 0
            ReadinessPercent = 0
            CohortUsers = @()
            AwaitingAssignmentUsers = @()
            BlockedUsers = @()
            DependencyStatus = [pscustomobject]@{
                IsSatisfied = $false
                Notes = 'Wave manifest not found. Run Deploy-Solution.ps1 first.'
            }
        }
    }

    $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json -Depth 20
    $cohortUsers = @($manifest.cohort)
    $blockedUsers = @($manifest.blockedUsers)
    $awaitingAssignmentUsers = @()

    if ($manifest.licenseAssignment.mode -ne 'assigned') {
        $awaitingAssignmentUsers = $cohortUsers
    }

    $deploymentState = if (-not [bool]$manifest.readinessSummary.gateReady) {
        'Blocked'
    }
    elseif ($awaitingAssignmentUsers.Count -gt 0) {
        'PendingAssignment'
    }
    else {
        'Completed'
    }

    return [pscustomobject]@{
        HasManifest = $true
        ManifestPath = $manifestPath
        DeploymentState = $deploymentState
        WaveDefinition = $manifest.wave
        EligibleUserCount = [int]$manifest.readinessSummary.eligibleUserCount
        ReadyUserCount = [int]$manifest.readinessSummary.readyUserCount
        ReadinessPercent = [double]$manifest.readinessSummary.readinessPercent
        CohortUsers = $cohortUsers
        AwaitingAssignmentUsers = $awaitingAssignmentUsers
        BlockedUsers = $blockedUsers
        DependencyStatus = $manifest.dependency
    }
}

function Test-GateCriteria {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$WaveStatus,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration
    )

    $criteriaResults = @()
    $blockedUsers = @($WaveStatus.BlockedUsers)
    $gateCriteria = @($WaveStatus.WaveDefinition.gateCriteria)

    foreach ($criterion in $gateCriteria) {
        $passed = $false
        $notes = ''

        switch ($criterion) {
            'scannerComplete' {
                $passed = [bool]$WaveStatus.DependencyStatus.IsSatisfied
                $notes = 'Readiness-scanner evidence must be current and present.'
            }
            'minimumReadinessScore' {
                $passed = [double]$WaveStatus.ReadinessPercent -ge [double]$Configuration.gateThresholds.minimumPilotReadinessPercent
                $notes = 'Wave 0 requires the configured pilot-readiness threshold.'
            }
            'serviceHealthGreen' {
                $passed = $blockedUsers.Count -le [int]$Configuration.gateThresholds.maximumOpenIncidents
                $notes = 'Blocked users should stay within the open-incident threshold.'
            }
            'supportDeskCoverage' {
                $passed = @($Configuration.notifications.summaryRecipients).Count -gt 0
                $notes = 'Support and notification contacts must be configured.'
            }
            'wave0Success' {
                $passed = [double]$WaveStatus.ReadinessPercent -ge [double]$Configuration.gateThresholds.minimumExpansionReadinessPercent
                $notes = 'Expansion requires stable pilot readiness.'
            }
            'dlpValidatedForTier2' {
                $passed = (@($blockedUsers | Where-Object { $_.riskTier -eq 'Tier2' -and ($_.blockers -contains 'DlpReady') }).Count -eq 0)
                $notes = 'Tier 2 users must pass DLP validation before expansion.'
            }
            'supervisionCoverage' {
                $passed = (@($blockedUsers | Where-Object { $_.riskTier -eq 'Tier2' -and ($_.blockers -contains 'SupervisionReady') }).Count -eq 0)
                $notes = 'Tier 2 users require supervision readiness.'
            }
            'incidentThreshold' {
                $passed = $blockedUsers.Count -le [int]$Configuration.gateThresholds.maximumOpenIncidents
                $notes = 'Open findings and blocked users should remain under threshold.'
            }
            'trainingCompletion' {
                $passed = [bool]$Configuration.analytics.vivaInsightsEnabled
                $notes = 'Training completion is represented by the configured analytics feed in this stub.'
            }
            'backlogWithinThreshold' {
                $passed = $blockedUsers.Count -le [int]$Configuration.gateThresholds.maximumOpenIncidents
                $notes = 'Queued remediation items should remain within tolerance.'
            }
            'dashboardHealthy' {
                $passed = [double]$WaveStatus.ReadinessPercent -ge [double]$Configuration.powerBI.healthScoreWarningThreshold
                $notes = 'Wave readiness should stay above the dashboard warning threshold.'
            }
            'caPolicyValidated' {
                $passed = (@($blockedUsers | Where-Object { $_.riskTier -eq 'Tier3' -and ($_.blockers -contains 'CaPolicyReady') }).Count -eq 0)
                $notes = 'Tier 3 rollout requires Conditional Access validation.'
            }
            'auditTrailVerified' {
                $passed = (@($blockedUsers | Where-Object { $_.riskTier -eq 'Tier3' -and ($_.blockers -contains 'AuditTrailReady') }).Count -eq 0)
                $notes = 'Tier 3 rollout requires a complete audit trail.'
            }
            'dlpCoverage' {
                $passed = (@($blockedUsers | Where-Object { $_.blockers -contains 'DlpReady' }).Count -eq 0)
                $notes = 'All users in the wave must satisfy DLP requirements.'
            }
            'doraResilienceReview' {
                $passed = [bool]$Configuration.resilience.doraGateRequired
                $notes = 'Regulated rollout requires a documented DORA resilience review.'
            }
            default {
                $passed = $false
                $notes = 'Criterion is not yet instrumented in the current monitoring stub.'
            }
        }

        $criteriaResults += [pscustomobject]@{
            criterion = $criterion
            passed = $passed
            notes = $notes
        }
    }

    return [pscustomobject]@{
        Criteria = $criteriaResults
        CompletedCriteriaCount = @($criteriaResults | Where-Object { $_.passed }).Count
        TotalCriteriaCount = $criteriaResults.Count
        IsComplete = (@($criteriaResults | Where-Object { -not $_.passed }).Count -eq 0)
    }
}

function Measure-RolloutHealth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$WaveStatus,

        [Parameter(Mandatory)]
        [pscustomobject]$GateCriteriaResult
    )

    $criteriaCompletionPercent = if ($GateCriteriaResult.TotalCriteriaCount -eq 0) {
        0
    }
    else {
        [math]::Round(($GateCriteriaResult.CompletedCriteriaCount / [double]$GateCriteriaResult.TotalCriteriaCount) * 100, 2)
    }

    $assignmentProgressPercent = if (@($WaveStatus.CohortUsers).Count -eq 0) {
        0
    }
    elseif (@($WaveStatus.AwaitingAssignmentUsers).Count -eq 0) {
        100
    }
    else {
        [math]::Round(((@($WaveStatus.CohortUsers).Count - @($WaveStatus.AwaitingAssignmentUsers).Count) / [double]@($WaveStatus.CohortUsers).Count) * 100, 2)
    }

    $blockerPenalty = [math]::Min(40, @($WaveStatus.BlockedUsers).Count * 5)
    $score = [math]::Round((($criteriaCompletionPercent * 0.6) + ($assignmentProgressPercent * 0.4)) - $blockerPenalty, 2)
    $score = [math]::Max(0, [math]::Min(100, $score))

    $rawStatus = if ($score -ge 85) {
        'implemented'
    }
    elseif ($score -ge 60) {
        'partial'
    }
    elseif ($score -ge 35) {
        'monitor-only'
    }
    else {
        'playbook-only'
    }

    $status = if ($rawStatus -eq 'implemented') { 'partial' } else { $rawStatus }

    return [pscustomobject]@{
        Score = $score
        Status = $status
        StatusScore = Get-CopilotGovStatusScore -Status $status
        CriteriaCompletionPercent = $criteriaCompletionPercent
        AssignmentProgressPercent = $assignmentProgressPercent
        BlockerCount = @($WaveStatus.BlockedUsers).Count
        RuntimeMode = $script:RuntimeMode
        StatusBasis = if ($rawStatus -ne $status) { 'Implemented score downgraded to partial because rollout execution is staged-only in the repository.' } else { 'Documentation-first wave score derived from manifest state and representative sample criteria.' }
    }
}

try {
    $configuration = Get-RolloutConfiguration -Tier $ConfigurationTier
    $waveStatus = Get-WaveStatus -Configuration $configuration -SelectedWaveNumber $WaveNumber -ArtifactRoot $OutputPath
    $gateCriteria = Test-GateCriteria -WaveStatus $waveStatus -Configuration $configuration
    $waveHealth = Measure-RolloutHealth -WaveStatus $waveStatus -GateCriteriaResult $gateCriteria

    $result = [pscustomobject]@{
        solution = $configuration.solution
        solutionCode = $configuration.solutionCode
        configurationTier = $ConfigurationTier
        generatedAt = (Get-Date).ToString('o')
        runtimeMode = $script:RuntimeMode
        populationSource = 'representative-sample'
        assignmentExecution = 'staged-manifest-only'
        statusWarning = $script:StatusWarning
        waveNumber = $WaveNumber
        waveStatus = $waveStatus
        gateCriteria = $gateCriteria
        usersAwaitingAssignment = @(
            $waveStatus.AwaitingAssignmentUsers | ForEach-Object {
                [pscustomobject]@{
                    userPrincipalName = $_.userPrincipalName
                    riskTier = $_.riskTier
                    department = $_.department
                }
            }
        )
        blockedUsers = @(
            $waveStatus.BlockedUsers | ForEach-Object {
                [pscustomobject]@{
                    userPrincipalName = $_.userPrincipalName
                    riskTier = $_.riskTier
                    blockers = @($_.blockers)
                }
            }
        )
        waveHealth = $waveHealth
    }

    Write-Warning $script:StatusWarning
    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $statusPath = Join-Path $OutputPath ("RTR-wave-{0}-status.json" -f $WaveNumber)
    $result | ConvertTo-Json -Depth 10 | Set-Content -Path $statusPath -Encoding utf8

    Write-Output $result
}
catch {
    $message = "Risk-tiered rollout monitoring failed: $($_.Exception.Message)"
    Write-Error $message
    throw
}
