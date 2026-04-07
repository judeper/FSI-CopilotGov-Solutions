<#
.SYNOPSIS
Prepares a risk-tiered Copilot rollout wave manifest.

.DESCRIPTION
Loads default and tier-specific configuration for Risk-Tiered Rollout Automation, validates the
01-copilot-readiness-scanner dependency, classifies a representative user population by risk tier,
evaluates wave readiness, and writes a structured manifest for the requested wave. When requested,
the script also stages license-assignment actions for the approved cohort. The script is a
documentation-first implementation stub and does not call Microsoft Graph directly.

.PARAMETER ConfigurationTier
Governance tier to apply. Valid values are baseline, recommended, and regulated.

.PARAMETER OutputPath
Directory where rollout manifests are written.

.PARAMETER TenantId
Tenant identifier or primary verified domain for the target environment.

.PARAMETER WaveNumber
Wave to prepare. Valid values are 0 through 3.

.PARAMETER Environment
Friendly environment label such as Sandbox, Pilot, UAT, or Production.

.PARAMETER TriggerLicenseAssignment
Stages license-assignment actions in the manifest for the selected cohort. Use -WhatIf to preview.

.EXAMPLE
pwsh -File .\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId "contoso.onmicrosoft.com" -WaveNumber 0 -Environment "Pilot" -WhatIf

.EXAMPLE
pwsh -File .\Deploy-Solution.ps1 -ConfigurationTier regulated -TenantId "contoso.onmicrosoft.com" -WaveNumber 3 -Environment "Production" -TriggerLicenseAssignment

.NOTES
This script supports WhatIf and is intended to be extended with tenant-specific API integrations.
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
    [ValidateRange(0, 3)]
    [int]$WaveNumber = 0,

    [Parameter()]
    [string]$Environment = 'Sandbox',

    [Parameter()]
    [switch]$TriggerLicenseAssignment
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force
Import-Module (Join-Path $solutionRoot 'scripts\RolloutConfig.psm1') -Force

function Resolve-DependencyArtifactPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactPath
    )

    if ([System.IO.Path]::IsPathRooted($ArtifactPath)) {
        return $ArtifactPath
    }

    return Join-Path $repoRoot $ArtifactPath
}

function Test-ReadinessScannerDependency {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration
    )

    $dependencyConfig = $Configuration.dependencies.readinessScanner
    $artifactPath = Resolve-DependencyArtifactPath -ArtifactPath $dependencyConfig.requiredArtifactPath

    if (-not (Test-Path -Path $artifactPath)) {
        throw "Required readiness scanner evidence file was not found: $artifactPath"
    }

    $artifact = Get-Content -Path $artifactPath -Raw | ConvertFrom-Json -AsHashtable -Depth 20
    $exportedAt = [datetime]$artifact.metadata.exportedAt
    $ageDays = [math]::Round(((Get-Date) - $exportedAt).TotalDays, 2)
    $maxAgeDays = [double]$dependencyConfig.maxArtifactAgeDays
    $isFresh = $ageDays -le $maxAgeDays

    if (-not $isFresh) {
        throw "Readiness scanner evidence is stale. AgeDays=$ageDays, MaximumAgeDays=$maxAgeDays"
    }

    return [pscustomobject]@{
        Solution = $artifact.metadata.solution
        ArtifactPath = $artifactPath
        Tier = $artifact.metadata.tier
        ExportedAt = $artifact.metadata.exportedAt
        AgeDays = $ageDays
        OverallStatus = $artifact.summary.overallStatus
        IsSatisfied = $true
    }
}

