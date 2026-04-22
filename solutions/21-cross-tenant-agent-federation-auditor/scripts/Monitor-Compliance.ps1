<#
.SYNOPSIS
    Captures a sample federation, trust, MCP attestation, and Entra Agent ID snapshot for CTAF.

.DESCRIPTION
    Documentation-first monitoring script. Generates representative sample records for
    cross-tenant Copilot agent federation, cross-tenant trust assessment, MCP federated
    server attestation, and Entra Agent ID attestation. No live tenant calls are made.

.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.

.PARAMETER OutputPath
    Path for the monitoring snapshot.

.PARAMETER PassThru
    Returns the snapshot object after writing it.

.EXAMPLE
    .\Monitor-Compliance.ps1 -ConfigurationTier recommended -Verbose

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
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'CtafConfig.psm1') -Force

$script:SampleWarning = 'Snapshot output is generated from documentation-first sample data; no live Microsoft 365, Entra, or MCP calls were made.'

function Get-SampleFederationInventory {
    return @(
        [pscustomobject]@{
            agentId = 'agent-fsi-research-copilot'
            displayName = 'FSI Research Copilot'
            sourceTenantId = 'contoso-financial.onmicrosoft.com'
            publishingMode = 'restricted-multi-tenant'
            approvedAudienceTenants = @('partner-bank.onmicrosoft.com')
            lastReviewedAt = (Get-Date).AddDays(-14).ToString('o')
        },
        [pscustomobject]@{
            agentId = 'agent-fsi-third-party-pricing'
            displayName = 'Third-Party Pricing Assistant'
            sourceTenantId = 'contoso-financial.onmicrosoft.com'
            publishingMode = 'multi-tenant'
            approvedAudienceTenants = @('vendor-marketdata.onmicrosoft.com', 'partner-bank.onmicrosoft.com')
            lastReviewedAt = (Get-Date).AddDays(-45).ToString('o')
        }
    )
}

function Get-SampleCrossTenantTrust {
    param([int]$ReviewCadenceDays)
    return @(
        [pscustomobject]@{
            relationshipId = 'xt-rel-partner-bank'
            direction = 'outbound'
            partnerTenantId = 'partner-bank.onmicrosoft.com'
            allowedAudiences = @('agent-fsi-research-copilot')
            lastReviewedAt = (Get-Date).AddDays(- ($ReviewCadenceDays - 5)).ToString('o')
            reviewStatus = 'current'
        },
        [pscustomobject]@{
            relationshipId = 'xt-rel-vendor-marketdata'
            direction = 'bidirectional'
            partnerTenantId = 'vendor-marketdata.onmicrosoft.com'
            allowedAudiences = @('agent-fsi-third-party-pricing')
            lastReviewedAt = (Get-Date).AddDays(- ($ReviewCadenceDays + 10)).ToString('o')
            reviewStatus = 'overdue'
        }
    )
}

function Get-SampleMcpAttestations {
    param([int]$MaxAttestationAgeDays)
    return @(
        [pscustomobject]@{
            serverId = 'mcp-marketdata-prod'
            transport = 'https'
            signingKeyThumbprint = '0F1E2D3C4B5A69788796A5B4C3D2E1F0FEDCBA98'
            attestedAt = (Get-Date).AddDays(- [int]($MaxAttestationAgeDays / 2)).ToString('o')
            attestationStatus = 'current'
            scopes = @('quotes.read', 'reference-data.read')
        },
        [pscustomobject]@{
            serverId = 'mcp-research-archive'
            transport = 'https'
            signingKeyThumbprint = 'A1B2C3D4E5F60718293A4B5C6D7E8F90FEDCBA01'
            attestedAt = (Get-Date).AddDays(- ($MaxAttestationAgeDays + 7)).ToString('o')
            attestationStatus = 'stale'
            scopes = @('research.read')
        }
    )
}

function Get-SampleAgentIdAttestations {
    param([bool]$SigningRequired, [int]$MaxKeyAgeDays)
    return @(
        [pscustomobject]@{
            agentId = 'agent-fsi-research-copilot'
            signingRequired = $SigningRequired
            lastKeyRotationAt = (Get-Date).AddDays(-30).ToString('o')
            nextKeyRotationDueAt = (Get-Date).AddDays($MaxKeyAgeDays - 30).ToString('o')
            verificationStatus = 'verified'
        },
        [pscustomobject]@{
            agentId = 'agent-fsi-third-party-pricing'
            signingRequired = $SigningRequired
            lastKeyRotationAt = (Get-Date).AddDays(- ($MaxKeyAgeDays + 15)).ToString('o')
            nextKeyRotationDueAt = (Get-Date).AddDays(-15).ToString('o')
            verificationStatus = 'pending'
        }
    )
}

Write-Verbose ("Loading CTAF configuration for tier [{0}]." -f $ConfigurationTier)
$configuration = Get-CtafConfiguration -Tier $ConfigurationTier
Test-CtafConfiguration -Configuration $configuration

$maxAttestationAgeDays = if ($configuration.mcpAttestation.Contains('maxAttestationAgeDays')) {
    [int]$configuration.mcpAttestation.maxAttestationAgeDays
} else { 60 }
$maxKeyAgeDays = if ($null -ne $configuration.agentIdRotation -and $configuration.agentIdRotation.Contains('maxKeyAgeDays')) {
    [int]$configuration.agentIdRotation.maxKeyAgeDays
} else { 365 }

$snapshot = [pscustomobject]@{
    Solution = $configuration.solution
    Tier = $ConfigurationTier
    GeneratedAt = (Get-Date).ToString('o')
    RuntimeMode = 'sample'
    Warning = $script:SampleWarning
    FederationInventory = Get-SampleFederationInventory
    CrossTenantTrust = Get-SampleCrossTenantTrust -ReviewCadenceDays $configuration.federationReviewCadenceDays
    McpAttestations = Get-SampleMcpAttestations -MaxAttestationAgeDays $maxAttestationAgeDays
    AgentIdAttestations = Get-SampleAgentIdAttestations -SigningRequired ([bool]$configuration.agentIdSigningRequired) -MaxKeyAgeDays $maxKeyAgeDays
}

$resolvedOutputPath = (New-Item -ItemType Directory -Path $OutputPath -Force).FullName
$snapshotPath = Join-Path $resolvedOutputPath ("ctaf-monitoring-snapshot-{0}.json" -f $ConfigurationTier)
$snapshot | ConvertTo-Json -Depth 10 | Set-Content -Path $snapshotPath -Encoding utf8
$null = Write-CtafSha256File -Path $snapshotPath

Write-Host (
    "CTAF monitoring summary: tier [{0}] | agents {1} | trust relationships {2} | MCP attestations {3} | Agent ID attestations {4}." -f
    $ConfigurationTier,
    @($snapshot.FederationInventory).Count,
    @($snapshot.CrossTenantTrust).Count,
    @($snapshot.McpAttestations).Count,
    @($snapshot.AgentIdAttestations).Count
)

if ($PassThru) {
    return $snapshot
}

$snapshot
