<#
.SYNOPSIS
    Exports CTAF evidence artifacts as JSON files with SHA-256 companion sidecars.

.DESCRIPTION
    Documentation-first evidence export. Invokes Monitor-Compliance.ps1 to gather a
    sample snapshot, then writes four evidence artifacts: agent-federation-inventory,
    cross-tenant-trust-assessment, mcp-trust-relationship-log, and
    agent-id-attestation-evidence. Each artifact is paired with a .sha256 sidecar.

.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.

.PARAMETER OutputPath
    Path for exported evidence artifacts.

.PARAMETER PeriodStart
    Beginning of the evidence window (defaults to 30 days ago).

.PARAMETER PeriodEnd
    End of the evidence window (defaults to now).

.PARAMETER PassThru
    Returns the evidence summary object after writing artifacts.

.EXAMPLE
    .\Export-Evidence.ps1 -ConfigurationTier recommended -Verbose

.NOTES
    Solution: Cross-Tenant Agent Federation Auditor (CTAF)
    Version:  v0.1.0
    Status:   Documentation-first scaffold (sample data only)
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

Import-Module (Join-Path $PSScriptRoot 'CtafConfig.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '..\..\..\scripts\common\IntegrationConfig.psm1') -Force

if ($PeriodEnd -lt $PeriodStart) {
    throw 'PeriodEnd must be greater than or equal to PeriodStart.'
}

function New-CtafArtifactFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [object]$Content
    )

    $directory = Split-Path -Path $Path -Parent
    $null = New-Item -ItemType Directory -Path $directory -Force
    $Content | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding utf8
    $hashInfo = Write-CtafSha256File -Path $Path

    return [pscustomobject]@{
        Path = $Path
        Hash = $hashInfo.Hash
    }
}

Write-Verbose ("Loading CTAF configuration for tier [{0}]." -f $ConfigurationTier)
$configuration = Get-CtafConfiguration -Tier $ConfigurationTier
Test-CtafConfiguration -Configuration $configuration

$resolvedOutputPath = (New-Item -ItemType Directory -Path $OutputPath -Force).FullName
$monitorScript = Join-Path $PSScriptRoot 'Monitor-Compliance.ps1'

Write-Verbose 'Collecting monitoring snapshot for evidence export.'
$snapshot = & $monitorScript -ConfigurationTier $ConfigurationTier -OutputPath $resolvedOutputPath -PassThru -Verbose:$($VerbosePreference -eq 'Continue')

$envelope = {
    param($recordsArr)
    [ordered]@{
        solution = $configuration.solution
        tier = $ConfigurationTier
        periodStart = $PeriodStart.ToString('o')
        periodEnd = $PeriodEnd.ToString('o')
        generatedAt = (Get-Date).ToString('o')
        runtimeMode = 'sample'
        warning = $snapshot.Warning
        retentionDays = $configuration.evidenceRetentionDays
        records = $recordsArr
    }
}

$inventoryArtifact = & $envelope @($snapshot.FederationInventory)
$trustArtifact = & $envelope @($snapshot.CrossTenantTrust)
$mcpArtifact = & $envelope @($snapshot.McpAttestations)
$agentIdArtifact = & $envelope @($snapshot.AgentIdAttestations)

$inventoryFile = New-CtafArtifactFile -Path (Join-Path $resolvedOutputPath ("agent-federation-inventory-{0}.json" -f $ConfigurationTier)) -Content $inventoryArtifact
$trustFile = New-CtafArtifactFile -Path (Join-Path $resolvedOutputPath ("cross-tenant-trust-assessment-{0}.json" -f $ConfigurationTier)) -Content $trustArtifact
$mcpFile = New-CtafArtifactFile -Path (Join-Path $resolvedOutputPath ("mcp-trust-relationship-log-{0}.json" -f $ConfigurationTier)) -Content $mcpArtifact
$agentIdFile = New-CtafArtifactFile -Path (Join-Path $resolvedOutputPath ("agent-id-attestation-evidence-{0}.json" -f $ConfigurationTier)) -Content $agentIdArtifact

