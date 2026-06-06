# Freamon Pass-2 Re-Verification — Solution 21: Cross-Tenant Agent Federation Auditor

**Reviewer:** Freamon (Research / Verification)
**Pass:** 2 (second-opinion re-check against latest MS Learn, post-pass-1 corrections)
**Date:** 2026-06-05
**Scope:** README.md, docs/*.md, scripts/*.ps1, config/*.json

---

## VERDICT: CLEAN — no product/feature inaccuracies found (pass-2 re-verification).

All Microsoft product names, feature claims, API endpoints, permission names, and role names verified against current Microsoft Learn pages. No corrections required.

---

## Spot-Check Citations (key claims verified)

| Claim | File | Verified Result | Citation |
|-------|------|----------------|----------|
| "Streamable transport type" for MCP in Copilot Studio | README.md:75, docs/architecture.md, scripts/Monitor-Compliance.ps1:105 | ✅ CORRECT. MS Learn Copilot Studio MCP article states verbatim: "Currently, Copilot Studio supports the Streamable transport type." | https://learn.microsoft.com/microsoft-copilot-studio/agent-extend-mcp-existing |
| Graph endpoint `/policies/crossTenantAccessPolicy/partners` with `Policy.Read.All` as least-privileged permission | docs/prerequisites.md:14 | ✅ CORRECT. MS Learn Graph API reference confirms `Policy.Read.All` is the least-privileged delegated and application permission; `Policy.ReadWrite.CrossTenantAccess` applies to write scenarios only. | https://learn.microsoft.com/graph/api/crosstenantaccesspolicyconfigurationpartner-get |
| Entra roles: "Agent ID Administrator", "Agent ID Developer", "AI Administrator", "AI Reader", "Global Secure Access Administrator", "Security Reader", "Global Reader", "Teams Administrator", "Security Administrator" | docs/prerequisites.md:24-29 | ✅ ALL CONFIRMED as current Microsoft Entra built-in roles. Agent ID Administrator and Developer roles confirmed with their GUIDs and descriptions. AI Administrator and AI Reader confirmed. Global Secure Access Administrator confirmed. Supported roles for crossTenantAccessPolicy reads confirmed to include Security Reader, Global Reader, Global Secure Access Administrator, Teams Administrator, Security Administrator — matching the prerequisites exactly. | https://learn.microsoft.com/entra/identity/role-based-access-control/permissions-reference |
| Microsoft Entra Agent ID licensing ("Microsoft Agent 365 or Microsoft 365 E5 license, or component Entra ID P1/P2 + Global Secure Access") | docs/prerequisites.md:12-13 | ✅ CORRECT. MS Learn confirms: Microsoft Agent 365 license required for M365 service integration; Microsoft 365 E5 or component licenses (Entra ID P1/P2, Microsoft Entra Internet Access / Global Secure Access) required for security features (CA, ID Protection, ID Governance, network controls). Core Agent ID is available to all Microsoft Entra customers. | https://learn.microsoft.com/entra/identity/lifecycle-workflows/agent-identity-sponsor |
| "Authenticate with Microsoft" as Copilot Studio authentication option name | scripts/Monitor-Compliance.ps1:55 | ✅ CORRECT. MS Learn Copilot Studio authentication article confirms "Authenticate with Microsoft" is a valid authentication option name. | https://learn.microsoft.com/microsoft-copilot-studio/configuration-end-user-authentication |
| "Microsoft Entra External ID" for cross-tenant access settings | README.md:18, docs/architecture.md | ✅ CORRECT. MS Learn confirms cross-tenant access with Microsoft Entra External ID is the current product framing. | https://learn.microsoft.com/entra/external-id/cross-tenant-access-overview |

---

## Detailed Scan Notes

- **MCP transport terminology:** "Streamable transport type" (not "Streamable HTTP") is the **correct Copilot Studio-specific terminology**. Azure Functions docs use "Streamable HTTP" for generic MCP transport, but the Copilot Studio-specific documentation uses "Streamable transport type" — the solution is in the correct context. No flag.
- **Sample data values** (`authenticationType = 'Authenticate manually (Microsoft Entra ID)'`): The Copilot Studio UI option is named "Authenticate manually" (with Microsoft Entra ID as the underlying provider). The parenthetical "(Microsoft Entra ID)" is added for clarity in representative sample data and is not claimed to be the exact UI label in any doc section. No flag.
- **Organization sharing controls:** Scoping of cross-tenant agent sharing is controlled through Entra External ID cross-tenant access policies and Copilot Studio channel publishing settings — not through a single "organization sharing" UI toggle. The solution correctly frames these as a combined governance surface and does not overstate a single product feature. No flag.
- All four evidence output names, SHA-256 companion files, and tier configuration structure are documentation-first scaffolds and make no product API claims requiring verification.
