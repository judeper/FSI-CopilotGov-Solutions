# Copilot Connector and Plugin Governance

> **Status:** Documentation-first scaffold | **Version:** v0.2.4 | **Priority:** P1 | **Track:** C
>
> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](../../docs/documentation-vs-runnable-assets-guide.md).

## Overview

Copilot Connector and Plugin Governance extends Copilot supervision into the connector, plugin, and extensibility layer used by Microsoft 365 Copilot, Copilot Studio, Copilot connectors (formerly Graph connectors), and Power Platform based agent scenarios. In a financial services environment, those extensibility paths can introduce third-party risk, data egress risk, and approval obligations that sit within FINRA 3110 supervisory scope, OCC 2011-12 third-party risk management expectations, and DORA ICT third-party risk oversight.

This solution inventories connectors and plugins, applies risk classification, routes approval requests, and records data-flow boundary decisions for approved use cases. It supports compliance with internal control programs by documenting which external systems Copilot can reach, who approved that reach, and whether ongoing monitoring is catching new or unapproved extensibility paths.

The **Copilot Control System** is a framework whose controls span the Microsoft 365 admin center, Power Platform admin center, and Copilot Studio for managing Copilot connectors, plugins, and **declarative agents** — a newer extensibility path that allows organizations to define custom Copilot behaviors using Copilot's own orchestrator and models, buildable with low-code or pro-code tooling. This solution documents governance patterns that help meet oversight expectations for all three extensibility categories.

For Control 2.16, the governance surfaces are complementary rather than interchangeable:

- **Agents > Settings > Allowed agent types** provides tenant-wide publisher-category controls that also affect agents and apps in those categories.
- **Copilot connectors > Your connections** provides connector-specific allowed-user scope, including **No users**, and staged rollout where available.
- Federated and self-serve connector access uses the user's identity and remains bounded by authentication, consent, and source-system permissions.
- **Agents > Tools** separately governs tool and MCP server inventory, availability, blocking, and requests.

## Features

| Feature | What it does | Primary evidence output |
|---------|--------------|-------------------------|
| Connector inventory | Documents the structure for enumerating Power Platform connectors, Microsoft-built plugins, Copilot connector dependencies, and custom extensibility records in scope for Copilot scenarios. Live enumeration requires customer Power Automate flows. | `connector-inventory` |
| Risk classification | Assigns low, medium, high, or blocked treatment based on publisher type, certification, external data egress, and financial system access. | `connector-inventory` |
| Approval workflow | Routes connector or plugin requests through security review and CISO or DLP review before production enablement. | `approval-register` |
| Data flow attestation | Records approved source and destination boundaries for extensibility scenarios that move data outside Microsoft 365. | `data-flow-attestations` |
| Ongoing monitoring | Detects new connectors, stale approvals, and overdue review actions for operational follow-up. | `approval-register`, `connector-inventory` |
| Control 2.16 reconciliation | Documents the manual comparison of tenant-wide category settings, connector-specific user scope, controlled access tests, and the separate MCP Tools registry. | Tenant portal captures and controlled test records; not emitted by the sample scripts |

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not enumerate connectors from live Power Platform environments (inventory uses configuration-defined connector lists)
- ❌ Does not model the Microsoft Graph connectors API (`/external/connections`) path for Copilot connector enumeration (only the Power Platform Admin API surface is documented)
- ❌ Does not block or approve connectors automatically (approval workflows are documented, not deployed)
- ❌ Does not deploy Power Automate flows (governance workflows are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)
- ❌ Does not prove the tenant's **Allowed agent types** settings, connector-specific allowed-user scope, staged rollout, user authentication, source-system permissions, or effective end-user access
- ❌ Does not manage, approve, block, or validate MCP servers in **Agents > Tools**
- ❌ Does not cover Agent 365 platform governance, Entra Agent ID security controls, or agent pinning (v1.3+ framework features pending solution update)
- ❌ Does not govern third-party model provider integrations

> **Data classification:** See [Data Classification Matrix](../../docs/reference/data-classification.md) for residency, retention, and data-class metadata.

## Architecture

```text
+--------------------------+      +--------------------------+      +--------------------------+
| Power Platform Admin API | ---> | CPG-ConnectorInventory   | ---> | Risk classification      |
| Agent Registry metadata |      | daily inventory flow     |      | low/medium/high/blocked  |
+--------------------------+      +--------------------------+      +--------------------------+
             |                                                                  |
             v                                                                  v
+--------------------------+      +--------------------------+      +--------------------------+
| 09-feature-management-   | ---> | CPG-ApprovalRouter       | ---> | Dataverse registry       |
| controller dependency    |      | security and CISO review |      | baseline/finding/evidence|
+--------------------------+      +--------------------------+      +--------------------------+
                                                                                  |
                                                                                  v
                                                                  +--------------------------+
                                                                  | Monitor-Compliance.ps1   |
                                                                  | Export-Evidence.ps1      |
                                                                  +--------------------------+
```

