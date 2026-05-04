<#
.SYNOPSIS
    Generates a sample inventory, OneNote section coverage snapshot, Loop provenance,
    and internal sample lineage rows for the Pages and Notebooks Retention Tracker (PNRT).

.DESCRIPTION
    Produces representative sample inventories that mirror the target shape of live data
    from SharePoint Embedded, documented Microsoft Graph DriveItem/export surfaces,
    OneNote section metadata, and Microsoft Purview. The repository version does not
    connect to live services; insertion points are documented in docs/architecture.md.
    The script is testable without external connectivity and
    helps meet records retention expectations under SEC Rule 17a-4 (where applicable
    to broker-dealer required records) and FINRA Rule 4511(a).

.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.

.PARAMETER OutputPath
    Path for monitoring snapshots.

.PARAMETER TenantId
    Microsoft Entra ID tenant ID. Defaults to AZURE_TENANT_ID.

.PARAMETER ClientId
    Microsoft Entra ID application ID. Defaults to AZURE_CLIENT_ID.

.PARAMETER ClientSecret
    SecureString client secret used when a live SharePoint Embedded, Graph DriveItem/export, or Purview implementation is added.

.PARAMETER PassThru
    Returns the compliance status object after writing the snapshot file.

.EXAMPLE
    .\Monitor-Compliance.ps1 -ConfigurationTier recommended -Verbose

.NOTES
    Solution: Pages and Notebooks Retention Tracker (PNRT)
    Version: v0.1.1
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts'),

    [Parameter()]
    [string]$TenantId = $env:AZURE_TENANT_ID,

    [Parameter()]
    [string]$ClientId = $env:AZURE_CLIENT_ID,

    [Parameter()]
    [System.Security.SecureString]$ClientSecret,

    [Parameter()]
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'PnrtConfig.psm1') -Force

$script:SampleWarning = 'Inventory output came from PNRT sample-data generator and does not confirm live SharePoint Embedded, documented Graph DriveItem/export, or Purview reads.'

function New-PnrtSamplePages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [int]$Count,
        [Parameter(Mandatory)] [int]$RetentionDays
    )

    $now = Get-Date
    $labels = @('Records-7yr', 'Records-7yr', 'General', $null, 'Confidential-Records')
    $states = @('sample-internal-active', 'sample-internal-derived', 'sample-internal-active', 'sample-internal-reviewed', 'sample-internal-retention-candidate', 'sample-internal-active')
    $versionStatuses = @('purview-audit-sample', 'version-history-sample', 'purview-audit-sample', 'version-history-sample')

    return @(
        for ($i = 1; $i -le $Count; $i++) {
            $label = $labels[$i % $labels.Count]
            $state = $states[$i % $states.Count]
            $sampleParent = if ($state -eq 'sample-internal-derived') { ("page-{0:0000}" -f ($i - 1)) } else { $null }
            $versionStatus = $versionStatuses[$i % $versionStatuses.Count]

            [pscustomobject]@{
                pageId = "page-{0:0000}" -f $i
                title = "Sample Copilot Page {0}" -f $i
                owner = "user{0}@contoso.com" -f $i
                createdAt = $now.AddDays(-30 - $i).ToString('o')
                lastModifiedAt = $now.AddDays(-$i).ToString('o')
                retentionLabel = $label
                retentionDays = $RetentionDays
                versionEvidenceStatus = $versionStatus
                internalSampleState = $state
                internalSampleParentPageId = $sampleParent
                taxonomySource = 'PNRT internal sample taxonomy; not Microsoft 365 lifecycle state'
            }
        }
    )
}

function New-PnrtSampleNotebooks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [int]$Count,
        [Parameter(Mandatory)] [int]$RetentionDays
    )

    $now = Get-Date
    $sources = @('section-label', 'folder-inherited', 'policy-inherited', 'none')

    return @(
        for ($i = 1; $i -le $Count; $i++) {
            $source = $sources[$i % $sources.Count]
            $label = if ($source -eq 'none') { $null } else { 'Records-7yr' }

            [pscustomobject]@{
                sectionId = "section-{0:0000}" -f $i
                sectionDisplayName = "Sample Section {0}" -f $i
                notebookId = "notebook-{0:0000}" -f $i
                displayName = "Sample Notebook {0}" -f $i
                parentContainer = "https://contoso.sharepoint.com/sites/team{0}/Shared Documents/Notebook {0}" -f $i
                retentionLabel = $label
                retentionPolicySource = $source
                retentionEvidenceGranularity = 'OneNote section file'
                retentionDays = $RetentionDays
                lastReviewedAt = $now.AddDays(-15).ToString('o')
            }
        }
    )
}

