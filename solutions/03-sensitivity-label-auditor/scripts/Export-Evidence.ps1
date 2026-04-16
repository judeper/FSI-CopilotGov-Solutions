<#
.SYNOPSIS
Exports evidence for the Sensitivity Label Coverage Auditor solution.

.DESCRIPTION
Invokes the monitoring script for the selected governance tier and reporting period, materializes the
label coverage report, label gap findings, and remediation manifest artifacts, and writes SHA-256
companion files for each JSON file. The evidence package aligns to the repository evidence contract
and records control status values that reflect monitoring and manual review boundaries.

.PARAMETER ConfigurationTier
The governance tier to export. Valid values are baseline, recommended, and regulated.

.PARAMETER OutputPath
Directory where evidence artifacts and the evidence package are written.

.PARAMETER TenantId
The Microsoft Entra tenant ID or primary tenant domain for the target export.

.PARAMETER PeriodStart
The start of the reporting period included in the export.

.PARAMETER PeriodEnd
The end of the reporting period included in the export.

.EXAMPLE
.\Export-Evidence.ps1 -ConfigurationTier recommended -TenantId "contoso.onmicrosoft.com"

.EXAMPLE
.\Export-Evidence.ps1 -ConfigurationTier regulated -TenantId "contoso.onmicrosoft.com" -PeriodStart (Get-Date).AddDays(-30) -PeriodEnd (Get-Date)

.NOTES
Control status mapping:
- 1.5 partial
- 2.2 monitor-only
- 3.11 partial
- 3.12 monitor-only
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\evidence'),

    [Parameter(Mandatory)]
    [string]$TenantId,

    [Parameter()]
    [datetime]$PeriodStart = (Get-Date).Date.AddDays(-7),

    [Parameter()]
    [datetime]$PeriodEnd = (Get-Date)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force

function Get-SolutionRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
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
        [string]$Tier
    )

    $solutionRoot = Get-SolutionRoot
    $defaultConfig = Read-JsonFile -Path (Join-Path $solutionRoot 'config\default-config.json')
    $tierConfig = Read-JsonFile -Path (Join-Path $solutionRoot ("config\{0}.json" -f $Tier))

    return [pscustomobject]@{
        solution = $defaultConfig.solution
        solutionCode = $defaultConfig.solutionCode
        displayName = $defaultConfig.displayName
        version = $defaultConfig.version
        tier = $tierConfig.tier
        controls = @($defaultConfig.controls)
        evidenceOutputs = @($defaultConfig.evidenceOutputs)
        tierSettings = $tierConfig
    }
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [object]$Content
    )

    if ($PSCmdlet.ShouldProcess($Path, 'Write evidence artifact')) {
        $Content | ConvertTo-Json -Depth 30 | Set-Content -Path $Path -Encoding utf8
    }
}

function Write-Sha256CompanionFile {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if ($PSCmdlet.ShouldProcess($Path, 'Write SHA-256 companion file')) {
        return (Write-CopilotGovSha256File -Path $Path)
    }

    return [pscustomobject]@{
        Hash     = 'whatif-placeholder'
        HashPath = "$Path.sha256"
    }
}

function New-ArtifactRecord {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Type,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Hash
    )

    return [pscustomobject]@{
        name = $Name
        type = $Type
        path = $Path
        hash = $Hash
    }
}

function Get-ControlStatuses {
    return @(
        [pscustomobject]@{
            controlId = '1.5'
            status = 'partial'
            notes = 'Sensitivity label taxonomy review is manual; the export records the snapshot reviewed.'
        },
        [pscustomobject]@{
            controlId = '2.2'
            status = 'monitor-only'
            notes = 'Labels are reported but not enforced by this script.'
        },
        [pscustomobject]@{
            controlId = '3.11'
            status = 'partial'
            notes = 'Coverage metrics support books-and-records classification review in regulated stores.'
        },
        [pscustomobject]@{
            controlId = '3.12'
            status = 'monitor-only'
            notes = 'Evidence collection is automated, but attestation remains a manual governance activity.'
        }
    )
}

$configuration = Get-ResolvedConfiguration -Tier $ConfigurationTier
$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$stagingPath = Join-Path $resolvedOutputPath 'staging'
$null = New-Item -Path $resolvedOutputPath -ItemType Directory -Force
$null = New-Item -Path $stagingPath -ItemType Directory -Force

$monitorScriptPath = Join-Path $PSScriptRoot 'Monitor-Compliance.ps1'
$monitorResult = & $monitorScriptPath -ConfigurationTier $ConfigurationTier -TenantId $TenantId -OutputPath $stagingPath

$exportedAt = (Get-Date).ToString('o')
$coveragePath = Join-Path $resolvedOutputPath 'label-coverage-report.json'
$gapFindingsPath = Join-Path $resolvedOutputPath 'label-gap-findings.json'
$remediationManifestPath = Join-Path $resolvedOutputPath 'remediation-manifest.json'
$packagePath = Join-Path $resolvedOutputPath 'evidence-package.json'

