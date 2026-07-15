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

.PARAMETER WhatIf
    Build the evidence plan in memory and return it without writing any JSON artifacts, SHA-256
    companions, or the evidence package. Useful for read-only lab validation that must leave no
    local artifacts. Planned artifact paths are returned with null hashes.

.EXAMPLE
    .\Export-Evidence.ps1 -ConfigurationTier recommended -Verbose

.EXAMPLE
    .\Export-Evidence.ps1 -ConfigurationTier regulated -PassThru -WhatIf

.NOTES
    Solution: Pages and Notebooks Retention Tracker (PNRT)
    Version: v0.1.3
#>
[CmdletBinding(SupportsShouldProcess)]
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

$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
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

$artifactPlans = [System.Collections.Generic.List[object]]::new()

Write-Verbose 'Preparing pages-retention-inventory artifact.'
$pagesArtifact = [ordered]@{} + $baseEnvelope
$pagesArtifact.retentionDays = $configuration.pagesRetentionDays
$pagesArtifact.records = @($snapshot.Pages)
$null = $artifactPlans.Add([pscustomobject]@{
    name = 'pages-retention-inventory'
    fileName = ("pages-retention-inventory-{0}.json" -f $ConfigurationTier)
    content = $pagesArtifact
})

Write-Verbose 'Preparing notebook-retention-log artifact.'
$notebookArtifact = [ordered]@{} + $baseEnvelope
$notebookArtifact.retentionDays = $configuration.notebookRetentionDays
$notebookArtifact.records = @($snapshot.Notebooks)
$null = $artifactPlans.Add([pscustomobject]@{
    name = 'notebook-retention-log'
    fileName = ("notebook-retention-log-{0}.json" -f $ConfigurationTier)
    content = $notebookArtifact
})

Write-Verbose 'Preparing loop-component-lineage artifact.'
$loopArtifact = [ordered]@{} + $baseEnvelope
$loopArtifact.signedLineageRequired = [bool]$configuration.signedLineageRequired
$loopArtifact.records = @($snapshot.LoopComponents)
$null = $artifactPlans.Add([pscustomobject]@{
    name = 'loop-component-lineage'
    fileName = ("loop-component-lineage-{0}.json" -f $ConfigurationTier)
    content = $loopArtifact
})

Write-Verbose 'Preparing branching-event-log internal sample lineage artifact.'
$branchingArtifact = [ordered]@{} + $baseEnvelope
$branchingArtifact.internalSampleLineageMode = $configuration.branchingAuditMode
$branchingArtifact.branchingAuditRequired = [bool]$configuration.branchingAuditRequired
$branchingArtifact.documentedEvidence = @('Purview audit logs', 'Version history export in Purview or Graph API where documented')
$branchingArtifact.records = @($snapshot.InternalSampleLineageEvents)
$null = $artifactPlans.Add([pscustomobject]@{
    name = 'branching-event-log'
    fileName = ("branching-event-log-{0}.json" -f $ConfigurationTier)
    content = $branchingArtifact
})

$controls = @(
    [pscustomobject]@{
        controlId = '3.14'
        status = 'partial'
        notes = 'Pages and Copilot Notebook retention coverage is documented through sample inventory; live SharePoint Embedded, documented Graph DriveItem/export, and Purview integration is required to confirm production retention coverage.'
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

$recordCount = @($snapshot.Pages).Count + @($snapshot.Notebooks).Count + @($snapshot.LoopComponents).Count + @($snapshot.InternalSampleLineageEvents).Count
$exceptionCount = ($controls | Where-Object { $_.status -ne 'implemented' }).Count

$summary = @{
    overallStatus = 'partial'
    recordCount = $recordCount
    findingCount = 0
    coverageGapCount = [int]$snapshot.CoverageGapCount
    exceptionCount = $exceptionCount
}

# Package artifact entries use package-relative file names so the exported package stays valid when
# the evidence directory is relocated (the shared validator resolves relative paths against the
# package directory). Returned artifact entries use absolute paths so callers can locate the files.
$resultArtifacts = @()
$packageResult = [pscustomobject]@{ Path = $null; Hash = $null; HashPath = $null }

if ($PSCmdlet.ShouldProcess($resolvedOutputPath, ("Export PNRT evidence package for tier {0}" -f $ConfigurationTier))) {
    $null = New-Item -ItemType Directory -Path $resolvedOutputPath -Force

    $packageArtifacts = @()
    foreach ($plan in $artifactPlans) {
        $artifactPath = Join-Path $resolvedOutputPath $plan.fileName
        $file = Write-PnrtArtifactFile -Path $artifactPath -Content $plan.content
        $packageArtifacts += [pscustomobject]@{ name = $plan.name; type = 'json'; path = $plan.fileName; hash = $file.Hash }
        $resultArtifacts += [pscustomobject]@{ name = $plan.name; type = 'json'; path = $file.Path; hash = $file.Hash }
    }

    Write-Verbose 'Creating PNRT evidence package with shared exporter.'
    $packageResult = Export-SolutionEvidencePackage `
        -Solution $configuration.solution `
        -SolutionCode $configuration.solutionCode `
        -Tier $ConfigurationTier `
        -OutputPath $resolvedOutputPath `
        -Summary $summary `
        -Controls $controls `
        -Artifacts $packageArtifacts `
        -PackageFileName ("22-pages-notebooks-retention-tracker-evidence-{0}.json" -f $ConfigurationTier) `
        -ExpectedArtifacts @($configuration.evidenceOutputs) `
        -AdditionalMetadata @{
            runtimeMode = $snapshot.RuntimeMode
            warning = $snapshot.StatusWarning
        }
}
else {
    Write-Verbose 'WhatIf enabled. Returning evidence plan without writing artifacts or package.'
    foreach ($plan in $artifactPlans) {
        $resultArtifacts += [pscustomobject]@{
            name = $plan.name
            type = 'json'
            path = (Join-Path $resolvedOutputPath $plan.fileName)
            hash = $null
        }
    }
}

$result = [pscustomobject]@{
    Summary = $summary
    Controls = $controls
    Artifacts = $resultArtifacts
    RuntimeMode = $snapshot.RuntimeMode
    PackagePath = $packageResult.Path
    Package = $packageResult
}

Write-Host (
    "Evidence summary: PNRT tier [{0}] {1} {2} artifacts, {3} records, {4} coverage gaps." -f
    $ConfigurationTier,
    $(if ($null -eq $packageResult.Path) { 'planned' } else { 'exported' }),
    $resultArtifacts.Count,
    $recordCount,
    $summary['coverageGapCount']
)

if ($PassThru) {
    return $result
}

$result
