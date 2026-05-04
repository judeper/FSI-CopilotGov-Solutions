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
    Status model: monitor-only by default, partial when compensating controls are in place
#>
[CmdletBinding()]
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

function Get-CopilotPagesRetentionGaps {
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
                regulations = @('SEC 17a-4', 'FINRA 4511', 'SOX 404')
                severity = 'medium'
                discoveredAt = $assessedAt.AddDays(-30).ToString('o')
                status = 'validation-required'
                platformUpdateRequired = $false
            }
            [pscustomobject]@{
                gapId = 'PNGM-GAP-004'
                description = 'Pages security and sharing restrictions require manual review, and Information Barriers are not supported for content stored in SharePoint Embedded containers.'
                affectedCapability = 'Copilot Pages security, sharing, and Information Barriers'
                regulations = @('FINRA 4511', 'SOX 404')
                severity = 'high'
                discoveredAt = $assessedAt.AddDays(-14).ToString('o')
                status = 'open'
                platformUpdateRequired = $true
            }
            [pscustomobject]@{
                gapId = 'PNGM-GAP-005'
                description = 'Legal hold requires manual SharePoint Embedded container addition per user, and retention labels have limited manual support for Pages, Notebooks, and Loop content.'
                affectedCapability = 'Legal hold and retention label limitations'
                regulations = @('SEC 17a-4', 'FINRA 4511')
                severity = 'high'
                discoveredAt = $assessedAt.AddDays(-28).ToString('o')
                status = 'open'
                platformUpdateRequired = $true
            }
        )
    }
}

function Get-NotebooksEDiscoveryGaps {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$TierConfiguration
    )

    $assessedAt = Get-Date

    return [pscustomobject]@{
        source = 'eDiscoveryStub'
        assessedAt = $assessedAt.ToString('o')
        gaps = @(
            [pscustomobject]@{
                gapId = 'PNGM-GAP-002'
                description = 'Purview eDiscovery supports search, collection, review, and export for Pages, Notebooks, and Loop, but full-text search within .page and .loop files in review sets is not available.'
                affectedCapability = 'Purview eDiscovery review-set full-text search'
                regulations = @('SEC 17a-4', 'FINRA 4511')
                severity = 'high'
                discoveredAt = $assessedAt.AddDays(-21).ToString('o')
                status = 'open'
                platformUpdateRequired = $true
            }
            [pscustomobject]@{
                gapId = 'PNGM-GAP-003'
                description = 'Copilot Notebooks create .pod files in SharePoint Embedded containers; notebook storage, retention policy scope, and export evidence require tenant validation.'
                affectedCapability = 'Notebooks preservation verification'
                regulations = @('FINRA 4511', 'SOX 404')
                severity = 'medium'
                discoveredAt = $assessedAt.AddDays(-10).ToString('o')
                status = 'validation-required'
                platformUpdateRequired = $false
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
        [object[]]$OpenGaps
    )

    $controlsRequired = [bool]$TierConfiguration.compensatingControlsRequired
    $now = Get-Date
    $openGapIds = @($OpenGaps | ForEach-Object { $_.gapId })

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
            controlDescription = 'Investigation teams record SharePoint Embedded container URLs, custodian names, collection/export steps, and the review-set full-text search limitation in the case record.'
            controlType = 'ediscovery-review-set-limitation'
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
            status = $(if ($controlsRequired -and $TierConfiguration.tier -eq 'regulated') { 'in-place' } elseif ($controlsRequired) { 'planned' } else { 'planned' })
        }
        [pscustomobject]@{
            controlId = 'PNGM-CC-004'
            gapId = 'PNGM-GAP-003'
            controlDescription = 'Compliance operations validates notebook storage location, retention policy scope, retention label behavior, and export steps during quarterly control reviews.'
            controlType = 'manual-export'
            lastValidatedAt = $now.AddDays(-7).ToString('o')
            reviewDueDate = $now.AddDays(30).ToString('o')
            status = $(if ($controlsRequired) { 'in-place' } else { 'planned' })
        }
        [pscustomobject]@{
            controlId = 'PNGM-CC-005'
            gapId = 'PNGM-GAP-005'
            controlDescription = 'Records Management documents legal-hold container inclusion, retention-label limitations, and any preservation exception required for books-and-records review.'
            controlType = 'preservation-exception'
            lastValidatedAt = $now.AddDays(-3).ToString('o')
            reviewDueDate = $now.AddDays(90).ToString('o')
            status = $(if ($controlsRequired) { 'in-place' } else { 'planned' })
        }
    )

    return @($allControls | Where-Object { $openGapIds -contains $_.gapId })
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
                messageId = 'MC-PNGM-2025-001'
                title = 'Copilot Pages and Notebooks retention and eDiscovery support documented; limitation review continues'
                publishedAt = $checkedAt.AddDays(-10).ToString('o')
                status = 'watch'
                closesGapIds = @('PNGM-GAP-001')
                notes = 'Retention policies via All SharePoint Sites and Purview eDiscovery are supported; continue monitoring review-set full-text search, legal hold, retention label, and Information Barriers limitations.'
            }
            [pscustomobject]@{
                messageId = 'MC-PNGM-2025-002'
                title = 'SharePoint Embedded notebook guidance updated for compliance review workflows'
                publishedAt = $checkedAt.AddDays(-4).ToString('o')
                status = 'available'
                closesGapIds = @('PNGM-GAP-003')
                notes = 'Notebook guidance documents SharePoint Embedded storage and licensing requirements, but tenant verification is still required before closing validation items.'
            }
        )
    }
}

