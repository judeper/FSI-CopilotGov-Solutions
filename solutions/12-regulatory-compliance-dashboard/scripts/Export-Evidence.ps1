<#
.SYNOPSIS
Exports Regulatory Compliance Dashboard evidence using the shared repository package contract.

.DESCRIPTION
Creates documentation-led control posture, framework coverage, and dashboard export artifacts for
the selected governance tier, writes SHA-256 companion files for every emitted artifact, and then
packages the export with the shared evidence schema.

.PARAMETER ConfigurationTier
Governance tier used to label the evidence package.

.PARAMETER OutputPath
Directory used for the evidence artifacts and packaged evidence file.

.EXAMPLE
pwsh .\Export-Evidence.ps1 -ConfigurationTier recommended -OutputPath 'C:\Temp\rcd'
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

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:RuntimeMode = 'documentation-first-seed'
$script:RuntimeWarning = 'Export-Evidence.ps1 emits seeded dashboard artifacts and package references; live Dataverse aggregation and Power BI publication are outside the repository state.'

Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force

function Read-JsonAsHashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return Get-Content -Path $Path -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable
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
        $result[$key] = $Base[$key]
    }

    foreach ($key in $Overlay.Keys) {
        if ($result.Contains($key) -and ($result[$key] -is [System.Collections.IDictionary]) -and ($Overlay[$key] -is [System.Collections.IDictionary])) {
            $result[$key] = Merge-Hashtable -Base $result[$key] -Overlay $Overlay[$key]
            continue
        }

        $result[$key] = $Overlay[$key]
    }

    return $result
}

function Get-RcdConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    $defaultConfig = Read-JsonAsHashtable -Path (Join-Path $solutionRoot 'config\default-config.json')
    $tierConfig = Read-JsonAsHashtable -Path (Join-Path $solutionRoot ("config\{0}.json" -f $Tier))
    return (Merge-Hashtable -Base $defaultConfig -Overlay $tierConfig)
}

function Write-ArtifactDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [object]$Content
    )

    $Content | ConvertTo-Json -Depth 20 | Set-Content -Path $Path -Encoding utf8
    $hashInfo = Write-CopilotGovSha256File -Path $Path

    return [pscustomobject]@{
        name = $Name
        type = 'json'
        path = $Path
        hash = $hashInfo.Hash
    }
}