function Get-SeedUserPopulation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantIdentifier
    )

    $domain = if ($TenantIdentifier -match '\.') { $TenantIdentifier } else { 'example.fs' }

    return @(
        [pscustomobject]@{ UserPrincipalName = "ava.singh@$domain"; Department = 'Operations'; JobTitle = 'Operations Analyst'; IsPrivileged = $false; RequiresSupervision = $false; ReadinessScore = 95; DlpReady = $true; SupervisionReady = $true; CaPolicyReady = $true; AuditTrailReady = $true }
        [pscustomobject]@{ UserPrincipalName = "noah.reyes@$domain"; Department = 'Finance'; JobTitle = 'Finance Manager'; IsPrivileged = $false; RequiresSupervision = $false; ReadinessScore = 88; DlpReady = $true; SupervisionReady = $true; CaPolicyReady = $true; AuditTrailReady = $true }
        [pscustomobject]@{ UserPrincipalName = "zoe.carter@$domain"; Department = 'Compliance'; JobTitle = 'Compliance Officer'; IsPrivileged = $false; RequiresSupervision = $true; ReadinessScore = 91; DlpReady = $true; SupervisionReady = $true; CaPolicyReady = $true; AuditTrailReady = $true }
        [pscustomobject]@{ UserPrincipalName = "maya.evans@$domain"; Department = 'Legal'; JobTitle = 'Legal Counsel'; IsPrivileged = $false; RequiresSupervision = $true; ReadinessScore = 84; DlpReady = $true; SupervisionReady = $true; CaPolicyReady = $true; AuditTrailReady = $true }
        [pscustomobject]@{ UserPrincipalName = "liam.turner@$domain"; Department = 'Human Resources'; JobTitle = 'HR Business Partner'; IsPrivileged = $false; RequiresSupervision = $true; ReadinessScore = 79; DlpReady = $false; SupervisionReady = $true; CaPolicyReady = $true; AuditTrailReady = $true }
        [pscustomobject]@{ UserPrincipalName = "olivia.brooks@$domain"; Department = 'Executive'; JobTitle = 'Chief Risk Officer'; IsPrivileged = $true; RequiresSupervision = $false; ReadinessScore = 93; DlpReady = $true; SupervisionReady = $true; CaPolicyReady = $true; AuditTrailReady = $true }
        [pscustomobject]@{ UserPrincipalName = "ethan.hughes@$domain"; Department = 'IT Administration'; JobTitle = 'Systems Administrator'; IsPrivileged = $true; RequiresSupervision = $false; ReadinessScore = 87; DlpReady = $true; SupervisionReady = $true; CaPolicyReady = $false; AuditTrailReady = $true }
        [pscustomobject]@{ UserPrincipalName = "sophia.ward@$domain"; Department = 'Trading'; JobTitle = 'Equities Trader'; IsPrivileged = $true; RequiresSupervision = $false; ReadinessScore = 94; DlpReady = $true; SupervisionReady = $true; CaPolicyReady = $true; AuditTrailReady = $false }
        [pscustomobject]@{ UserPrincipalName = "jack.lee@$domain"; Department = 'Retail Banking'; JobTitle = 'Branch Support Specialist'; IsPrivileged = $false; RequiresSupervision = $false; ReadinessScore = 76; DlpReady = $true; SupervisionReady = $true; CaPolicyReady = $true; AuditTrailReady = $true }
        [pscustomobject]@{ UserPrincipalName = "emma.wright@$domain"; Department = 'Wealth Support'; JobTitle = 'Wealth Support Lead'; IsPrivileged = $false; RequiresSupervision = $false; ReadinessScore = 81; DlpReady = $true; SupervisionReady = $true; CaPolicyReady = $true; AuditTrailReady = $true }
        [pscustomobject]@{ UserPrincipalName = "harper.kim@$domain"; Department = 'Operations'; JobTitle = 'Operations Manager'; IsPrivileged = $false; RequiresSupervision = $false; ReadinessScore = 69; DlpReady = $true; SupervisionReady = $true; CaPolicyReady = $true; AuditTrailReady = $true }
        [pscustomobject]@{ UserPrincipalName = "lucas.green@$domain"; Department = 'Compliance'; JobTitle = 'Compliance Analyst'; IsPrivileged = $false; RequiresSupervision = $true; ReadinessScore = 88; DlpReady = $true; SupervisionReady = $false; CaPolicyReady = $true; AuditTrailReady = $true }
    )
}

function Get-UserRiskTier {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$User,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration
    )

    $tier2Departments = @($Configuration.riskTierCriteria.tier2.departments)
    $tier3Departments = @($Configuration.riskTierCriteria.tier3.departments)

    if (
        $User.IsPrivileged -or
        ($tier3Departments -contains $User.Department) -or
        ($User.JobTitle -match '\b(Chief|Trader|Administrator)\b')
    ) {
        return 'Tier3'
    }

    if (
        $User.RequiresSupervision -or
        ($tier2Departments -contains $User.Department) -or
        ($User.JobTitle -match '\b(Compliance|Counsel|HR)\b')
    ) {
        return 'Tier2'
    }

    return 'Tier1'
}

function Get-MinimumReadinessScore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RiskTier,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration
    )

    switch ($RiskTier) {
        'Tier1' { return [int]$Configuration.riskTierCriteria.tier1.minimumReadinessScore }
        'Tier2' { return [int]$Configuration.riskTierCriteria.tier2.minimumReadinessScore }
        'Tier3' { return [int]$Configuration.riskTierCriteria.tier3.minimumReadinessScore }
        default { throw "Unsupported risk tier: $RiskTier" }
    }
}

