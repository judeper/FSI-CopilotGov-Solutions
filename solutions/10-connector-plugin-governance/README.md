# Copilot Connector and Plugin Governance

> **Status:** Documentation-first scaffold | **Version:** v0.1.0 | **Priority:** P1 | **Track:** C
>
> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](../../docs/documentation-vs-runnable-assets-guide.md).

## Overview

Copilot Connector and Plugin Governance extends Copilot supervision into the connector, plugin, and extensibility layer used by Microsoft 365 Copilot, Copilot Studio, Copilot connectors (formerly Graph connectors), and Power Platform based agent scenarios. In a financial services environment, those extensibility paths can introduce third-party risk, data egress risk, and approval obligations that sit within FINRA 3110 supervisory scope, OCC 2011-12 third-party risk management expectations, and DORA ICT third-party risk oversight.

This solution inventories connectors and plugins, applies risk classification, routes approval requests, and records data-flow boundary decisions for approved use cases. It supports compliance with internal control programs by documenting which external systems Copilot can reach, who approved that reach, and whether ongoing monitoring is catching new or unapproved extensibility paths.

The **Copilot Control System** in the Microsoft 365 admin center serves as the centralized admin surface for managing Copilot connectors, plugins, and **declarative agents** — a newer extensibility path that allows organizations to define custom Copilot behaviors through configuration rather than code. This solution documents governance patterns that help meet oversight expectations for all three extensibility categories.

## Features

| Feature | What it does | Primary evidence output |
|---------|--------------|-------------------------|
| Connector inventory | Documents the structure for enumerating Power Platform connectors, Microsoft-built plugins, Copilot connector dependencies, and custom extensibility records in scope for Copilot scenarios. Live enumeration requires customer Power Automate flows. | `connector-inventory` |
| Risk classification | Assigns low, medium, high, or blocked treatment based on publisher type, certification, external data egress, and financial system access. | `connector-inventory` |
| Approval workflow | Routes connector or plugin requests through security review and CISO or DLP review before production enablement. | `approval-register` |
| Data flow attestation | Records approved source and destination boundaries for extensibility scenarios that move data outside Microsoft 365. | `data-flow-attestations` |
| Ongoing monitoring | Detects new connectors, stale approvals, and overdue review actions for operational follow-up. | `approval-register`, `connector-inventory` |

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not enumerate connectors from live Power Platform environments (inventory uses configuration-defined connector lists)
- ❌ Does not block or approve connectors automatically (approval workflows are documented, not deployed)
- ❌ Does not deploy Power Automate flows (governance workflows are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)
- ❌ Does not cover Agent 365 platform governance, Entra Agent ID security controls, or agent pinning (v1.3+ framework features pending solution update)
- ❌ Does not govern third-party model provider integrations

## Architecture

```text
+--------------------------+      +--------------------------+      +--------------------------+
| Power Platform Admin API | ---> | CPG-ConnectorInventory   | ---> | Risk classification      |
| Microsoft Graph inventory|      | daily inventory flow     |      | low/medium/high/blocked  |
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
4. Use solution `09-feature-management-controller` to gate production rollout until connectors and plugins reach the approved state for the target ring.

## Prerequisites

- Solution `09-feature-management-controller` deployed in the same governance program.
- Power Platform Administrator access for connector enumeration and DLP verification.
- Microsoft 365 Global Admin access for Teams app policy and plugin deployment review.
- Dataverse System Administrator access for solution import and table administration.
- Power Automate Premium licensing for approval workflows and scheduled inventory runs.
- A security reviewer mailbox or distribution group to receive approval workflow tasks.

## Related Controls

| Control | Why it matters | Solution response |
|---------|----------------|------------------|
| 1.13 | Third-party connectors and plugins extend the Copilot operating boundary and require formal risk review. | Maintains inventory and classification records, then flags where manual third-party due diligence is still required. |
| 2.13 | Data flow boundaries must be documented before Copilot can reach external systems through extensibility. | Captures approved data-flow boundaries and records attestation evidence for cross-boundary use cases. |
| 2.14 | Extensibility requests need a repeatable approval path before tenant deployment. | Routes requests through security review, CISO or DLP decision points, and approval or denial registration. |
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

- Copilot Studio plugins and declarative agents can require separate tenant and Teams app policy configuration outside this solution package.
- Microsoft AppSource metadata and Microsoft Graph inventory can require manual reconciliation for custom plugin publishers.
- Risk classification supports compliance with governance objectives, but exceptional business context still requires human review before approval.