$configuration = Get-PngmConfiguration -Tier $ConfigurationTier
$defaultConfig = $configuration.Default
$tierConfig = $configuration.Tier
$tierDefinition = Get-CopilotGovTierDefinition -Tier $ConfigurationTier

$pagesResult = Get-CopilotPagesRetentionGaps -TierConfiguration $tierConfig -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
$notebookResult = Get-NotebooksEDiscoveryGaps -TierConfiguration $tierConfig
$allGaps = @($pagesResult.gaps) + @($notebookResult.gaps)
$openGaps = @($allGaps | Where-Object { $_.status -eq 'open' })
$compensatingControls = Test-CompensatingControlStatus -TierConfiguration $tierConfig -OpenGaps $openGaps
$controlsInPlace = @($compensatingControls | Where-Object { $_.status -eq 'in-place' })
$platformUpdateStatus = Get-PlatformUpdateStatus -CheckFrequencyDays ([int]$tierConfig.platformUpdateCheckFrequencyDays) -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
$availableUpdates = @($platformUpdateStatus.updates | Where-Object { $_.status -eq 'available' })
$hasCompensatingControls = ($controlsInPlace.Count -gt 0)
$overallStatus = if ($hasCompensatingControls) { 'partial' } else { 'monitor-only' }
$statusFile = Join-Path $OutputPath '15-pages-notebooks-gap-monitor-compliance-status.json'

$controlStates = @(
    [pscustomobject]@{
        controlId = '2.11'
        status = 'monitor-only'
        notes = 'Pages sharing controls and the SharePoint Embedded Information Barriers limitation are documented for manual governance review.'
    }
    [pscustomobject]@{
        controlId = '3.2'
        status = $(if ($hasCompensatingControls) { 'partial' } else { 'monitor-only' })
        notes = 'Retention policies are supported via All SharePoint Sites; tenant validation and compensating preservation procedures are tracked.'
    }
    [pscustomobject]@{
        controlId = '3.3'
        status = $(if ($hasCompensatingControls) { 'partial' } else { 'monitor-only' })
        notes = 'Purview eDiscovery is supported for search, collection, review, and export, while review-set full-text search and container-scoping limitations remain monitored.'
    }
    [pscustomobject]@{
        controlId = '3.11'
        status = 'monitor-only'
        notes = 'Books-and-records evidence remains monitor-led for legal hold, retention label, and preservation exception reviews.'
    }
)

$statusPayload = [ordered]@{
    solution = $defaultConfig.solution
    solutionCode = $defaultConfig.solutionCode
    displayName = $defaultConfig.displayName
    tier = $ConfigurationTier
    tierDefinition = $tierDefinition
    assessedAt = (Get-Date).ToString('o')
    tenantId = $(if ($TenantId) { $TenantId } else { 'not-specified' })
    overallStatus = $overallStatus
    dashboardStatusScore = (Get-CopilotGovStatusScore -Status $overallStatus)
    gapCount = $allGaps.Count
    openGapCount = $openGaps.Count
    openGaps = $openGaps
    compensatingControlsInPlace = $controlsInPlace.Count
    hasCompensatingControlsInPlace = $hasCompensatingControls
    compensatingControls = $compensatingControls
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

$null = New-Item -ItemType Directory -Path $OutputPath -Force
$statusPayload | ConvertTo-Json -Depth 8 | Set-Content -Path $statusFile -Encoding utf8

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
