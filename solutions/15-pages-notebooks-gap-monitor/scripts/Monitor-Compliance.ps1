<#
.SYNOPSIS
    Monitors the Copilot Pages and Notebooks compliance gap register.

.DESCRIPTION
    Assesses known retention, Microsoft Purview eDiscovery, sharing, and books-and-records limitations for
    Copilot Pages, Loop workspaces, and notebooks. The script uses documentation-first
    stub checks to inventory documented limitations and validation items, validates whether registered
    compensating controls remain in place, and summarizes any Microsoft platform
    updates that may change previously documented limitations.

    This script supports compliance with SEC 17a-4, FINRA 4511, and SOX 404 by
    producing a monitor-only or partial status view. It does not make tenant changes.

.PARAMETER ConfigurationTier
    Governance tier to assess: baseline, recommended, or regulated.

.PARAMETER OutputPath
    Directory where the compliance status snapshot is written.

.PARAMETER TenantId
    Optional tenant identifier used for authenticated monitoring context.

.PARAMETER ClientId
    Optional client identifier used for authenticated monitoring context.

.PARAMETER ClientSecret
    Optional secure client secret used for authenticated monitoring context.

.PARAMETER PassThru
    Returns the full compliance payload when specified.

.OUTPUTS
    PSCustomObject. Summary or full status payload depending on PassThru.

.EXAMPLE
    pwsh -File .\scripts\Monitor-Compliance.ps1 -ConfigurationTier baseline -PassThru

.EXAMPLE
    pwsh -File .\scripts\Monitor-Compliance.ps1 -ConfigurationTier regulated -TenantId contoso.onmicrosoft.com -ClientId 00000000-0000-0000-0000-000000000000 -ClientSecret $secret -OutputPath .\artifacts\monitoring

.NOTES
    Solution: Copilot Pages and Notebooks Compliance Gap Monitor (PNGM)
    Controls: 2.11, 3.2, 3.3, 3.11
    Status model: monitor-only by default, partial when mapped controls and validation-required items are tracked
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts'),

    [Parameter()]
    [string]$TenantId,

    [Parameter()]
    [string]$ClientId,

    [Parameter()]
    [SecureString]$ClientSecret,

    [Parameter()]
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force

Import-Module (Join-Path $PSScriptRoot 'PngmShared.psm1') -Force

function Get-CopilotPagesRetentionGap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$TierConfiguration,

        [Parameter()]
        [string]$TenantId,

        [Parameter()]
        [string]$ClientId,

        [Parameter()]
        [SecureString]$ClientSecret
    )

    # TierConfiguration accepted for future tier-specific gap weighting; not yet referenced.
    $null = $TierConfiguration

    $authenticated = ($TenantId -and $ClientId -and $null -ne $ClientSecret)
    $assessedAt = Get-Date

    return [pscustomobject]@{
        source = $(if ($authenticated) { 'GraphStubAuthenticated' } else { 'GraphStub' })
        assessedAt = $assessedAt.ToString('o')
        gaps = @(
            [pscustomobject]@{
                gapId = 'PNGM-GAP-001'
                description = 'Purview retention policies configured for All SharePoint Sites are supported for Copilot Pages and Copilot Notebooks; tenant policy scope and evidence should be validated for this baseline.'
                affectedCapability = 'Copilot Pages and Notebooks retention policy validation'
                affectedRegulation = @('SEC 17a-4', 'FINRA 4511', 'SOX 404')
                severity = 'medium'
                discoveredAt = $assessedAt.AddDays(-30).ToString('o')
                status = 'validation-required'
                platformUpdateRequired = $false
            }
            [pscustomobject]@{
                gapId = 'PNGM-GAP-004'
                description = 'Conditional Access applies at the Microsoft 365 Copilot app level, and Information Barriers are not supported for SharePoint Embedded containers used by Copilot Pages and Copilot Notebooks.'
                affectedCapability = 'Access boundaries (Conditional Access app-level and Information Barriers limitation)'
                affectedRegulation = @('FINRA 4511', 'SOX 404')
                severity = 'high'
                discoveredAt = $assessedAt.AddDays(-14).ToString('o')
                status = 'open'
                platformUpdateRequired = $true
            }
            [pscustomobject]@{
                gapId = 'PNGM-GAP-005'
                description = 'Purview custodian data-source picker support for user-owned SharePoint Embedded containers is rolling out (expected early August 2026); tenant validation is required before removing manual legal-hold container and retention-label procedures.'
                affectedCapability = 'Legal hold container picker rollout and retention-label manual limits'
                affectedRegulation = @('SEC 17a-4', 'FINRA 4511')
                severity = 'medium'
                discoveredAt = $assessedAt.AddDays(-28).ToString('o')
                status = 'validation-required'
                platformUpdateRequired = $false
            }
        )
    }
}

