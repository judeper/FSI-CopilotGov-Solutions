<#
.SYNOPSIS
    Exports Pages and Notebooks Retention Tracker (PNRT) evidence artifacts.

.DESCRIPTION
    Builds the four PNRT evidence artifacts (pages-retention-inventory,
    notebook-retention-log, loop-component-lineage, and branching-event-log as
    internal sample lineage) from the monitoring snapshot and writes JSON files
    plus SHA-256 companion hashes.
    Helps meet retention recordkeeping expectations under SEC Rule 17a-4 (where
    applicable to broker-dealer required records), FINRA Rule 4511(a), and
    Sarbanes-Oxley §§302/404 (where applicable to ICFR).

.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.

.PARAMETER OutputPath
    Path for exported evidence artifacts.

.PARAMETER PeriodStart
    Beginning of the evidence window.

.PARAMETER PeriodEnd
    End of the evidence window.

.PARAMETER PassThru
    Returns the evidence summary object after writing artifacts.

.EXAMPLE
    .\Export-Evidence.ps1 -ConfigurationTier recommended -Verbose

.NOTES
    Solution: Pages and Notebooks Retention Tracker (PNRT)
    Version: v0.1.2
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts'),

    [Parameter()]
    [datetime]$PeriodStart = (Get-Date).Date.AddDays(-30),

    [Parameter()]
    [datetime]$PeriodEnd = (Get-Date),

    [Parameter()]
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'PnrtConfig.psm1') -Force

function Write-PnrtArtifactFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [object]$Content
    )

    $directory = Split-Path -Path $Path -Parent
    $null = New-Item -ItemType Directory -Path $directory -Force
    $Content | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding utf8
    $hashInfo = Write-CopilotGovSha256File -Path $Path

    return [pscustomobject]@{
        Path = $Path
        Hash = $hashInfo.Hash
        HashPath = $hashInfo.HashPath
    }
}

if ($PeriodEnd -lt $PeriodStart) {
    throw 'PeriodEnd must be greater than or equal to PeriodStart.'
}

Write-Verbose ("Loading PNRT configuration for tier [{0}]." -f $ConfigurationTier)
$configuration = Get-PnrtConfiguration -Tier $ConfigurationTier
Test-PnrtConfiguration -Configuration $configuration

$resolvedOutputPath = (New-Item -ItemType Directory -Path $OutputPath -Force).FullName
$monitorScript = Join-Path $PSScriptRoot 'Monitor-Compliance.ps1'

Write-Verbose 'Collecting monitoring snapshot for evidence export.'
$snapshot = & $monitorScript -ConfigurationTier $ConfigurationTier -OutputPath $resolvedOutputPath -PassThru -Verbose:$($VerbosePreference -eq 'Continue')

$baseEnvelope = [ordered]@{
    solution = $configuration.solution
    tier = $ConfigurationTier
    periodStart = $PeriodStart.ToString('o')
    periodEnd = $PeriodEnd.ToString('o')
    generatedAt = (Get-Date).ToString('o')
    runtimeMode = $snapshot.RuntimeMode
    warning = $snapshot.StatusWarning
}

Write-Verbose 'Building pages-retention-inventory artifact.'
$pagesArtifact = [ordered]@{} + $baseEnvelope
$pagesArtifact.retentionDays = $configuration.pagesRetentionDays
$pagesArtifact.records = @($snapshot.Pages)
$pagesFile = Write-PnrtArtifactFile -Path (Join-Path $resolvedOutputPath ("pages-retention-inventory-{0}.json" -f $ConfigurationTier)) -Content $pagesArtifact

Write-Verbose 'Building notebook-retention-log artifact.'
$notebookArtifact = [ordered]@{} + $baseEnvelope
$notebookArtifact.retentionDays = $configuration.notebookRetentionDays
$notebookArtifact.records = @($snapshot.Notebooks)
$notebookFile = Write-PnrtArtifactFile -Path (Join-Path $resolvedOutputPath ("notebook-retention-log-{0}.json" -f $ConfigurationTier)) -Content $notebookArtifact

Write-Verbose 'Building loop-component-lineage artifact.'
$loopArtifact = [ordered]@{} + $baseEnvelope
$loopArtifact.signedLineageRequired = [bool]$configuration.signedLineageRequired
$loopArtifact.records = @($snapshot.LoopComponents)
$loopFile = Write-PnrtArtifactFile -Path (Join-Path $resolvedOutputPath ("loop-component-lineage-{0}.json" -f $ConfigurationTier)) -Content $loopArtifact

