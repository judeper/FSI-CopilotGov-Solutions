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
        name        = $Name
        type        = 'json'
        path        = $Path
        packagePath = [IO.Path]::GetFileName($Path)
        hash        = $hashInfo.Hash
    }
}

try {
$config = Get-FmcConfiguration -Tier $ConfigurationTier
$null = New-Item -ItemType Directory -Path $OutputPath -Force
$resolvedOutputPath = (Resolve-Path -Path $OutputPath).Path
$capturedAt = (Get-Date).ToString('o')

# Runtime honesty markers. All artifacts below are derived from tier configuration
# templates and representative sample values, not from live Microsoft 365, Teams, or
# Power Platform admin surfaces. These markers must remain in the exported package so
# reviewers do not treat sample control states as proof of live enforcement.
$runtimeMode = 'documentation-first'
$dataSourceMode = 'representative-sample'

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

# Control implementation status based on solution capabilities. All states are 'partial'
# because the exported evidence is representative sample data derived from tier templates,
# not live tenant collection. Live tenant evidence is required before any control can be
# presented as implemented in a supervisory record.
$controls = @(
    [pscustomobject]@{
        controlId = '2.6'
        status = 'partial'
        notes = 'Tier configuration documents approved feature scope, restricted-state handling, and the Cloud Policy "Allow web search in Copilot" state; the exported baseline is representative sample data and does not read the live Cloud Policy or Purview DLP web-search boundary.'
    },
    [pscustomobject]@{
        controlId = '4.1'
        status = 'partial'
        notes = 'Exports a normalized sample baseline of Microsoft 365, Teams, and Power Platform Copilot features; live inventory from admin surfaces (Copilot Control System, Teams admin center, Power Platform admin center) is a customer implementation step.'
    },
    [pscustomobject]@{
        controlId = '4.2'
        status = 'partial'
        notes = 'Expected Teams meetings Copilot enablement and ring assignment are preserved in the sample baseline; live state from Set-CsTeamsMeetingPolicy -Copilot is not read by this scaffold.'
    },
    [pscustomobject]@{
        controlId = '4.3'
        status = 'partial'
        notes = 'Rollout-ring history records sample promotions and approvals for the Teams calls/phone extension pattern; live state from Set-CsTeamsCallingPolicy -Copilot is not read by this scaffold.'
    },
    [pscustomobject]@{
        controlId = '4.4'
        status = 'partial'
        notes = 'Drift detection findings are exported using representative sample data; remediation and Viva Suite coverage still require tenant-specific operator action.'
    },
    [pscustomobject]@{
        controlId = '4.12'
        status = 'partial'
        notes = 'Sample change tickets, approval routing, and ring transitions demonstrate the governance record shape; live change records must be supplied by the customer.'
    },
    [pscustomobject]@{
        controlId = '4.13'
        status = 'partial'
        notes = 'Connector and plugin drift is surfaced with sample data; deeper agent, connector, and plugin lifecycle governance depends on solution 10 and Microsoft Agent 365.'
    }
)

$partialControls = @($controls | Where-Object { $_.status -ne 'implemented' }).Count
$artifacts = @($baselineArtifact, $historyArtifact, $driftArtifact)

# Package artifact references use package-relative file names so the evidence package
# stays portable and free of local filesystem paths when relocated. Absolute paths are
# returned to the caller for immediate inspection only.
$packageArtifacts = @(
    foreach ($artifact in $artifacts) {
        [pscustomobject]@{
            name = $artifact.name
            type = $artifact.type
            path = $artifact.packagePath
            hash = $artifact.hash
        }
    }
)

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
        statusSemantics = 'Control states describe documentation-first sample evidence and must not be treated as proof of live Copilot feature enforcement.'
    } `
    -Controls $controls `
    -Artifacts $packageArtifacts `
    -ExpectedArtifacts ([string[]]$config.evidenceOutputs) `
    -AdditionalMetadata ([ordered]@{ runtimeMode = $runtimeMode; dataSourceMode = $dataSourceMode })

[pscustomobject]@{
    Package = $package
    Controls = $controls
    Artifacts = $artifacts
    RuntimeMode = $runtimeMode
    DataSourceMode = $dataSourceMode
}
}
catch {
    $message = "Export-Evidence.ps1 failed for FMC: $($_.Exception.Message)"
    Write-Error $message
    throw
}