function Get-NotebooksEDiscoveryGap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$TierConfiguration
    )

    # TierConfiguration accepted for future tier-specific eDiscovery scoping; not yet referenced.
    $null = $TierConfiguration

    $assessedAt = Get-Date

    return [pscustomobject]@{
        source = 'eDiscoveryStub'
        assessedAt = $assessedAt.ToString('o')
        gaps = @(
            [pscustomobject]@{
                gapId = 'PNGM-GAP-002'
                description = 'M365 Roadmap 561492 (GA June 2026, rolling out) introduces full indexing and keyword search for Loop and Copilot Pages in review sets plus HTML export from search; validate tenant behavior before retiring manual search-limit procedures.'
                affectedCapability = 'Purview eDiscovery review-set indexing rollout validation'
                affectedRegulation = @('SEC 17a-4', 'FINRA 4511')
                severity = 'medium'
                discoveredAt = $assessedAt.AddDays(-21).ToString('o')
                status = 'validation-required'
                platformUpdateRequired = $false
            }
            [pscustomobject]@{
                gapId = 'PNGM-GAP-003'
                description = 'Copilot Notebooks .pod files share a user-owned SharePoint Embedded container with Copilot Pages and Loop My workspace. Audit visibility and preservation evidence must be reviewed, and deleted notebooks cannot be recovered through an end-user recycle bin.'
                affectedCapability = 'Notebook lifecycle, audit visibility, and recovery limitation'
                affectedRegulation = @('SEC 17a-4', 'FINRA 4511', 'SOX 404')
                severity = 'high'
                discoveredAt = $assessedAt.AddDays(-10).ToString('o')
                status = 'open'
                platformUpdateRequired = $true
            }
        )
    }
}

