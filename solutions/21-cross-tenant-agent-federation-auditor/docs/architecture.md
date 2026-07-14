# Cross-Tenant Agent Federation Auditor — Architecture

## Solution Overview

The Cross-Tenant Agent Federation Auditor (CTAF) is a documentation-first auditor that records federation posture for Microsoft 365 Copilot agents, Microsoft Entra Agent IDs, and MCP server connections exposed across organizational boundaries. The repository implementation produces sample inventories and review evidence so that delivery teams can model cross-tenant agent risk before live tenant integration is wired.

> **Scope note.** Microsoft does not document a distinct "cross-tenant agent federation" product. CTAF audits cross-tenant trust and dependencies — Entra External ID cross-tenant access settings, multitenant app registrations and service principals, remote MCP connections, the Microsoft Agent 365 agent registry, and Microsoft Entra Agent ID governance. Copilot Studio multitenant mode and Microsoft Entra Agent ID are both in preview; verify current status with Microsoft before relying on them.

## Component Diagram

```text
+---------------------------------------------------------------+
| Sources reviewed by CTAF (live targets, sample data today)    |
| - Copilot Studio channels, authentication, and sharing         |
| - Copilot Studio multitenant mode (preview)                    |
| - Microsoft Agent 365 agent registry inventory                 |
| - Microsoft Entra Agent ID identities and blueprints (preview) |
| - Entra External ID cross-tenant access settings               |
| - MCP server connection and authentication settings            |
+------------------------------+--------------------------------+
                               |
                               v
+------------------------------+--------------------------------+
| Monitor-Compliance.ps1                                        |
| - Federation Inventory Collector (sample)                     |
| - Cross-Tenant Trust Assessor (sample)                        |
| - MCP Connection Review Reader (sample)                       |
| - Agent ID Governance Reader (sample)                         |
+------------------------------+--------------------------------+
                               |
                               v
+------------------------------+--------------------------------+
| Export-Evidence.ps1                                           |
| - agent-federation-inventory                                  |
| - cross-tenant-trust-assessment                               |
| - mcp-trust-relationship-log                                  |
| - agent-id-attestation-evidence                               |
| - JSON + SHA-256 packaging                                    |
+---------------------------------------------------------------+
```

## Data Flow

1. `Monitor-Compliance.ps1` reads tier configuration from `config/<tier>.json` and `config/default-config.json` via `CtafConfig.psm1`.
2. The script generates sample federation inventory, cross-tenant trust, MCP connection review, and Agent ID identity-governance records that mirror the contract that a future live integration would produce.
3. `Export-Evidence.ps1` serializes records into four JSON artifacts and writes a `.sha256` companion for each artifact.
4. Optional downstream consumption: a future enterprise dashboard (out of scope for this stub) may display the JSON outputs.

## Integration Points (Future)

- Microsoft Graph v1.0 `/policies/crossTenantAccessPolicy/partners` endpoint for cross-tenant access policy partner enumeration (least-privileged `Policy.Read.All`). Partner records expose B2B collaboration and B2B direct connect inbound/outbound settings, `inboundTrust`, `isServiceProvider`, and `isInMultiTenantOrganization`.
- Microsoft Agent 365 agent registry (Microsoft 365 admin center) and the Package Management API (documented as preview; `GET https://graph.microsoft.com/v1.0/copilot/admin/catalog/packages[/{id}]`, least-privileged `CopilotPackages.Read.All`, requires a Microsoft Agent 365 license) for read-only inventory of Microsoft, external partner-built, org-published, and creator-shared agents.
- Copilot Studio channel, authentication, organization sharing, and multitenant mode (preview) review patterns for cross-tenant user access.
- Microsoft Entra Agent ID (preview) blueprint, owner/sponsor, permission, Conditional Access, and audit-log review. Agent ID exposes no signing-key or key-rotation surface.
- MCP server URL, Streamable transport, API key/OAuth authentication, tool approval, and allow-list review. MCP has no Microsoft-defined signing-key attestation.

Correlating Agent 365 registry entries to Entra multitenant app registrations or service principals is a documented manual review; no single Microsoft API joins the two.

## Security Considerations

- Evidence artifacts may include tenant identifiers; treat as Confidential when generated against real tenants.
- Sample data in this scaffold is non-sensitive and safe for repository inclusion.
- Live integration must use least-privilege Entra app registrations and short-lived secrets stored in a managed secret store.