## Quick Start

1. Review [Prerequisites](docs/prerequisites.md) and confirm that solution `09-feature-management-controller` is already deployed.
2. Select the governance tier that matches the deployment scope:
   - `baseline` for Microsoft-built connectors with limited external reach
   - `recommended` for risk-based approvals across low, medium, and high risk connectors
   - `regulated` for full approval, retention, and third-party register discipline
3. Review the JSON settings under `.\config\` and confirm blocked connectors, SLAs, and data-flow boundaries. These local tiers do not configure Microsoft 365 admin center settings.
4. Run the deployment script with tenant and environment details:

   ```powershell
   .\scripts\Deploy-Solution.ps1 `
     -ConfigurationTier recommended `
     -TenantId <tenant-guid> `
     -Environment <power-platform-environment-id> `
     -DataverseUrl https://contoso.crm.dynamics.com `
     -ApproverEmail cpg-reviewers@contoso.com `
     -OutputPath .\artifacts
   ```

5. Review the generated connector inventory and approval register, then run monitoring and evidence export:

   ```powershell
   .\scripts\Monitor-Compliance.ps1 -ConfigurationTier recommended -AlertOnNewConnectors -OutputPath .\artifacts
   .\scripts\Export-Evidence.ps1 -ConfigurationTier recommended -OutputPath .\artifacts
   ```

6. Separately reconcile the generated inventory with saved tenant evidence from **Allowed agent types**, **Copilot connectors > Your connections**, and **Agents > Tools**. Use controlled approved-user and unapproved-user tests to validate effective access and source-system permission trimming.

## Solution Components

| Path | Purpose |
|------|---------|
| `scripts\Deploy-Solution.ps1` | Discovers connectors, classifies risk, seeds approval requests, and generates the initial deployment manifest. |
| `scripts\Monitor-Compliance.ps1` | Compares current inventory to the approved baseline, checks review SLA adherence, and highlights new or overdue approvals. |
| `scripts\Export-Evidence.ps1` | Packages evidence outputs and control statuses using the shared evidence export contract. |
| `config\default-config.json` | Shared connector risk categories, default SLAs, blocked connector list, Dataverse table names, and monitoring defaults. |
| `config\baseline.json` | Baseline governance settings, including Microsoft-built auto-approval and a 72 hour third-party review SLA. |
| `config\recommended.json` | Recommended governance settings with risk-based auto-approval and faster review expectations for medium risk integrations. |
| `config\regulated.json` | Regulated governance settings with approval for all connectors, mandatory CISO sign-off for high risk, and 365 day evidence retention. |
| `docs\architecture.md` | Documentation-first design for the Power Automate flows, Dataverse tables, and dependency integration points. |
| `docs\deployment-guide.md` | Step-by-step deployment guidance, including Dataverse import, approval routing, and initial inventory execution. |
| `tests\10-connector-plugin-governance.Tests.ps1` | Pester tests for required files, config structure, comment-based help, and PowerShell syntax validation. |

## Deployment

Deployment follows a documentation-first pattern for Power Automate and Dataverse assets. Document and review the flow design and Dataverse schema before promoting connectors into production approval routing, then use the PowerShell scripts to generate manifests, seed review records, and validate monitoring output.

Key deployment stages:

1. Import the Dataverse solution and create the `fsi_cg_cpg_baseline`, `fsi_cg_cpg_finding`, and `fsi_cg_cpg_evidence` tables.
2. Configure the `CPG-ConnectorInventory`, `CPG-ApprovalRouter`, and `CPG-DataFlowAudit` Power Automate flows with the target environment and reviewer account.
3. Run `Deploy-Solution.ps1` to generate the initial inventory, approval register, and data-flow attestation seeds.
4. Capture the tenant-wide **Allowed agent types** posture, then record each connector's allowed-user scope and staged rollout under **Copilot connectors > Your connections**.
5. Record the separate **Agents > Tools** posture for MCP servers.
6. Use solution `09-feature-management-controller` to document rollout coordination until connectors and plugins reach the approved state for the target ring.

## Prerequisites

- Solution `09-feature-management-controller` deployed in the same governance program.
- Power Platform Administrator access for connector enumeration and DLP verification.
- AI Administrator role preferred for Microsoft 365 admin center agent and plugin governance; Global Administrator is reserved for tasks that explicitly require it.
- Dataverse System Administrator access for solution import and table administration.
- Power Automate Premium licensing for approval workflows and scheduled inventory runs.
- A security reviewer mailbox or distribution group to receive approval workflow tasks.

