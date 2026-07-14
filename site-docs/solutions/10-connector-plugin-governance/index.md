# Copilot Connector and Plugin Governance

> **Status:** Documentation-first scaffold | **Version:** v0.2.3 | **Priority:** P1 | **Track:** C
>
> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../disclaimer.md) and [Documentation vs Runnable Assets Guide](../../documentation-vs-runnable-assets-guide.md).

## Overview

Copilot Connector and Plugin Governance extends Copilot supervision into the connector, plugin, and extensibility layer used by Microsoft 365 Copilot, Copilot Studio, Copilot connectors (formerly Graph connectors), and Power Platform based agent scenarios. In a financial services environment, those extensibility paths can introduce third-party risk, data egress risk, and approval obligations that sit within FINRA 3110 supervisory scope, OCC 2011-12 third-party risk management expectations, and DORA ICT third-party risk oversight.

This solution documents connector and plugin inventory structures, applies risk classification to representative records, models approval routing, and records sample data-flow boundary decisions for approved use cases. It supports compliance with internal control programs by documenting how teams can review which external systems Copilot may reach, who approved that reach, and whether tenant-bound monitoring identifies new or unapproved extensibility paths.

The **Copilot Control System** is a framework whose controls span the Microsoft 365 admin center, Power Platform admin center, and Copilot Studio for managing Copilot connectors, plugins, and **declarative agents** — a newer extensibility path that allows organizations to define custom Copilot behaviors using Copilot's own orchestrator and models, buildable with low-code or pro-code tooling. This solution documents governance patterns that help meet oversight expectations for all three extensibility categories.

Microsoft 365 Copilot connectors come in two models: **synced connectors**, which index external content into Microsoft Graph, and **federated connectors**, which retrieve content in real time using the Model Context Protocol (MCP) without indexing. Federated connectors are read-only and, as of this review, are in early access preview (Frontier program). This solution documents governance patterns for both models and treats MCP-based extensibility — federated connectors and Copilot Studio MCP servers — as a cross-boundary path that requires documented trust boundaries and Power Platform data loss prevention (DLP) review. Current extensibility terminology refers to **agents** (declarative and custom engine) and **actions** (formerly plugins); this solution retains "plugin" wording for continuity while mapping it to those current categories.

## Features

| Feature | What it does | Primary evidence output |
|---------|--------------|-------------------------|
| Connector inventory | Documents the structure for enumerating Power Platform connectors, Microsoft-built plugins, Copilot connector dependencies (synced and federated), and custom extensibility records in scope for Copilot scenarios. Live enumeration requires customer Power Automate flows. | `connector-inventory` |
| Risk classification | Assigns low, medium, high, or blocked treatment based on publisher type, certification, external data egress, and financial system access. | `connector-inventory` |
| Approval workflow | Routes connector or plugin requests through security review and CISO or DLP review before production enablement. | `approval-register` |
| Data flow attestation | Records approved source and destination boundaries for extensibility scenarios that move data outside Microsoft 365. | `data-flow-attestations` |
| Ongoing monitoring | Detects new connectors, stale approvals, and overdue review actions for operational follow-up. | `approval-register`, `connector-inventory` |

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not enumerate connectors from live Power Platform environments (inventory uses configuration-defined connector lists)
- ❌ Does not model the Microsoft Graph connectors API (`/external/connections`) path for Copilot connector enumeration (only the Power Platform Admin API surface is documented)
- ❌ Does not block or approve connectors automatically (approval workflows are documented, not deployed)
- ❌ Does not deploy Power Automate flows (governance workflows are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)
- ❌ Does not cover Microsoft Agent 365 platform governance, the converged agent registry and control plane, Microsoft Entra Agent ID security controls, or agent pinning (these are owned by Microsoft Agent 365 and Solutions 21 and 23)
- ❌ Does not execute Microsoft Agent 365 Package Management Graph API writes; the documented preview API is limited to read-only, redacted inventory validation in the lab contract
- ❌ Does not perform live validation of federated Copilot connectors or Copilot Studio MCP servers, and does not maintain a universal MCP registry (federated/MCP oversight is documented, not exercised)
- ❌ Does not govern third-party model provider integrations

> **Data classification:** See [Data Classification Matrix](../../reference/data-classification.md) for residency, retention, and data-class metadata.

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

1. Review [Prerequisites](prerequisites.md) and confirm that solution `09-feature-management-controller` is already deployed.
2. Select the governance tier that matches the deployment scope:
   - `baseline` for Microsoft-built connectors with limited external reach
   - `recommended` for risk-based approvals across low, medium, and high risk connectors
   - `regulated` for full approval, retention, and third-party register discipline