function New-PnrtSampleLoopComponents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [int]$Count,
        [Parameter(Mandatory)] [string[]]$WorkspaceSeeds,
        [Parameter()] [bool]$IncludeSignedLineage
    )

    $now = Get-Date
    $types = @('task-list', 'table', 'paragraph', 'voting', 'progress-tracker')

    return @(
        for ($i = 1; $i -le $Count; $i++) {
            $workspace = $WorkspaceSeeds[$i % $WorkspaceSeeds.Count]
            $lineageHash = if ($IncludeSignedLineage) { ("sha256:sample-{0:x16}" -f ($i * 1234567)) } else { $null }

            [pscustomobject]@{
                componentId = "loop-{0:0000}" -f $i
                componentType = $types[$i % $types.Count]
                originatingWorkspace = $workspace
                parentContainer = "loop://{0}/container-{1}" -f ($workspace -replace '\s', '-'), $i
                embeddedInPageId = "page-{0:0000}" -f (($i % 6) + 1)
                createdBy = "user{0}@contoso.com" -f $i
                createdAt = $now.AddDays(-$i).ToString('o')
                lineageHash = $lineageHash
            }
        }
    )
}

function New-PnrtInternalSampleLineageEvents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [int]$Count,
        [Parameter(Mandatory)] [string]$AuditMode
    )

    $now = Get-Date
    $eventTypes = @('sample-internal-derive', 'sample-internal-copy', 'sample-internal-consolidate', 'sample-internal-review', 'sample-internal-retention-check')

    return @(
        for ($i = 1; $i -le $Count; $i++) {
            [pscustomobject]@{
                eventId = "evt-{0:0000}" -f $i
                sourcePageId = "page-{0:0000}" -f $i
                targetPageId = "page-{0:0000}" -f ($i + 100)
                eventType = $eventTypes[$i % $eventTypes.Count]
                actor = "user{0}@contoso.com" -f $i
                occurredAt = $now.AddDays(-$i).ToString('o')
                taxonomySource = 'PNRT internal sample taxonomy; not Microsoft 365 product event'
                documentedEvidence = 'Purview audit logs and version history'
                internalSampleLineageMode = $AuditMode
            }
        }
    )
}

Write-Verbose ("Loading PNRT configuration for tier [{0}]." -f $ConfigurationTier)
$configuration = Get-PnrtConfiguration -Tier $ConfigurationTier
Test-PnrtConfiguration -Configuration $configuration

if ($null -ne $ClientSecret -and -not [string]::IsNullOrWhiteSpace($ClientId) -and -not [string]::IsNullOrWhiteSpace($TenantId)) {
    Write-Verbose 'Client credentials supplied. Insert authenticated SharePoint Embedded, documented Graph DriveItem/export, and Purview calls here when enabling live monitoring.'
}
else {
    Write-Verbose 'Client credentials are incomplete. Returning sample inventory records for local validation.'
}

$resolvedOutputPath = (New-Item -ItemType Directory -Path $OutputPath -Force).FullName

$pages = New-PnrtSamplePages -Count ([int]$configuration.defaults.samplePageCount) -RetentionDays ([int]$configuration.pagesRetentionDays)
$notebooks = New-PnrtSampleNotebooks -Count ([int]$configuration.defaults.sampleNotebookCount) -RetentionDays ([int]$configuration.notebookRetentionDays)
$loopComponents = New-PnrtSampleLoopComponents -Count ([int]$configuration.defaults.sampleLoopComponentCount) -WorkspaceSeeds @($configuration.defaults.loopWorkspaceSeeds) -IncludeSignedLineage ([bool]$configuration.signedLineageRequired)
$internalLineageEvents = New-PnrtInternalSampleLineageEvents -Count ([int]$configuration.defaults.sampleBranchingEventCount) -AuditMode ([string]$configuration.branchingAuditMode)

$pagesWithoutLabel = @($pages | Where-Object { [string]::IsNullOrWhiteSpace($_.retentionLabel) })
$notebooksWithoutLabel = @($notebooks | Where-Object { $_.retentionPolicySource -eq 'none' })
$coverageGapCount = $pagesWithoutLabel.Count + $notebooksWithoutLabel.Count

$status = [pscustomobject]@{
    Solution = $configuration.solution
    Tier = $ConfigurationTier
    GeneratedAt = (Get-Date).ToString('o')
    RuntimeMode = 'sample-data'
    StatusWarning = $script:SampleWarning
    Pages = $pages
    Notebooks = $notebooks
    LoopComponents = $loopComponents
    InternalSampleLineageEvents = $internalLineageEvents
    CoverageGapCount = $coverageGapCount
    PagesWithoutLabel = $pagesWithoutLabel.Count
    NotebooksWithoutLabel = $notebooksWithoutLabel.Count
    PreservationLockRequired = [bool]$configuration.preservationLockRequired
    SignedLineageRequired = [bool]$configuration.signedLineageRequired
}

$snapshotPath = Join-Path $resolvedOutputPath ("monitor-snapshot-{0}.json" -f $ConfigurationTier)
$status | ConvertTo-Json -Depth 10 | Set-Content -Path $snapshotPath -Encoding utf8
Write-Verbose ("Monitor snapshot written to {0}." -f $snapshotPath)

Write-Host (
    "Monitor summary: PNRT tier [{0}] inventoried {1} Pages, {2} OneNote sections, {3} Loop components, {4} internal sample lineage rows. Coverage gaps: {5}." -f
    $ConfigurationTier,
    $pages.Count,
    $notebooks.Count,
    $loopComponents.Count,
    $internalLineageEvents.Count,
    $coverageGapCount
)

if ($PassThru) {
    return $status
}