$controls = @(
    [pscustomobject]@{
        controlId = '2.17'
        status = 'partial'
        notes = 'Entra Agent ID attestation evidence is exported using sample records; live Graph integration is required for production evidence.'
    },
    [pscustomobject]@{
        controlId = '2.16'
        status = 'partial'
        notes = 'Cross-tenant access posture is exported using sample records; live cross-tenant access policy enumeration is required for production evidence.'
    },
    [pscustomobject]@{
        controlId = '1.10'
        status = 'monitor-only'
        notes = 'Third-party connector inventory is referenced via MCP attestation log; full third-party register lives outside this solution.'
    },
    [pscustomobject]@{
        controlId = '2.13'
        status = 'monitor-only'
        notes = 'Copilot Studio publishing settings are sampled; live admin API enumeration is roadmapped.'
    },
    [pscustomobject]@{
        controlId = '2.14'
        status = 'partial'
        notes = 'MCP federated server trust is recorded in mcp-trust-relationship-log; signing-key verification is roadmapped.'
    },
    [pscustomobject]@{
        controlId = '4.13'
        status = 'monitor-only'
        notes = 'Cross-tenant audit log retention is documented per tier; live aggregation requires Sentinel or equivalent provisioning.'
    }
)

$artifacts = @(
    [pscustomobject]@{ name = 'agent-federation-inventory'; type = 'json'; path = $inventoryFile.Path; hash = $inventoryFile.Hash },
    [pscustomobject]@{ name = 'cross-tenant-trust-assessment'; type = 'json'; path = $trustFile.Path; hash = $trustFile.Hash },
    [pscustomobject]@{ name = 'mcp-trust-relationship-log'; type = 'json'; path = $mcpFile.Path; hash = $mcpFile.Hash },
    [pscustomobject]@{ name = 'agent-id-attestation-evidence'; type = 'json'; path = $agentIdFile.Path; hash = $agentIdFile.Hash }
)

$recordCount = @($snapshot.FederationInventory).Count + @($snapshot.CrossTenantTrust).Count + @($snapshot.McpAttestations).Count + @($snapshot.AgentIdAttestations).Count
$findingCount = (@($snapshot.CrossTenantTrust) | Where-Object { $_.reviewStatus -ne 'current' }).Count +
                (@($snapshot.McpAttestations) | Where-Object { $_.attestationStatus -ne 'current' }).Count +
                (@($snapshot.AgentIdAttestations) | Where-Object { $_.verificationStatus -ne 'verified' }).Count
$exceptionCount = ($controls | Where-Object { $_.status -ne 'implemented' }).Count

$packageManifest = [ordered]@{
    metadata = [ordered]@{
        solution = $configuration.solution
        solutionCode = $configuration.solutionCode
        exportVersion = (Get-CopilotGovEvidenceSchemaVersion)
        exportedAt = (Get-Date).ToString('o')
        tier = $ConfigurationTier
        generatedAt = (Get-Date).ToString('o')
        runtimeMode = 'sample'
        documentationFirstNotice = 'Evidence package generated from documentation-first sample data; not suitable for examiner submission.'
    }
    summary = [ordered]@{
        overallStatus = 'partial'
        recordCount = $recordCount
        findingCount = $findingCount
        exceptionCount = $exceptionCount
    }
    controls = $controls
    artifacts = $artifacts
}

$packagePath = Join-Path $resolvedOutputPath ("ctaf-evidence-package-{0}.json" -f $ConfigurationTier)
$packageManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $packagePath -Encoding utf8
$null = Write-CtafSha256File -Path $packagePath

$result = [pscustomobject]@{
    Summary = $packageManifest
    Controls = $controls
    Artifacts = $artifacts
    PackagePath = $packagePath
    RuntimeMode = 'sample'
}

if ($PassThru) {
    return $result
}

$result
