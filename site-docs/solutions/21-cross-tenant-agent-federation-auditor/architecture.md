# Cross-Tenant Agent Federation Auditor — Architecture

## Solution Overview

The Cross-Tenant Agent Federation Auditor (CTAF) is a documentation-first auditor that records federation posture for Microsoft 365 Copilot agents, Microsoft Entra Agent IDs, and MCP server connections exposed across organizational boundaries. The repository implementation produces sample inventories and review evidence so that delivery teams can model cross-tenant agent risk before live tenant integration is wired.

## Component Diagram

```text
+---------------------------------------------------------------+
| Sources reviewed by CTAF (live targets, sample data today)    |
| - Copilot Studio channels, authentication, and sharing         |
| - Microsoft Entra Agent ID identities and blueprints           |
| - Entra External Identities cross-tenant access settings       |
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

- Microsoft Graph v1.0 `/policies/crossTenantAccessPolicy/partners` endpoint for cross-tenant access policy partner enumeration.
- Copilot Studio channel, authentication, and organization sharing review patterns.
- MCP server URL, Streamable transport, API key/OAuth authentication, tool approval, and allow-list review.

## Security Considerations

- Evidence artifacts may include tenant identifiers; treat as Confidential when generated against real tenants.
- Sample data in this scaffold is non-sensitive and safe for repository inclusion.
- Live integration must use least-privilege Entra app registrations and short-lived secrets stored in a managed secret store.