function Test-CompensatingControlStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$TierConfiguration,

        [Parameter(Mandatory)]
        [object[]]$TrackedGaps
    )

    $controlsRequired = [bool]$TierConfiguration.compensatingControlsRequired
    $now = Get-Date
    $trackedGapIds = @($TrackedGaps | ForEach-Object { $_.gapId })

    $allControls = @(
        [pscustomobject]@{
            controlId = 'PNGM-CC-001'
            gapId = 'PNGM-GAP-001'
            controlDescription = 'Records Management verifies All SharePoint Sites retention policy scope, records SharePoint Embedded container evidence, and uses manual export only when policy scope cannot be demonstrated.'
            controlType = 'tenant-validation'
            lastValidatedAt = $now.AddDays(-5).ToString('o')
            reviewDueDate = $now.AddDays(25).ToString('o')
            status = $(if ($controlsRequired) { 'in-place' } else { 'planned' })
        }
        [pscustomobject]@{
            controlId = 'PNGM-CC-002'
            gapId = 'PNGM-GAP-002'
            controlDescription = 'Investigation teams validate tenant rollout for review-set indexing and HTML export, and preserve evidence for any custodian searches that still require manual workaround steps.'
            controlType = 'ediscovery-rollout-validation'
            lastValidatedAt = $now.AddDays(-4).ToString('o')
            reviewDueDate = $now.AddDays(21).ToString('o')
            status = $(if ($controlsRequired) { 'in-place' } else { 'planned' })
        }
        [pscustomobject]@{
            controlId = 'PNGM-CC-003'
            gapId = 'PNGM-GAP-004'
            controlDescription = 'Restricted-sharing review for Pages workspaces with escalation to compliance operations when exceptions are found.'
            controlType = 'access-review'
            lastValidatedAt = $now.AddDays(-2).ToString('o')
            reviewDueDate = $now.AddDays(14).ToString('o')
            status = $(if ($controlsRequired) { 'in-place' } else { 'planned' })
        }
        [pscustomobject]@{
            controlId = 'PNGM-CC-004'
            gapId = 'PNGM-GAP-003'
            controlDescription = 'Compliance operations validates notebook storage location, .pod audit visibility, retention policy scope, and export steps during quarterly control reviews.'
            controlType = 'lifecycle-audit-validation'
            lastValidatedAt = $now.AddDays(-7).ToString('o')
            reviewDueDate = $now.AddDays(30).ToString('o')
            status = $(if ($controlsRequired) { 'in-place' } else { 'planned' })
        }
        [pscustomobject]@{
            controlId = 'PNGM-CC-005'
            gapId = 'PNGM-GAP-005'
            controlDescription = 'Records Management documents legal-hold container inclusion until picker rollout is verified, tracks retention-label manual limits, and records preservation exceptions where needed.'
            controlType = 'preservation-exception'
            lastValidatedAt = $now.AddDays(-3).ToString('o')
            reviewDueDate = $now.AddDays(90).ToString('o')
            status = $(if ($controlsRequired) { 'in-place' } else { 'planned' })
        }
    )

    return @($allControls | Where-Object { $trackedGapIds -contains $_.gapId })
}

function Get-PlatformUpdateStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$CheckFrequencyDays,

        [Parameter()]
        [string]$TenantId,

        [Parameter()]
        [string]$ClientId,

        [Parameter()]
        [SecureString]$ClientSecret
    )

    $authenticated = ($TenantId -and $ClientId -and $null -ne $ClientSecret)
    $checkedAt = Get-Date

    return [pscustomobject]@{
        source = $(if ($authenticated) { 'MessageCenterStubAuthenticated' } else { 'MessageCenterStub' })
        lastCheckedAt = $checkedAt.ToString('o')
        checkFrequencyDays = $CheckFrequencyDays
        updates = @(
            [pscustomobject]@{
                messageId = 'M365RD-561492'
                title = 'Purview eDiscovery review-set indexing and HTML export enhancement for Loop and Copilot Pages'
                publishedAt = '2026-07-13T23:07:14.8221961Z'
                status = 'rolling-out'
                closesGapIds = @('PNGM-GAP-002')
                notes = 'Roadmap item 561492 is launched (GA June 2026). Validate tenant rollout before retiring review-set search workaround procedures.'
            }
            [pscustomobject]@{
                messageId = 'MSL-CPCN-2026-07-LEGAL-HOLD'
                title = 'Copilot Pages and Notebooks legal-hold container picker rollout update'
                publishedAt = '2026-07-06T15:46:00.0000000Z'
                status = 'rolling-out'
                closesGapIds = @('PNGM-GAP-005')
                notes = 'Microsoft Learn indicates legal-hold container picker support is rolling out with expected availability in early August 2026.'
            }
            [pscustomobject]@{
                messageId = 'MSL-CPCN-2026-07-LIMITATIONS'
                title = 'Copilot Pages and Notebooks baseline limitations requiring manual governance controls'
                publishedAt = '2026-07-06T15:46:00.0000000Z'
                status = 'watch'
                closesGapIds = @()
                notes = 'Track ongoing limitations for app-level Conditional Access scope, Information Barriers not supported in SharePoint Embedded, and no notebook recycle-bin recovery.'
            }
        )
    }
}