try {

$config = Get-RcdConfiguration -Tier $ConfigurationTier
$resolvedOutputPath = [IO.Path]::GetFullPath($OutputPath)
$null = New-Item -ItemType Directory -Path $resolvedOutputPath -Force
$exportedAt = (Get-Date).ToString('o')

$controls = @(
    [pscustomobject]@{
        controlId = '3.7'
        status = 'partial'
        notes = 'Supports compliance reporting with seeded executive posture dashboards and cross-solution rollup metadata, but live aggregation remains outside the repository.'
    }
    [pscustomobject]@{
        controlId = '3.8'
        status = 'partial'
        notes = 'Supports examination readiness reporting, but package freshness depends on upstream evidence exports and a customer-implemented aggregation environment.'
    }
    [pscustomobject]@{
        controlId = '3.12'
        status = 'monitor-only'
        notes = 'Tracks evidence freshness, package hashes, and dashboard references while source solutions remain responsible for collection.'
    }
    [pscustomobject]@{
        controlId = '3.13'
        status = 'monitor-only'
        notes = 'Provides framework coverage views and third-party reporting references without replacing source evidence retention.'
    }
    [pscustomobject]@{
        controlId = '4.5'
        status = 'monitor-only'
        notes = 'Defines the reporting contract for usage analytics and adoption reporting, but connected telemetry feeds are not aggregated by the repository.'
    }
    [pscustomobject]@{
        controlId = '4.7'
        status = 'monitor-only'
        notes = 'Calculates maturity benchmarking and trend views from seeded control scores and dependency evidence references.'
    }
)

$controlStatusSnapshot = @(
    foreach ($control in $controls) {
        [pscustomobject]@{
            controlId = $control.controlId
            status = $control.status
            score = Get-CopilotGovStatusScore -Status $control.status
            lastEvidenceDate = $exportedAt
            solutionSlug = 'RCD'
            controlTitle = ('Regulatory dashboard status for control {0}' -f $control.controlId)
            tier = $ConfigurationTier
            sourceSolutions = @($config.dependencies)
            runtimeMode = $script:RuntimeMode
            dataSourceMode = 'documentation-first-seed'
            notes = $control.notes
        }
    }
)

$frameworkCoverageMatrix = @(
    foreach ($framework in @($config.enabledFrameworks)) {
        foreach ($control in $controls) {
            [pscustomobject]@{
                framework = $framework
                controlId = $control.controlId
                coverageState = if ($control.status -eq 'implemented') { 'covered' } else { 'monitoring' }
                sourceSolutions = @($config.dependencies)
                evidenceFreshnessState = if ([int]$config.freshnessThresholdHours -le 25) { 'current' } else { 'review-needed' }
                aggregationCadence = $config.aggregationCadence
                coverageBasis = $script:RuntimeMode
            }
        }
    }
)

$dashboardExport = [ordered]@{
    reportName = 'FSI Copilot Governance Dashboard'
    workspace = $config.defaults.dashboardWorkspace
    exportTimestamp = $exportedAt
    filters = [ordered]@{
        tier = $ConfigurationTier
        enabledFrameworks = @($config.enabledFrameworks)
        freshnessThresholdHours = [int]$config.freshnessThresholdHours
    }
    referencedEvidencePackages = @(
        foreach ($dependency in @($config.dependencies)) {
            [ordered]@{
                solution = $dependency
                packagePath = ('solutions\{0}\artifacts\{0}-evidence.json' -f $dependency)
                # Sibling evidence packages must be exported at runtime before hashes can be computed;
                # this placeholder is resolved by the RCD-EvidenceAggregator flow in the customer environment.
                hash = 'pending-runtime-resolution'
                freshnessStatus = if ([int]$config.freshnessThresholdHours -le 25) { 'current' } else { 'review-needed' }
            }
        }
    )
    selectedRegulatoryFramework = @($config.enabledFrameworks)
    packageOwner = 'Compliance Operations'
    reviewer = 'Regulatory Readiness Lead'
    maturityScoringEnabled = [bool]$config.maturityScoring.enabled
    runtimeMode = $script:RuntimeMode
    aggregationMode = 'documentation-first'
    warning = $script:RuntimeWarning
}

$controlArtifact = Write-ArtifactDocument -Path (Join-Path $resolvedOutputPath 'control-status-snapshot.json') -Name 'control-status-snapshot' -Content $controlStatusSnapshot
$coverageArtifact = Write-ArtifactDocument -Path (Join-Path $resolvedOutputPath 'framework-coverage-matrix.json') -Name 'framework-coverage-matrix' -Content $frameworkCoverageMatrix
$dashboardArtifact = Write-ArtifactDocument -Path (Join-Path $resolvedOutputPath 'dashboard-export.json') -Name 'dashboard-export' -Content $dashboardExport

$artifacts = @($controlArtifact, $coverageArtifact, $dashboardArtifact)
$package = Export-SolutionEvidencePackage `
    -Solution '12-regulatory-compliance-dashboard' `
    -SolutionCode 'RCD' `
    -Tier $ConfigurationTier `
    -OutputPath $resolvedOutputPath `
    -Summary @{
        overallStatus = 'partial'
        recordCount = ($controlStatusSnapshot.Count + $frameworkCoverageMatrix.Count + @($dashboardExport.referencedEvidencePackages).Count)
        findingCount = @($controls | Where-Object { $_.status -ne 'implemented' }).Count
        exceptionCount = @($controls | Where-Object { $_.status -eq 'monitor-only' }).Count
    } `
    -Controls $controls `
    -Artifacts $artifacts `
    -ExpectedArtifacts @($config.evidenceOutputs) `
    -AdditionalMetadata @{
        runtimeMode = $script:RuntimeMode
        aggregationMode = 'documentation-first'
        warning = $script:RuntimeWarning
    }

[pscustomobject]@{
    Package = $package
    Controls = $controls
    Artifacts = $artifacts
    RuntimeMode = $script:RuntimeMode
}

}
catch {
    Write-Error -Message ('Evidence export failed: {0}' -f $_.Exception.Message)
    throw
}
