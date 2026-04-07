<#
.SYNOPSIS
Exports FMC evidence artifacts and the shared evidence package.

.DESCRIPTION
Generates documentation-led feature baseline, rollout history, and drift finding artifacts for the
selected governance tier, writes SHA-256 companion files for each emitted artifact, and then
packages the export by using the shared repository evidence contract.

.PARAMETER ConfigurationTier
The governance tier that the evidence package represents.

.PARAMETER OutputPath
Directory where the evidence package and companion artifacts are written.

.EXAMPLE
.\scripts\Export-Evidence.ps1 -ConfigurationTier regulated -OutputPath .\artifacts\FMC
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

function Copy-Value {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $copy = [ordered]@{}
        foreach ($key in $Value.Keys) {
            $copy[$key] = Copy-Value -Value $Value[$key]
        }

        return $copy
    }

    if (($Value -is [System.Collections.IEnumerable]) -and -not ($Value -is [string])) {
        $items = @()
        foreach ($item in $Value) {
            $items += ,(Copy-Value -Value $item)
        }

        return $items
    }

    return $Value
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
        $result[$key] = Copy-Value -Value $Base[$key]
    }

    foreach ($key in $Overlay.Keys) {
        if ($result.Contains($key) -and ($result[$key] -is [System.Collections.IDictionary]) -and ($Overlay[$key] -is [System.Collections.IDictionary])) {
            $result[$key] = Merge-Hashtable -Base $result[$key] -Overlay $Overlay[$key]
            continue
        }

        $result[$key] = Copy-Value -Value $Overlay[$key]
    }

    return $result
}

function Get-StableFeatureHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FeatureId
    )

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($FeatureId))
        return [BitConverter]::ToUInt32($bytes, 0)
    }
    finally {
        $sha.Dispose()
    }
}

