# Cross-Tenant Agent Federation Auditor

> **Status:** Documentation-first scaffold | **Version:** v0.1.1 | **Priority:** P1 | **Track:** B

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365, Entra, or Copilot Studio services. See [Disclaimer](../../disclaimer.md) and [Documentation vs Runnable Assets Guide](../../documentation-vs-runnable-assets-guide.md).

## Overview

The Cross-Tenant Agent Federation Auditor (CTAF) is a documentation-first auditor for cross-tenant Microsoft 365 Copilot agent invocation patterns, Copilot Studio channels, authentication settings, organization sharing controls, Microsoft Entra Agent ID identity-governance metadata, and Model Context Protocol (MCP) server connection reviews. The repository implementation produces sample inventories, trust assessments, and review evidence so that delivery teams can reason about cross-org agent risk before live tenant integration is wired.

CTAF helps meet third-party and information-security governance expectations under GLBA §501(b), the FFIEC IT Handbook (Information Security Booklet), SEC Reg S-P, OCC Bulletin 2023-17 (Third-Party Risk Management), and FINRA Rule 3110 by improving visibility into who can invoke agents across tenant boundaries, what trust relationships are in force, and what MCP connection and Agent ID governance review evidence has been recorded.

## What This Solution Monitors

- Cross-tenant Copilot agent invocation patterns influenced by Copilot Studio channels, authentication settings, and organization sharing controls.
- Microsoft Entra Agent ID agent identity records, blueprints, owners, sponsors, Conditional Access posture, and sign-in/audit log references for each agent identity.
- MCP server connection review records, including server URL, Streamable transport type, authentication type, scopes, allowed tools, approval requirements, and review date.
- Cross-tenant access settings in Microsoft Entra External Identities that authorize or restrict agent invocation across organizational boundaries.

## Features

| Capability | Description |
|------------|-------------|
| Federation inventory pattern | Documents a repeatable inventory of Copilot agents, Copilot Studio channel/authentication/sharing settings, Entra Agent IDs, and MCP endpoints exposed across tenant boundaries; current version uses representative sample data. |
| Cross-tenant trust assessment | Records trust direction, allowed audiences, and review cadence for each federation relationship. |
| MCP connection review log | Records MCP server URL, Streamable transport type, authentication method, allowed tools/scopes, approval requirements, and review status for federated endpoints. |
| Agent ID governance evidence | Records agent identity IDs, blueprints, owners/sponsors, assigned permissions, Conditional Access posture, and sign-in/audit references for Entra Agent IDs. |
| Tier-aware deployment | Applies baseline, recommended, or regulated settings for review cadence, MCP connection-review rigor, Agent ID governance review, and audit log retention. |
| Documentation-first automation | Describes review workflows without forcing deployment-time changes to tenant policy. |

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not enumerate live Copilot Studio publishing settings (sample agent inventory only).
- ❌ Does not call Microsoft Graph for Entra cross-tenant access policies (sample trust records only).
- ❌ Does not perform live MCP server calls, tool approval changes, or cryptographic attestation; connection review evidence is template-driven.
- ❌ Does not modify Entra Agent ID configurations, assign permissions, or manage credentials.
- ❌ Does not block agent invocation; CTAF is detective and evidentiary, not preventive.
- ❌ Does not cover internal-only (single-tenant) agents — see solution 20 for in-tenant agent inventory.

> **Data classification:** See [Data Classification Matrix](../../reference/data-classification.md) for residency, retention, and data-class metadata.

## Prerequisites

Review [docs/prerequisites.md](prerequisites.md) for the required admin roles, PowerShell modules, and Microsoft 365 prerequisites before deploying this solution.

## Architecture

CTAF uses PowerShell stub scripts for deployment, monitoring, and evidence export, JSON tier configuration files, and documentation-first guidance for review workflows. See [docs/architecture.md](architecture.md) for the component diagram, data flow, and integration points.

## Deployment

1. Review [docs/prerequisites.md](prerequisites.md) and confirm Entra, Copilot Studio, and MCP review prerequisites.
2. Select a governance tier (`baseline`, `recommended`, `regulated`) and review `config/<tier>.json` together with `config/default-config.json`.
3. Run `scripts\Deploy-Solution.ps1 -ConfigurationTier <tier> -WhatIf` to validate the planned manifest.
4. Run `scripts\Monitor-Compliance.ps1 -ConfigurationTier <tier>` to generate a sample federation inventory and trust assessment.
5. Run `scripts\Export-Evidence.ps1 -ConfigurationTier <tier>` to generate the evidence package and verify each JSON file has a matching `.sha256` companion.

## Configuration Tiers

| Tier | Federation Review Cadence | MCP Connection Review | Agent ID Governance Review | Cross-Tenant Audit Retention |
|------|---------------------------|-----------------------|----------------------------|------------------------------|
| baseline | 90 days | Optional | Recommended | 90 days |
| recommended | 30 days | Required | Required | 365 days |
| regulated | 7 days | Required + revalidation | Required + customer-defined credential review | 1825 days (7 years aligned to broker-dealer record-keeping practice) |

## Evidence Export

The solution exports the following evidence outputs:

- `agent-federation-inventory` — Copilot agents, Copilot Studio channel/authentication/sharing settings, and Entra Agent IDs exposed across tenant boundaries.
- `cross-tenant-trust-assessment` — review status of cross-tenant access settings and external collaboration scopes that affect agent invocation.
- `mcp-trust-relationship-log` — MCP server connection review records with server URL, Streamable transport, authentication method, approval requirements, scopes/tools, and review status.
- `agent-id-attestation-evidence` — Microsoft Entra Agent ID identity-governance review records with blueprint, owner/sponsor, permissions, Conditional Access, and audit-log references.

All evidence packages are written as JSON with SHA-256 companion files.

## Related Controls

| Control | Title | Role |
|---------|-------|------|
| 2.17 | Microsoft Entra Agent ID Lifecycle Governance | Primary |
| 2.16 | Cross-Tenant Copilot and Agent Access Governance | Primary |
| 1.10 | Third-Party and External Connector Governance | Supporting |
| 2.13 | Copilot Studio Agent Publishing Controls | Supporting |
| 2.14 | MCP Server Trust and Attestation | Supporting |
| 4.13 | Cross-Tenant Audit Log Aggregation | Supporting |

> **Playbooks:** Control implementation playbooks (portal walkthroughs, PowerShell setup, verification, troubleshooting) are maintained in the FSI-CopilotGov framework repository under `docs/playbooks/control-implementations/`.

## Regulatory Alignment

CTAF supports compliance with:

- **GLBA §501(b)** — administrative, technical, and physical safeguards for nonpublic personal information when agents cross organizational boundaries.
- **FFIEC IT Handbook (Information Security Booklet)** — third-party connectivity, identity federation, and authentication oversight.
- **SEC Reg S-P** — safeguards for customer information potentially exposed through cross-tenant agent flows.
- **OCC Bulletin 2023-17 (Third-Party Risk Management)** — risk management for third-party agent endpoints, MCP servers, and federated identity providers.
- **FINRA Rule 3110** — supervisory systems and written supervisory procedures for cross-tenant agent activity recorded by the broker-dealer.

CTAF aids in evidencing these obligations but does not on its own satisfy them. Organizations should verify that configurations match their specific regulatory program and supervisory procedures.

## Roadmap

- v0.2.0 — Add live Microsoft Graph integration patterns for Entra cross-tenant access policy enumeration.
- v0.3.0 — Add Copilot Studio publishing telemetry hook patterns (read-only).
- v0.4.0 — Add MCP connection/authentication validation reference (review pattern, no transport calls).