Write-Verbose 'Building branching-event-log internal sample lineage artifact.'
$branchingArtifact = [ordered]@{} + $baseEnvelope
$branchingArtifact.internalSampleLineageMode = $configuration.branchingAuditMode
$branchingArtifact.branchingAuditRequired = [bool]$configuration.branchingAuditRequired
$branchingArtifact.documentedEvidence = @('Purview audit logs', 'Version history export in Purview or Graph API where documented')
$branchingArtifact.records = @($snapshot.InternalSampleLineageEvents)
$branchingFile = Write-PnrtArtifactFile -Path (Join-Path $resolvedOutputPath ("branching-event-log-{0}.json" -f $ConfigurationTier)) -Content $branchingArtifact

$controls = @(
    [pscustomobject]@{
        controlId = '3.14'
        status = 'partial'
        notes = 'Pages and OneNote section retention coverage is documented through sample inventory; live SharePoint Embedded, documented Graph DriveItem/export, and Purview integration is required to confirm production retention coverage.'
    },
    [pscustomobject]@{
        controlId = '3.2'
        status = 'partial'
        notes = 'Lifecycle, version-history, and provenance metadata for Pages and Loop components is documented; live integration is required for full evidence.'
    },
    [pscustomobject]@{
        controlId = '3.3'
        status = 'monitor-only'
        notes = 'Microsoft Purview retention-policy lookup is documented but not wired in this version.'
    },
    [pscustomobject]@{
        controlId = '3.11'
        status = 'monitor-only'
        notes = 'Purview audit/version-history context and internal sample lineage support eDiscovery and legal-hold readiness; live hold placement is out of scope for this solution.'
    },
    [pscustomobject]@{
        controlId = '2.11'
        status = 'partial'
        notes = 'Branching-event-log records internal sample lineage only; production audit evidence should come from Purview audit-log search/export and documented Graph DriveItem/export or version-history capabilities.'
    }
)

$artifacts = @(
    [pscustomobject]@{ name = 'pages-retention-inventory'; type = 'json'; path = $pagesFile.Path; hash = $pagesFile.Hash },
    [pscustomobject]@{ name = 'notebook-retention-log'; type = 'json'; path = $notebookFile.Path; hash = $notebookFile.Hash },
    [pscustomobject]@{ name = 'loop-component-lineage'; type = 'json'; path = $loopFile.Path; hash = $loopFile.Hash },
    [pscustomobject]@{ name = 'branching-event-log'; type = 'json'; path = $branchingFile.Path; hash = $branchingFile.Hash }
)

$recordCount = @($snapshot.Pages).Count + @($snapshot.Notebooks).Count + @($snapshot.LoopComponents).Count + @($snapshot.InternalSampleLineageEvents).Count
$exceptionCount = ($controls | Where-Object { $_.status -ne 'implemented' }).Count

$summary = @{
    overallStatus = 'partial'
    recordCount = $recordCount
    findingCount = 0
    coverageGapCount = [int]$snapshot.CoverageGapCount
    exceptionCount = $exceptionCount
}

Write-Verbose 'Creating PNRT evidence package with shared exporter.'
$package = Export-SolutionEvidencePackage `
    -Solution $configuration.solution `
    -SolutionCode $configuration.solutionCode `
    -Tier $ConfigurationTier `
    -OutputPath $resolvedOutputPath `
    -Summary $summary `
    -Controls $controls `
    -Artifacts $artifacts `
    -PackageFileName ("22-pages-notebooks-retention-tracker-evidence-{0}.json" -f $ConfigurationTier) `
    -ExpectedArtifacts @($configuration.evidenceOutputs) `
    -AdditionalMetadata @{
        runtimeMode = $snapshot.RuntimeMode
        warning = $snapshot.StatusWarning
    }

$result = [pscustomobject]@{
    Summary = $summary
    Controls = $controls
    Artifacts = $artifacts
    RuntimeMode = $snapshot.RuntimeMode
    PackagePath = $package.Path
    Package = $package
}

Write-Host (
    "Evidence summary: PNRT tier [{0}] exported {1} artifacts, {2} records, {3} coverage gaps." -f
    $ConfigurationTier,
    $artifacts.Count,
    $recordCount,
    $summary['coverageGapCount']
)

if ($PassThru) {
    return $result
}

$result