## Related Controls

> **Coverage state** (per [Control Coverage Honesty](../../docs/reference/control-coverage-honesty.md)):
> 4 control(s) are **evidence-export-ready** in scaffold form: 1.13, 2.13, 2.14, 4.13.
> 1 control(s) is/are **documentation-only** (listed in metadata but not yet exercised by scripts/tests in this scaffold): 2.16.

| Control | Why it matters | Solution response |
|---------|----------------|------------------|
| 1.13 | Third-party connectors and plugins extend the Copilot operating boundary and require formal risk review. | Maintains inventory and classification records, then flags where manual third-party due diligence is still required. |
| 2.13 | Data flow boundaries must be documented before Copilot can reach external systems through extensibility. | Captures approved data-flow boundaries and records attestation evidence for cross-boundary use cases. |
| 2.14 | Extensibility requests need a repeatable approval path before tenant deployment. | Routes requests through security review, CISO or DLP decision points, and approval or denial registration. |
| 2.16 | Federated connector and MCP governance requires distinct tenant-wide, connector-specific, identity, source-permission, and MCP control evidence. | Documents manual reconciliation of **Allowed agent types**, connector-specific allowed-user scope (including **No users**) and staged rollout, controlled access tests, user-scoped authentication and source-system permissions, and the separate **Agents > Tools** MCP control plane. Live validation remains outside this scaffold. |
| 4.13 | Operational monitoring must detect drift, new connectors, and stale approvals after deployment. | Compares live inventory to the approved baseline and raises monitoring findings for new or overdue items. |

## Regulatory Alignment

| Regulation | Governance relevance | How this solution supports compliance with the requirement |
|------------|----------------------|------------------------------------------------------------|
| FINRA 3110 | Supervisory controls should cover technology-driven workflows and the external services they invoke. | Provides evidence that connector and plugin use is inventoried, approved, and monitored within a supervisory workflow. |
| OCC 2011-12 | Third-party relationships require risk assessment, ongoing monitoring, and governance escalation. | Classifies connector risk, records review decisions, and highlights unresolved approvals that need operational follow-up. |
| DORA | ICT third-party dependencies and critical data flows must be documented and governed. | Records cross-boundary data-flow attestations and highlights where the DORA third-party register still needs manual reconciliation. |

## Evidence Export

`Export-Evidence.ps1` packages connector governance artifacts into the shared JSON and SHA-256 evidence format. The expected outputs are:

| Evidence output | Description |
|-----------------|-------------|
| `connector-inventory` | Current inventory with connector ID, publisher, risk level, approval state, and data-flow boundaries. |
| `approval-register` | Review tasks and decisions for requested or denied connectors and plugins. |
| `data-flow-attestations` | Recorded boundary decisions for approved extensibility paths that reach external systems. |

The generated artifacts are supplemental inventory and workflow evidence. They do not prove current tenant-wide category settings, connector-specific assignments, staged rollout, successful or denied authentication, source-system permission trimming, or MCP server availability. Control 2.16 review therefore also requires manually captured portal settings and controlled access-test records described in [Evidence Export](docs/evidence-export.md).

## Known Limitations

- Copilot Studio tools/actions and declarative agents can require separate tenant and Teams app policy configuration outside this solution package.
- Microsoft 365 admin center Agent Registry and agent details metadata, AppSource metadata, and Microsoft Graph Agent Registry APIs (preview) can require manual reconciliation for custom plugin publishers.
- Tenant-wide **Allowed agent types** settings have a broader effect than connector-specific access settings; the scaffold does not infer one from the other.
- Administrative inventory visibility is not proof that a connector is available to users or that source-system permissions are enforced for a specific user.
- Risk classification supports compliance with governance objectives, but exceptional business context still requires human review before approval.

## Microsoft Primary References

- [Agent settings in Microsoft 365 admin center](https://learn.microsoft.com/microsoft-365/admin/manage/agent-settings?view=o365-worldwide#allowed-agent-types)
- [Manage federated connector availability](https://learn.microsoft.com/microsoft-365/copilot/connectors/manage-federated-connectors)
- [Manage self-serve sync connector availability](https://learn.microsoft.com/microsoft-365/copilot/connectors/manage-personal-sync-connectors)
- [Copilot connectors overview](https://learn.microsoft.com/microsoft-365/copilot/connectors/overview)
- [Manage tools for agents in Microsoft 365 admin center](https://learn.microsoft.com/microsoft-365/admin/manage/manage-tools-for-agent?view=o365-worldwide)
