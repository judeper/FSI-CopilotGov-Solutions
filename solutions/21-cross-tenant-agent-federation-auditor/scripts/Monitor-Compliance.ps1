<#
.SYNOPSIS
    Captures a sample federation, trust, MCP connection review, and Entra Agent ID governance snapshot for CTAF.

.DESCRIPTION
    Documentation-first monitoring script. Generates representative sample records for
    cross-tenant Copilot agent federation, cross-tenant trust assessment, MCP server
    connection review, and Entra Agent ID identity-governance review. No live tenant calls are made.

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
    Version:  v0.1.1
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
            channel = 'Microsoft Teams'
            authenticationType = 'Microsoft Entra ID'
            requireUsersToSignIn = $true
            sharingScope = 'Specific users and groups'
            allowedUsersOrGroups = @('partner-bank-agent-reviewers')
            approvedAudienceTenants = @('partner-bank.onmicrosoft.com')
            lastReviewedAt = (Get-Date).AddDays(-14).ToString('o')
        },
        [pscustomobject]@{
            agentId = 'agent-fsi-third-party-pricing'
            displayName = 'Third-Party Pricing Assistant'
            sourceTenantId = 'contoso-financial.onmicrosoft.com'
            channel = 'Custom channel'
            authenticationType = 'Microsoft Entra ID'
            requireUsersToSignIn = $true
            sharingScope = 'Approved partner tenants'
            allowedUsersOrGroups = @('vendor-marketdata-agent-reviewers', 'partner-bank-agent-reviewers')
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
    param([int]$MaxConnectionReviewAgeDays)
    return @(
        [pscustomobject]@{
            serverId = 'mcp-marketdata-prod'
            serverUrl = 'https://mcp.marketdata.example.com/mcp'
            transportType = 'streamable'
            authenticationType = 'OAuth 2.0'
            allowedTools = @('getQuote', 'getReferenceData')
            approvalRequired = $true
            lastConnectionReviewAt = (Get-Date).AddDays(- [int]($MaxConnectionReviewAgeDays / 2)).ToString('o')
            connectionReviewStatus = 'current'
            scopes = @('quotes.read', 'reference-data.read')
        },
        [pscustomobject]@{
            serverId = 'mcp-research-archive'
            serverUrl = 'https://mcp.research.example.com/mcp'
            transportType = 'streamable'
            authenticationType = 'API key'
            allowedTools = @('searchArchive')
            approvalRequired = $true
            lastConnectionReviewAt = (Get-Date).AddDays(- ($MaxConnectionReviewAgeDays + 7)).ToString('o')
            connectionReviewStatus = 'stale'
            scopes = @('research.read')
        }
    )
}

function Get-SampleAgentIdAttestations {
    param([int]$ReviewCadenceDays)
    return @(
        [pscustomobject]@{
            agentIdentityId = 'agent-fsi-research-copilot'
            displayName = 'FSI Research Copilot Agent ID'
            blueprintId = 'blueprint-fsi-research'
            owner = 'fsi-research-platform-owner'
            sponsor = 'fsi-research-business-sponsor'
            assignedPermissions = @('Sites.Read.All')
            conditionalAccessPosture = 'included-in-agent-policy'
            auditLogReference = 'entra-audit-agent-fsi-research-copilot'
            lastReviewedAt = (Get-Date).AddDays(- [int]($ReviewCadenceDays / 2)).ToString('o')
            reviewStatus = 'current'
        },
        [pscustomobject]@{
            agentIdentityId = 'agent-fsi-third-party-pricing'
            displayName = 'Third-Party Pricing Assistant Agent ID'
            blueprintId = 'blueprint-third-party-pricing'
            owner = 'market-data-platform-owner'
            sponsor = 'third-party-risk-sponsor'
            assignedPermissions = @('Files.Read.All')
            conditionalAccessPosture = 'policy-review-due'
            auditLogReference = 'entra-audit-agent-fsi-third-party-pricing'
            lastReviewedAt = (Get-Date).AddDays(- ($ReviewCadenceDays + 10)).ToString('o')
            reviewStatus = 'due'
        }
    )
}

Write-Verbose ("Loading CTAF configuration for tier [{0}]." -f $ConfigurationTier)
$configuration = Get-CtafConfiguration -Tier $ConfigurationTier
Test-CtafConfiguration -Configuration $configuration

$maxConnectionReviewAgeDays = if ($configuration.mcpAttestation.Contains('maxAttestationAgeDays')) {
    [int]$configuration.mcpAttestation.maxAttestationAgeDays
} else { 60 }

$snapshot = [pscustomobject]@{
    Solution = $configuration.solution
    Tier = $ConfigurationTier
    GeneratedAt = (Get-Date).ToString('o')
    RuntimeMode = 'sample'
    Warning = $script:SampleWarning
    FederationInventory = Get-SampleFederationInventory
    CrossTenantTrust = Get-SampleCrossTenantTrust -ReviewCadenceDays $configuration.federationReviewCadenceDays
    McpAttestations = Get-SampleMcpAttestations -MaxConnectionReviewAgeDays $maxConnectionReviewAgeDays
    AgentIdAttestations = Get-SampleAgentIdAttestations -ReviewCadenceDays $configuration.federationReviewCadenceDays
}

$resolvedOutputPath = (New-Item -ItemType Directory -Path $OutputPath -Force).FullName
$snapshotPath = Join-Path $resolvedOutputPath ("ctaf-monitoring-snapshot-{0}.json" -f $ConfigurationTier)
$snapshot | ConvertTo-Json -Depth 10 | Set-Content -Path $snapshotPath -Encoding utf8
$null = Write-CtafSha256File -Path $snapshotPath

Write-Host (
    "CTAF monitoring summary: tier [{0}] | agents {1} | trust relationships {2} | MCP connection reviews {3} | Agent ID governance reviews {4}." -f
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