$coverageArtifact = [pscustomobject]@{
    metadata = [pscustomobject]@{
        solution = $configuration.solution
        solutionCode = $configuration.solutionCode
        tenantId = $TenantId
        tier = $ConfigurationTier
        exportedAt = $exportedAt
        periodStart = $PeriodStart.ToString('s')
        periodEnd = $PeriodEnd.ToString('s')
    }
    overall = $monitorResult.overall
    workloads = $monitorResult.workloads
    trend = [pscustomobject]@{
        previousRun = 'placeholder'
        notes = 'Trend comparison becomes available once prior evidence packages are retained.'
    }
}

$gapFindingsArtifact = [pscustomobject]@{
    metadata = [pscustomobject]@{
        solution = $configuration.solution
        solutionCode = $configuration.solutionCode
        tenantId = $TenantId
        tier = $ConfigurationTier
        exportedAt = $exportedAt
    }
    summary = [pscustomobject]@{
        findingCount = @($monitorResult.gapFindings).Count
        highPriorityCount = @($monitorResult.gapFindings | Where-Object { $_.priority -eq 'HIGH' }).Count
    }
    findings = $monitorResult.gapFindings
}

$remediationManifestArtifact = [pscustomobject]@{
    metadata = [pscustomobject]@{
        solution = $configuration.solution
        solutionCode = $configuration.solutionCode
        tenantId = $TenantId
        tier = $ConfigurationTier
        exportedAt = $exportedAt
    }
    summary = [pscustomobject]@{
        itemCount = @($monitorResult.remediationManifest).Count
        autoLabelingDailyCap = 100000
    }
    items = $monitorResult.remediationManifest
    executionConstraints = [pscustomobject]@{
        autoLabelingDailyCap = 100000
        notes = 'Plan remediation waves so tenant auto-labeling capacity is not exceeded.'
    }
}

Write-JsonFile -Path $coveragePath -Content $coverageArtifact
$coverageHash = Write-Sha256CompanionFile -Path $coveragePath
Write-JsonFile -Path $gapFindingsPath -Content $gapFindingsArtifact
$gapHash = Write-Sha256CompanionFile -Path $gapFindingsPath
Write-JsonFile -Path $remediationManifestPath -Content $remediationManifestArtifact
$manifestHash = Write-Sha256CompanionFile -Path $remediationManifestPath

$artifacts = @(
    New-ArtifactRecord -Name 'label-coverage-report' -Type 'json' -Path $coveragePath -Hash $coverageHash.Hash
    New-ArtifactRecord -Name 'label-gap-findings' -Type 'json' -Path $gapFindingsPath -Hash $gapHash.Hash
    New-ArtifactRecord -Name 'remediation-manifest' -Type 'json' -Path $remediationManifestPath -Hash $manifestHash.Hash
)

$summary = [pscustomobject]@{
    overallStatus = if ($monitorResult.thresholdStatus -eq 'below-threshold') { 'partial' } else { 'monitor-only' }
    recordCount = [int]$monitorResult.overall.totalItems
    findingCount = @($monitorResult.gapFindings).Count
    exceptionCount = @($monitorResult.gapFindings | Where-Object { $_.priority -eq 'HIGH' }).Count
}

$package = [pscustomobject]@{
    metadata = [pscustomobject]@{
        solution = $configuration.solution
        solutionCode = $configuration.solutionCode
        exportVersion = (Get-CopilotGovEvidenceSchemaVersion)
        exportedAt = $exportedAt
        tier = $ConfigurationTier
    }
    summary = $summary
    controls = Get-ControlStatuses
    artifacts = $artifacts
}

Write-JsonFile -Path $packagePath -Content $package
$packageHash = Write-Sha256CompanionFile -Path $packagePath
$validation = Test-CopilotGovEvidencePackage -Path $packagePath -ExpectedArtifacts @($configuration.evidenceOutputs)
if (-not $validation.IsValid) {
    $details = ($validation.Errors | ForEach-Object { ' - {0}' -f $_ }) -join [Environment]::NewLine
    throw ("Evidence validation failed for {0}:{1}{2}" -f $packagePath, [Environment]::NewLine, $details)
}

[pscustomobject]@{
    solution = $configuration.displayName
    solutionCode = $configuration.solutionCode
    tenantId = $TenantId
    tier = $ConfigurationTier
    periodStart = $PeriodStart.ToString('s')
    periodEnd = $PeriodEnd.ToString('s')
    packagePath = $packagePath
    artifactPaths = $artifacts
    hashFiles = @($coverageHash.HashPath, $gapHash.HashPath, $manifestHash.HashPath, $packageHash.HashPath)
    summary = $summary
}
