<#
.SYNOPSIS
Deploys the Sensitivity Label Coverage Auditor configuration for a target tenant.

.DESCRIPTION
Loads the solution default configuration together with the selected governance tier, resolves the
workloads to audit, records placeholder validation results for Purview licensing and label taxonomy
readiness, checks that upstream dependency solutions are present, and writes a deployment manifest
plus a deployment registration record. The validation routines are intentionally safe stubs so the
script can be used before tenant-specific Graph and Purview integrations are approved.

.PARAMETER ConfigurationTier
The governance tier to deploy. Valid values are baseline, recommended, and regulated.

.PARAMETER OutputPath
Directory where deployment artifacts are written.

.PARAMETER TenantId
The Microsoft Entra tenant ID or primary tenant domain for the target deployment.

.PARAMETER WorkloadsToAudit
Optional workload override. When omitted, the workloads defined by the selected tier are used.

.EXAMPLE
.\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId "contoso.onmicrosoft.com"

.EXAMPLE
.\Deploy-Solution.ps1 -ConfigurationTier regulated -TenantId "00000000-0000-0000-0000-000000000000" -WorkloadsToAudit sharePoint,exchange -WhatIf

.NOTES
This is a solution-specific implementation stub. Replace placeholder validation functions with
tenant-approved Microsoft Graph and Purview checks before enabling automated enforcement.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\deployment'),

    [Parameter(Mandatory)]
    [string]$TenantId,

    [Parameter()]
    [ValidateSet('sharePoint', 'oneDrive', 'exchange')]
    [string[]]$WorkloadsToAudit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-SolutionRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}

function Resolve-OptionalPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (Test-Path -Path $Path) {
        return (Resolve-Path -Path $Path).Path
    }

    return $Path
}

function Read-JsonFile {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw "Required file not found: $Path"
    }

    return Get-Content -Path $Path -Raw -Encoding utf8 | ConvertFrom-Json -Depth 20
}

function Get-ResolvedConfiguration {
    param(
        [Parameter(Mandatory)]
        [string]$Tier,

        [string[]]$RequestedWorkloads
    )

    $solutionRoot = Get-SolutionRoot
    $defaultConfig = Read-JsonFile -Path (Join-Path $solutionRoot 'config\default-config.json')
    $tierConfig = Read-JsonFile -Path (Join-Path $solutionRoot ("config\{0}.json" -f $Tier))

    $resolvedWorkloads = if ($RequestedWorkloads -and $RequestedWorkloads.Count -gt 0) {
        @($RequestedWorkloads | Select-Object -Unique)
    }
    else {
        @($tierConfig.workloadsToAudit)
    }

    return [pscustomobject]@{
        solution = $defaultConfig.solution
        solutionCode = $defaultConfig.solutionCode
        displayName = $defaultConfig.displayName
        version = $defaultConfig.version
        tier = $tierConfig.tier
        controls = @($defaultConfig.controls)
        track = $defaultConfig.track
        priority = $defaultConfig.priority
        phase = $defaultConfig.phase
        solutionType = $defaultConfig.solutionType
        regulations = @($defaultConfig.regulations)
        evidenceOutputs = @($defaultConfig.evidenceOutputs)
        defaults = $defaultConfig.defaults
        graphApiVersion = $defaultConfig.graphApiVersion
        labelTaxonomy = @($defaultConfig.labelTaxonomy)
        coverageThreshold = $defaultConfig.coverageThreshold
        workloadsToAudit = $resolvedWorkloads
        prioritySites = @($defaultConfig.prioritySites)
        remediationManifestMaxItems = $defaultConfig.remediationManifestMaxItems
        tierSettings = $tierConfig
    }
}

function Test-PurviewLicensing {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration
    )

    $requiredSku = if ($Configuration.tier -eq 'baseline') {
        'Microsoft 365 E5 Compliance or equivalent'
    }
    else {
        'Microsoft 365 E5 Compliance or equivalent plus Purview Information Protection P2 for auto-labeling'
    }

    return [pscustomobject]@{
        status = 'placeholder'
        requiredSku = $requiredSku
        validatedAt = (Get-Date).ToString('s')
        notes = 'Manual confirmation required until tenant licensing checks are wired to Microsoft Graph and Purview.'
    }
}

function Test-LabelTaxonomyExists {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration
    )

    $taxonomyCount = @($Configuration.labelTaxonomy).Count
    $status = if ($taxonomyCount -gt 0) { 'placeholder' } else { 'failed' }

    return [pscustomobject]@{
        status = $status
        tierCount = $taxonomyCount
        validatedAt = (Get-Date).ToString('s')
        notes = 'Validate the configured taxonomy against the Purview portal before enabling bulk remediation.'
    }
}

function Get-LabelTaxonomySnapshot {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration
    )

    return [pscustomobject]@{
        snapshotTakenAt = (Get-Date).ToString('s')
        tiers = @(
            $Configuration.labelTaxonomy | ForEach-Object {
                [pscustomobject]@{
                    tier = $_.tier
                    name = $_.name
                    description = $_.description
                }
            }
        )
        notes = 'Snapshot sourced from config\default-config.json. Confirm against Purview before production rollout.'
    }
}