function Invoke-WaveReadinessCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$CandidateUsers,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$WaveDefinition,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration
    )

    $eligibleUsers = @($CandidateUsers | Where-Object { $WaveDefinition.includedRiskTiers -contains $_.RiskTier })
    $assessments = @()

    foreach ($user in $eligibleUsers) {
        $blockers = @()
        $minimumReadinessScore = Get-MinimumReadinessScore -RiskTier $user.RiskTier -Configuration $Configuration

        if ([int]$user.ReadinessScore -lt $minimumReadinessScore) {
            $blockers += 'ReadinessScoreBelowThreshold'
        }

        if (($user.RiskTier -eq 'Tier2' -or $user.RiskTier -eq 'Tier3') -and -not [bool]$user.DlpReady) {
            $blockers += 'DlpReady'
        }

        if ($user.RiskTier -eq 'Tier2' -and -not [bool]$user.SupervisionReady) {
            $blockers += 'SupervisionReady'
        }

        if ($user.RiskTier -eq 'Tier3' -and -not [bool]$user.CaPolicyReady) {
            $blockers += 'CaPolicyReady'
        }

        if ($user.RiskTier -eq 'Tier3' -and -not [bool]$user.AuditTrailReady) {
            $blockers += 'AuditTrailReady'
        }

        $assessments += [pscustomobject]@{
            UserPrincipalName = $user.UserPrincipalName
            Department = $user.Department
            JobTitle = $user.JobTitle
            RiskTier = $user.RiskTier
            ReadinessScore = $user.ReadinessScore
            Blockers = $blockers
            IsReady = ($blockers.Count -eq 0)
        }
    }

    $readyUsers = @($assessments | Where-Object { $_.IsReady })
    $cohortUsers = @($readyUsers | Select-Object -First ([int]$WaveDefinition.maxUsers))
    $queuedUsers = @($readyUsers | Select-Object -Skip ([int]$WaveDefinition.maxUsers))
    $blockedUsers = @($assessments | Where-Object { -not $_.IsReady })

    $thresholdPercent = if ([int]$WaveDefinition.waveNumber -eq 0) {
        [double]$Configuration.gateThresholds.minimumPilotReadinessPercent
    }
    else {
        [double]$Configuration.gateThresholds.minimumExpansionReadinessPercent
    }

    $readinessPercent = if ($eligibleUsers.Count -eq 0) {
        0
    }
    else {
        [math]::Round(($readyUsers.Count / [double]$eligibleUsers.Count) * 100, 2)
    }

    return [pscustomobject]@{
        EligibleUserCount = $eligibleUsers.Count
        ReadyUserCount = $readyUsers.Count
        BlockedUserCount = $blockedUsers.Count
        ReadinessPercent = $readinessPercent
        GateReady = ($readinessPercent -ge $thresholdPercent)
        CohortUsers = $cohortUsers
        QueuedUsers = $queuedUsers
        BlockedUsers = $blockedUsers
    }
}

function New-WaveManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$WaveDefinition,

        [Parameter(Mandatory)]
        [pscustomobject]$DependencyStatus,

        [Parameter(Mandatory)]
        [pscustomobject]$ReadinessResult,

        [Parameter(Mandatory)]
        [string]$TenantIdentifier,

        [Parameter(Mandatory)]
        [string]$TargetEnvironment,

        [Parameter(Mandatory)]
        [string]$SelectedTier,

        [Parameter(Mandatory)]
        [object[]]$LicenseAssignmentActions,

        [Parameter(Mandatory)]
        [string]$LicenseAssignmentMode
    )

    return [pscustomobject]@{
        solution = $Configuration.solution
        solutionCode = $Configuration.solutionCode
        displayName = $Configuration.displayName
        configurationTier = $SelectedTier
        tenantId = $TenantIdentifier
        environment = $TargetEnvironment
        generatedAt = (Get-Date).ToString('o')
        dependency = $DependencyStatus
        dataverse = [pscustomobject]@{
            baselineTable = $Configuration.dataverse.tables.baseline
            findingTable = $Configuration.dataverse.tables.finding
            evidenceTable = $Configuration.dataverse.tables.evidence
        }
        wave = [pscustomobject]@{
            waveNumber = [int]$WaveDefinition.waveNumber
            name = $WaveDefinition.name
            maxUsers = [int]$WaveDefinition.maxUsers
            includedRiskTiers = @($WaveDefinition.includedRiskTiers)
            gateCriteria = @($WaveDefinition.gateCriteria)
            approvalMode = $WaveDefinition.approvalMode
        }
        readinessSummary = [pscustomobject]@{
            eligibleUserCount = $ReadinessResult.EligibleUserCount
            readyUserCount = $ReadinessResult.ReadyUserCount
            blockedUserCount = $ReadinessResult.BlockedUserCount
            readinessPercent = $ReadinessResult.ReadinessPercent
            gateReady = $ReadinessResult.GateReady
        }
        cohort = @(
            $ReadinessResult.CohortUsers | ForEach-Object {
                [pscustomobject]@{
                    userPrincipalName = $_.UserPrincipalName
                    department = $_.Department
                    jobTitle = $_.JobTitle
                    riskTier = $_.RiskTier
                    assignmentState = if ($LicenseAssignmentMode -eq 'staged') { 'pending-assignment' } else { 'manifest-only' }
                }
            }
        )
        piiNotice = 'This manifest contains user principal names and organizational metadata. Handle according to data-classification policies and GDPR/GLBA requirements. Restrict access to authorized rollout operators.'
        blockedUsers = @(
            $ReadinessResult.BlockedUsers | ForEach-Object {
                [pscustomobject]@{
                    userPrincipalName = $_.UserPrincipalName
                    riskTier = $_.RiskTier
                    blockers = @($_.Blockers)
                    readinessScore = $_.ReadinessScore
                }
            }
        )
        queuedUsers = @(
            $ReadinessResult.QueuedUsers | ForEach-Object {
                [pscustomobject]@{
                    userPrincipalName = $_.UserPrincipalName
                    riskTier = $_.RiskTier
                    readinessScore = $_.ReadinessScore
                }
            }
        )
        licenseAssignment = [pscustomobject]@{
            requested = ($LicenseAssignmentMode -ne 'not-requested')
            mode = $LicenseAssignmentMode
            skuPartNumber = $Configuration.licenseAssignment.skuPartNumber
            groupMode = $Configuration.licenseAssignment.groupMode
            actions = $LicenseAssignmentActions
        }
    }
}