$configuration = Get-PngmConfiguration -Tier $ConfigurationTier
$defaultConfig = $configuration.Default
$tierConfig = $configuration.Tier
$tierDefinition = Get-CopilotGovTierDefinition -Tier $ConfigurationTier
$dependencyStatus = Get-PngmDependencyStatus -RepoRoot $repoRoot -Dependencies @($defaultConfig.dependencies)

$pagesResult = Get-CopilotPagesRetentionGap -TierConfiguration $tierConfig -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
$notebookResult = Get-NotebooksEDiscoveryGap -TierConfiguration $tierConfig
$allGaps = @($pagesResult.gaps) + @($notebookResult.gaps)
$trackedGaps = @($allGaps | Where-Object { $_.status -in @('open', 'validation-required') })
$openGaps = @($trackedGaps | Where-Object { $_.status -eq 'open' })
$validationGaps = @($trackedGaps | Where-Object { $_.status -eq 'validation-required' })
$compensatingControls = Test-CompensatingControlStatus -TierConfiguration $tierConfig -TrackedGaps $trackedGaps
$controlsInPlace = @($compensatingControls | Where-Object { $_.status -eq 'in-place' })
$platformUpdateStatus = Get-PlatformUpdateStatus -CheckFrequencyDays ([int]$tierConfig.platformUpdateCheckFrequencyDays) -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
$availableUpdates = @($platformUpdateStatus.updates | Where-Object { $_.status -in @('available', 'rolling-out') })
$hasCompensatingControls = ($controlsInPlace.Count -gt 0)
$controlStates = Get-PngmControlState -TierConfiguration $tierConfig -TrackedGaps $trackedGaps -CompensatingControls $compensatingControls
$overallStatus = if (@($controlStates | Where-Object { $_.status -eq 'partial' }).Count -gt 0) { 'partial' } else { 'monitor-only' }
if ($dependencyStatus.hasMissingDependencies) {
    $overallStatus = 'monitor-only'
}
$statusFile = Join-Path $OutputPath '15-pages-notebooks-gap-monitor-compliance-status.json'

$statusPayload = [ordered]@{
    solution = $defaultConfig.solution
    solutionCode = $defaultConfig.solutionCode
    displayName = $defaultConfig.displayName
    frameworkIds = @($defaultConfig.framework_ids)
    tier = $ConfigurationTier
    tierDefinition = $tierDefinition
    assessedAt = (Get-Date).ToString('o')
    tenantId = $(if ($TenantId) { $TenantId } else { 'not-specified' })
    overallStatus = $overallStatus
    dashboardStatusScore = (Get-CopilotGovStatusScore -Status $overallStatus)
    gapCount = $allGaps.Count
    openGapCount = $openGaps.Count
    validationRequiredGapCount = $validationGaps.Count
    openGaps = $openGaps
    compensatingControlsInPlace = $controlsInPlace.Count
    hasCompensatingControlsInPlace = $hasCompensatingControls
    compensatingControls = $compensatingControls
    dependencyStatus = $dependencyStatus
    platformUpdatesAvailable = $availableUpdates.Count
    platformUpdateStatus = $platformUpdateStatus
    controls = $controlStates
    monitoringSources = [ordered]@{
        pagesRetention = $pagesResult.source
        notebookEdiscovery = $notebookResult.source
        platformUpdates = $platformUpdateStatus.source
    }
    outputPath = $statusFile
}

if ($PSCmdlet.ShouldProcess($statusFile, 'Write compliance status snapshot')) {
    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $statusPayload | ConvertTo-Json -Depth 8 | Set-Content -Path $statusFile -Encoding utf8
}

if ($PassThru) {
    $statusPayload
}
else {
    [pscustomobject]@{
        solution = $defaultConfig.solution
        tier = $ConfigurationTier
        overallStatus = $overallStatus
        gapCount = $allGaps.Count
        openGapCount = $openGaps.Count
        compensatingControlsInPlace = $controlsInPlace.Count
        platformUpdatesAvailable = $availableUpdates.Count
        outputPath = $statusFile
    }
}