function Test-UpstreamDependencies {
    $solutionRoot = Get-SolutionRoot
    $dep01Path = Resolve-OptionalPath -Path (Join-Path $solutionRoot '..\01-copilot-readiness-scanner')
    $dep02Path = Resolve-OptionalPath -Path (Join-Path $solutionRoot '..\02-oversharing-risk-assessment')

    $dependencies = @(
        [pscustomobject]@{
            solution = '01-copilot-readiness-scanner'
            requiredState = 'baseline complete'
            location = $dep01Path
            status = if (Test-Path -Path $dep01Path) { 'detected' } else { 'not-found' }
            notes = 'Review readiness scope before enabling workload scans.'
        },
        [pscustomobject]@{
            solution = '02-oversharing-risk-assessment'
            requiredState = 'initial scan complete'
            location = $dep02Path
            status = if (Test-Path -Path $dep02Path) { 'detected' } else { 'not-found' }
            notes = 'Use oversharing findings to raise the priority of unlabeled regulated repositories.'
        }
    )

    return $dependencies
}

function New-DeploymentManifest {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration,

        [Parameter(Mandatory)]
        [pscustomobject]$LicensingCheck,

        [Parameter(Mandatory)]
        [pscustomobject]$TaxonomyCheck,

        [Parameter(Mandatory)]
        [pscustomobject]$TaxonomySnapshot,

        [Parameter(Mandatory)]
        [object[]]$Dependencies,

        [Parameter(Mandatory)]
        [string]$Tenant
    )

    return [pscustomobject]@{
        deploymentId = [guid]::NewGuid().Guid
        solution = $Configuration.solution
        solutionCode = $Configuration.solutionCode
        displayName = $Configuration.displayName
        version = $Configuration.version
        tenantId = $Tenant
        tier = $Configuration.tier
        workloadsToAudit = @($Configuration.workloadsToAudit)
        graphApiVersion = $Configuration.graphApiVersion
        licensingCheck = $LicensingCheck
        taxonomyCheck = $TaxonomyCheck
        labelTaxonomySnapshot = $TaxonomySnapshot
        upstreamDependencies = @($Dependencies)
        generatedAt = (Get-Date).ToString('s')
        notes = @(
            'Deployment registration created by solution 03 deployment stub.',
            'Replace placeholder prerequisite checks with tenant-approved automation before production use.'
        )
    }
}

$configuration = Get-ResolvedConfiguration -Tier $ConfigurationTier -RequestedWorkloads $WorkloadsToAudit
$licensingCheck = Test-PurviewLicensing -Configuration $configuration
$taxonomyCheck = Test-LabelTaxonomyExists -Configuration $configuration
$taxonomySnapshot = Get-LabelTaxonomySnapshot -Configuration $configuration
$dependencyChecks = Test-UpstreamDependencies
$deploymentManifest = New-DeploymentManifest -Configuration $configuration -LicensingCheck $licensingCheck -TaxonomyCheck $taxonomyCheck -TaxonomySnapshot $taxonomySnapshot -Dependencies $dependencyChecks -Tenant $TenantId

$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$manifestPath = Join-Path $resolvedOutputPath 'deployment-manifest.json'
$registrationPath = Join-Path $resolvedOutputPath 'deployment-registration.json'

if ($PSCmdlet.ShouldProcess($resolvedOutputPath, 'Create deployment manifest and registration record')) {
    $null = New-Item -Path $resolvedOutputPath -ItemType Directory -Force

    $deploymentManifest | ConvertTo-Json -Depth 20 | Set-Content -Path $manifestPath -Encoding utf8

    [pscustomobject]@{
        solution = $configuration.solution
        solutionCode = $configuration.solutionCode
        tenantId = $TenantId
        tier = $configuration.tier
        workloadsToAudit = @($configuration.workloadsToAudit)
        deploymentId = $deploymentManifest.deploymentId
        registeredAt = (Get-Date).ToString('s')
        status = 'registered'
        labelTaxonomyTierCount = @($configuration.labelTaxonomy).Count
    } | ConvertTo-Json -Depth 10 | Set-Content -Path $registrationPath -Encoding utf8
}

[pscustomobject]@{
    solution = $configuration.displayName
    solutionCode = $configuration.solutionCode
    version = $configuration.version
    tenantId = $TenantId
    tier = $configuration.tier
    workloadsToAudit = @($configuration.workloadsToAudit)
    deploymentManifestPath = $manifestPath
    registrationPath = $registrationPath
    licensingStatus = $licensingCheck.status
    taxonomyStatus = $taxonomyCheck.status
    upstreamDependencies = @($dependencyChecks | Select-Object solution, status, requiredState)
    nextAction = 'Run Monitor-Compliance.ps1 to generate initial label coverage metrics.'
}