try {
    $configuration = Get-RolloutConfiguration -Tier $ConfigurationTier -SolutionRoot $solutionRoot
    $waveDefinition = @($configuration.waveDefinitions | Where-Object { [int]$_.waveNumber -eq $WaveNumber })

    if ($waveDefinition.Count -eq 0) {
        throw "Wave $WaveNumber is not configured for tier '$ConfigurationTier'."
    }

    $dependencyStatus = Test-ReadinessScannerDependency -Configuration $configuration
    $candidateUsers = @()

    foreach ($user in (Get-SeedUserPopulation -TenantIdentifier $TenantId)) {
        $candidateUsers += [pscustomobject]@{
            UserPrincipalName = $user.UserPrincipalName
            Department = $user.Department
            JobTitle = $user.JobTitle
            IsPrivileged = $user.IsPrivileged
            RequiresSupervision = $user.RequiresSupervision
            ReadinessScore = $user.ReadinessScore
            DlpReady = $user.DlpReady
            SupervisionReady = $user.SupervisionReady
            CaPolicyReady = $user.CaPolicyReady
            AuditTrailReady = $user.AuditTrailReady
            RiskTier = Get-UserRiskTier -User $user -Configuration $configuration
        }
    }

    $readinessResult = Invoke-WaveReadinessCheck -CandidateUsers $candidateUsers -WaveDefinition $waveDefinition[0] -Configuration $configuration
    $licenseAssignmentActions = @()
    $licenseAssignmentMode = 'not-requested'

    if ($TriggerLicenseAssignment -and $readinessResult.CohortUsers.Count -gt 0) {
        $licenseAssignmentActions = @(
            $readinessResult.CohortUsers | ForEach-Object {
                [pscustomobject]@{
                    userPrincipalName = $_.UserPrincipalName
                    waveNumber = $WaveNumber
                    riskTier = $_.RiskTier
                    skuPartNumber = $configuration.licenseAssignment.skuPartNumber
                    requestedAt = (Get-Date).ToString('o')
                }
            }
        )

        if ($PSCmdlet.ShouldProcess("Wave $WaveNumber", "Stage Copilot license assignments for $($licenseAssignmentActions.Count) users")) {
            $licenseAssignmentMode = 'staged'
        }
        else {
            $licenseAssignmentMode = 'preview'
        }
    }

    $manifest = New-WaveManifest `
        -Configuration $configuration `
        -WaveDefinition $waveDefinition[0] `
        -DependencyStatus $dependencyStatus `
        -ReadinessResult $readinessResult `
        -TenantIdentifier $TenantId `
        -TargetEnvironment $Environment `
        -SelectedTier $ConfigurationTier `
        -LicenseAssignmentActions $licenseAssignmentActions `
        -LicenseAssignmentMode $licenseAssignmentMode

    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $manifestPath = Join-Path $OutputPath ("RTR-wave-{0}-manifest.json" -f $WaveNumber)

    if ($PSCmdlet.ShouldProcess($manifestPath, 'Write wave manifest')) {
        $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding utf8
    }

    Write-Output $manifest
}
catch {
    $message = "Risk-tiered rollout deployment failed: $($_.Exception.Message)"
    Write-Error $message
    throw
}
