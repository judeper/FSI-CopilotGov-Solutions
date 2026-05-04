<#
.SYNOPSIS
    Exports Copilot Studio agent lifecycle evidence for supervisory review.

.DESCRIPTION
    Builds agent-lifecycle-inventory, publishing-approval-log, version-history, and
    deprecation-evidence artifacts and writes JSON files with SHA-256 companions.
    Supports compliance with FFIEC IT Handbook (Operations Booklet) change-management
    expectations, FINRA Rule 3110 supervisory-systems and WSP expectations, OCC
    Bulletin 2023-17 third-party risk-management considerations, and Sarbanes-Oxley
    §§302/404 change-control documentation where applicable to ICFR.

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
    Solution: Copilot Studio Agent Lifecycle Tracker (CSLT)
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
    [datetime]$PeriodStart = (Get-Date).Date.AddDays(-30),

    [Parameter()]
    [datetime]$PeriodEnd = (Get-Date),

    [Parameter()]
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'CsltConfig.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '..\..\..\scripts\common\IntegrationConfig.psm1') -Force

function Write-Sha256Companion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $hash = (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    $hashPath = "$Path.sha256"
    "$hash  $(Split-Path -Leaf $Path)" | Set-Content -Path $hashPath -Encoding utf8
    return [pscustomobject]@{ Path = $hashPath; Hash = $hash }
}

function New-CsltArtifactFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [object]$Content
    )

    $directory = Split-Path -Path $Path -Parent
    $null = New-Item -ItemType Directory -Path $directory -Force
    $Content | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding utf8
    $hashInfo = Write-Sha256Companion -Path $Path
    return [pscustomobject]@{ Path = $Path; Hash = $hashInfo.Hash }
}

Write-Verbose ("Loading CSLT configuration for tier [{0}]." -f $ConfigurationTier)
$configuration = Get-CsltConfiguration -Tier $ConfigurationTier
Test-CsltConfiguration -Configuration $configuration

$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$null = New-Item -ItemType Directory -Path $resolvedOutputPath -Force

$now = (Get-Date).ToUniversalTime()
$periodMetadata = [ordered]@{
    periodStart = $PeriodStart.ToUniversalTime().ToString('o')
    periodEnd = $PeriodEnd.ToUniversalTime().ToString('o')
    exportedAt = $now.ToString('o')
    tier = $ConfigurationTier
    sourceEndpoint = 'local-cslt-stub'
}

$inventory = @{
    metadata = $periodMetadata
    records = @(
        [pscustomobject]@{
            agentId = 'sample-agent-production'
            displayName = 'Sample Copilot Studio Agent (production)'
            environment = 'production'
            owner = 'sample.owner@contoso.com'
            businessSponsor = 'sample.sponsor@contoso.com'
            currentVersion = '1.0.0'
            lastPublishedAt = $now.AddDays(-15).ToString('o')
            lastReviewedAt = $now.AddDays(-45).ToString('o')
            lifecycleStage = 'publishing'
        }
    )
}

$approvals = @{
    metadata = $periodMetadata
    records = @(
        [pscustomobject]@{
            agentId = 'sample-agent-production'
            version = '1.0.0'
            submittedBy = 'sample.author@contoso.com'
            submittedAt = $now.AddDays(-16).ToString('o')
            approvers = if ($configuration.dualApproverRequired) { @('sample.approver1@contoso.com','sample.approver2@contoso.com') } else { @('sample.approver1@contoso.com') }
            approvedAt = $now.AddDays(-15).ToString('o')
            changeSummary = 'Initial publish of sample agent.'
            tierApprovalRequirementMet = $true
        }
    )
}

$versions = @{
    metadata = $periodMetadata
    records = @(
        [pscustomobject]@{
            agentId = 'sample-agent-production'
            version = '1.0.0'
            publishedAt = $now.AddDays(-15).ToString('o')
            publishedBy = 'sample.author@contoso.com'
            changeNotes = 'Initial release.'
            rollbackOf = $null
            previousVersion = $null
        }
    )
}

$deprecations = @{
    metadata = $periodMetadata
    records = @(
        [pscustomobject]@{
            agentId = 'sample-agent-deprecated'
            deprecationAnnouncedAt = $now.AddDays(-90).ToString('o')
            customerNotifiedAt = $now.AddDays(-89).ToString('o')
            sunsetDate = $now.AddDays($configuration.deprecationNoticeDays).ToString('o')
            finalDisposition = 'pending-sunset'
            recordsRetentionConfirmed = $false
            notes = 'Sample deprecation record - replace with tenant data.'
        }
    )
}

$artifacts = @()
$inventoryFile = New-CsltArtifactFile -Path (Join-Path $resolvedOutputPath ("agent-lifecycle-inventory-{0}.json" -f $ConfigurationTier)) -Content $inventory
$approvalFile  = New-CsltArtifactFile -Path (Join-Path $resolvedOutputPath ("publishing-approval-log-{0}.json"   -f $ConfigurationTier)) -Content $approvals
$versionFile   = New-CsltArtifactFile -Path (Join-Path $resolvedOutputPath ("version-history-{0}.json"           -f $ConfigurationTier)) -Content $versions
$deprecFile    = New-CsltArtifactFile -Path (Join-Path $resolvedOutputPath ("deprecation-evidence-{0}.json"      -f $ConfigurationTier)) -Content $deprecations

$artifacts = @(
    [pscustomobject]@{ name = 'agent-lifecycle-inventory'; type = 'json'; path = $inventoryFile.Path; hash = $inventoryFile.Hash },
    [pscustomobject]@{ name = 'publishing-approval-log';   type = 'json'; path = $approvalFile.Path;  hash = $approvalFile.Hash },
    [pscustomobject]@{ name = 'version-history';           type = 'json'; path = $versionFile.Path;   hash = $versionFile.Hash },
    [pscustomobject]@{ name = 'deprecation-evidence';      type = 'json'; path = $deprecFile.Path;    hash = $deprecFile.Hash }
)

$package = [pscustomobject]@{
    metadata = [ordered]@{
        solution = $configuration.solution
        solutionCode = $configuration.solutionCode
        exportVersion = (Get-CopilotGovEvidenceSchemaVersion)
        version = $configuration.version
        tier = $ConfigurationTier
        exportedAt = $now.ToString('o')
    }
    summary = [ordered]@{
        overallStatus = 'partial'
        recordCount = ($inventory.records.Count + $approvals.records.Count + $versions.records.Count + $deprecations.records.Count)
        findingCount = 0
        exceptionCount = 0
    }
    controls = @(
        [pscustomobject]@{ controlId = '4.14'; status = 'partial' },
        [pscustomobject]@{ controlId = '4.13'; status = 'partial' },
        [pscustomobject]@{ controlId = '1.10'; status = 'monitor-only' },
        [pscustomobject]@{ controlId = '1.16'; status = 'monitor-only' },
        [pscustomobject]@{ controlId = '4.5'; status = 'monitor-only' },
        [pscustomobject]@{ controlId = '4.12'; status = 'monitor-only' }
    )
    artifacts = $artifacts
}

$packagePath = Join-Path $resolvedOutputPath '23-copilot-studio-lifecycle-tracker-evidence.json'
$package | ConvertTo-Json -Depth 10 | Set-Content -Path $packagePath -Encoding utf8
$null = Write-Sha256Companion -Path $packagePath

Write-Host (
    "CSLT evidence export [{0}]: {1} artifacts written to {2}." -f
    $ConfigurationTier,
    $artifacts.Count,
    $resolvedOutputPath
)

if ($PassThru) {
    return $package
}