3. Review the JSON settings under `.\config\` and confirm blocked connectors, SLAs, and data-flow boundaries.
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

## Solution Components

| Path | Purpose |
|------|---------|
| `scripts\Deploy-Solution.ps1` | Generates representative connector inventory, risk-classification, approval-request, and deployment-manifest records. |
| `scripts\Monitor-Compliance.ps1` | Compares representative inventory to the approved baseline shape, checks sample review SLA adherence, and highlights modeled new or overdue approvals. |
| `scripts\Export-Evidence.ps1` | Packages evidence outputs and control statuses using the shared evidence export contract. |
| `config\default-config.json` | Shared connector risk categories, default SLAs, blocked connector list, Dataverse table names, and monitoring defaults. |
| `config\baseline.json` | Baseline governance settings, including Microsoft-built auto-approval and a 72 hour third-party review SLA. |
| `config\recommended.json` | Recommended governance settings with risk-based auto-approval and faster review expectations for medium risk integrations. |
| `config\regulated.json` | Regulated governance settings with approval for all connectors, mandatory CISO sign-off for high risk, and 365 day evidence retention. |
| `docs\architecture.md` | Documentation-first design for the Power Automate flows, Dataverse tables, and dependency integration points. |
| `docs\deployment-guide.md` | Step-by-step deployment guidance, including Dataverse import, approval routing, and initial inventory execution. |
| `tests\10-connector-plugin-governance.Tests.ps1` | Pester tests for required files, config structure, comment-based help, and PowerShell syntax validation. |
| `lab\10-connector-plugin-governance.lab.json` | Read-only contract for tenant, connector, Agent 365 registry/API, MCP, DLP, and app-registration evidence validation. |

## Deployment

Deployment follows a documentation-first pattern for Power Automate and Dataverse assets. Document and review the flow design and Dataverse schema before promoting connectors into production approval routing, then use the PowerShell scripts to generate manifests, seed review records, and validate monitoring output.

Key deployment stages:

1. Import the Dataverse solution and create the `fsi_cg_cpg_baseline`, `fsi_cg_cpg_finding`, and `fsi_cg_cpg_evidence` tables.
2. Configure the `CPG-ConnectorInventory`, `CPG-ApprovalRouter`, and `CPG-DataFlowAudit` Power Automate flows with the target environment and reviewer account.
3. Run `Deploy-Solution.ps1` to generate the initial inventory, approval register, and data-flow attestation seeds.
4. Use solution `09-feature-management-controller` to gate production rollout until connectors and plugins reach the approved state for the target ring.

## Prerequisites

- Solution `09-feature-management-controller` deployed in the same governance program.
- Power Platform Administrator access for connector enumeration and DLP verification.
- AI Administrator role for Microsoft 365 admin center connector, agent, and plugin governance (managing Microsoft 365 Copilot connectors requires the AI Administrator role); the least-privilege **AI Reader** role is sufficient for read-only agent-registry inventory review. Global Administrator is reserved for tasks that explicitly require it.
- Dataverse System Administrator access for solution import and table administration.
- Power Automate Premium licensing for approval workflows and scheduled inventory runs.
- A security reviewer mailbox or distribution group to receive approval workflow tasks.

## Related Controls

> **Coverage state** (per [Control Coverage Honesty](../../reference/control-coverage-honesty.md)):
> 4 control(s) are **evidence-export-ready** in scaffold form: 1.13, 2.13, 2.14, 4.13.
> 1 control(s) is/are **documentation-only** (listed in metadata but not yet exercised by scripts/tests in this scaffold): 2.16.

| Control | Why it matters | Solution response |
|---------|----------------|------------------|
| 1.13 | Third-party connectors and plugins extend the Copilot operating boundary and require formal risk review. | Maintains inventory and classification records, then flags where manual third-party due diligence is still required. |
| 2.13 | Data flow boundaries must be documented before Copilot can reach external systems through extensibility. | Captures approved data-flow boundaries and records attestation evidence for cross-boundary use cases. |
| 2.14 | Extensibility requests need a repeatable approval path before tenant deployment. | Routes requests through security review, CISO or DLP decision points, and approval or denial registration. |
| 2.16 | Federated connector and MCP governance requires documented trust boundaries before cross-boundary extensibility is enabled. | Documents trust-boundary metadata and manual reconciliation steps for federated (MCP-based, early access preview) Copilot connectors and Copilot Studio MCP servers, which are governed through the Microsoft 365 admin center and Power Platform DLP connector classification; live validation and any universal MCP inventory remain outside this scaffold. |
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

## Known Limitations

- Copilot Studio tools/actions and declarative agents can require separate tenant and Teams app policy configuration outside this solution package.
- Agent and plugin (agent and action) metadata is reviewed through the Microsoft Agent 365 agent registry in the Microsoft 365 admin center (Agents > All agents > Registry, which supports read-only CSV export) and AppSource metadata; this can require manual reconciliation for custom publishers. Deeper agent-identity governance uses Microsoft Entra Agent ID and is out of scope for this solution.
- The Microsoft Agent 365 Package Management API is documented as preview for agent-registry automation. Read-only inventory uses `GET /v1.0/copilot/admin/catalog/packages` with `CopilotPackages.Read.All` and requires a Microsoft Agent 365 license plus AI Administrator or Global Administrator; write operations remain out of scope.
- Risk classification supports compliance with governance objectives, but exceptional business context still requires human review before approval.