function Get-FmcConfiguration {
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
$config = Get-FmcConfiguration -Tier $ConfigurationTier
$resolvedOutputPath = [IO.Path]::GetFullPath($OutputPath)
$null = New-Item -ItemType Directory -Path $resolvedOutputPath -Force
$capturedAt = (Get-Date).ToString('o')

# Feature baseline snapshot derived from tier configuration templates. In production,
# these values would be collected from live Microsoft 365, Teams, and Power Platform admin surfaces.
$featureStateBaseline = @(
    foreach ($feature in @($config.features)) {
        [pscustomobject]@{
            featureId = $feature.featureId
            displayName = $feature.displayName
            sourceSystem = $feature.sourceSystem
            category = $feature.category
            expectedEnabled = [bool]$feature.expectedEnabled
            expectedRing = $feature.expectedRing
            approvalReference = ('FMC-{0}-{1}' -f $ConfigurationTier.ToUpperInvariant(), $feature.featureId.ToUpperInvariant())
            capturedAt = $capturedAt
            tier = $ConfigurationTier
            riskNote = $feature.riskNote
        }
    }
)

# Sample rollout history entries for format validation. In production, these values
# would be derived from actual change records, approval workflows, and CAB tickets.
$rolloutRingHistory = @(
    foreach ($feature in @($config.features | Select-Object -First 3)) {
        [pscustomobject]@{
            changeId = ('FMC-CHG-{0}' -f $feature.featureId.ToUpperInvariant())
            featureId = $feature.featureId
            sourceRing = 'Restricted'
            targetRing = $feature.expectedRing
            requestedBy = 'Copilot Governance Board'
            approvedBy = if ($config.strictChangeApprovalRequired) { 'Compliance and Operations CAB' } else { 'Platform Operations Manager' }
            changedAt = $capturedAt
            changeTicket = ('CAB-{0}-{1}' -f $ConfigurationTier.ToUpperInvariant(), (Get-StableFeatureHash -FeatureId $feature.featureId))
            approvalMode = $config.changeApprovalMode
        }
    }
)

# Sample drift findings for format validation. In production, these would be generated
# by comparing observed tenant state against the approved baseline.
$driftFindings = @(
    [pscustomobject]@{
        findingId = 'FMC-DRIFT-001'
        featureId = 'teams-copilot-chat'
        driftType = 'unexpected-ring-membership'
        severity = 'medium'
        baselineValue = 'Early Adopters'
        observedValue = 'General Availability'
        detectedAt = $capturedAt
        remediationStatus = 'open'
        notes = 'One production policy assignment moved ahead of the approved ring plan.'
    }
)
# Only include third-party plugin drift finding when the feature is tracked in the selected tier
$pluginFeature = @($config.features) | Where-Object { $_.featureId -eq 'third-party-plugin-execution' }
if ($pluginFeature) {
    $driftFindings += [pscustomobject]@{
        findingId = 'FMC-DRIFT-002'
        featureId = 'third-party-plugin-execution'
        driftType = 'unapproved-enablement'
        severity = 'high'
        baselineValue = 'Disabled'
        observedValue = 'Enabled for pilot group'
        detectedAt = $capturedAt
        remediationStatus = 'investigating'
        notes = 'Connector governance review is still pending for one pilot connector.'
    }
}

$baselineArtifact = Write-ArtifactDocument -Path (Join-Path $resolvedOutputPath 'feature-state-baseline.json') -Name 'feature-state-baseline' -Content $featureStateBaseline
$historyArtifact = Write-ArtifactDocument -Path (Join-Path $resolvedOutputPath 'rollout-ring-history.json') -Name 'rollout-ring-history' -Content $rolloutRingHistory
$driftArtifact = Write-ArtifactDocument -Path (Join-Path $resolvedOutputPath 'drift-findings.json') -Name 'drift-findings' -Content $driftFindings

# Control implementation status based on solution capabilities. Review 'partial' controls
# before presenting the package as a final supervisory record.
$controls = @(
    [pscustomobject]@{
        controlId = '2.6'
        status = 'implemented'
        notes = 'Tier configuration defines approved feature scope, restricted-state handling, and evidence capture for feature baselines.'
    },
    [pscustomobject]@{
        controlId = '4.1'
        status = 'implemented'
        notes = 'FMC exports a normalized baseline of Microsoft 365, Teams, and Power Platform Copilot features.'
    },
    [pscustomobject]@{
        controlId = '4.2'
        status = 'implemented'
        notes = 'Expected enablement state and ring assignment are preserved in the feature-state baseline artifact.'
    },
    [pscustomobject]@{
        controlId = '4.3'
        status = 'implemented'
        notes = 'Rollout-ring history records approved promotions, restrictions, and rollout approvals.'
    },
    [pscustomobject]@{
        controlId = '4.4'
        status = 'partial'
        notes = 'Drift detection findings are exported, but remediation still requires tenant-specific operator action.'
    },
    [pscustomobject]@{
        controlId = '4.12'
        status = 'implemented'
        notes = 'Change tickets, approval routing, and ring transitions are captured for governance review.'
    },
    [pscustomobject]@{
        controlId = '4.13'
        status = 'partial'
        notes = 'Connector and plugin drift is surfaced, but deeper lifecycle governance depends on solution 10.'
    }
)

$partialControls = @($controls | Where-Object { $_.status -eq 'partial' }).Count
$artifacts = @($baselineArtifact, $historyArtifact, $driftArtifact)
$package = Export-SolutionEvidencePackage `
    -Solution '09-feature-management-controller' `
    -SolutionCode 'FMC' `
    -Tier $ConfigurationTier `
    -OutputPath $resolvedOutputPath `
    -Summary @{
        overallStatus = 'partial'
        recordCount = ($featureStateBaseline.Count + $rolloutRingHistory.Count + $driftFindings.Count)
        findingCount = $driftFindings.Count
        exceptionCount = $partialControls
    } `
    -Controls $controls `
    -Artifacts $artifacts

[pscustomobject]@{
    Package = $package
    Controls = $controls
    Artifacts = $artifacts
}
}
catch {
    $message = "Export-Evidence.ps1 failed for FMC: $($_.Exception.Message)"
    Write-Error $message
    throw
}
