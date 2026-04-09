# Agent Lifecycle and Deployment Governance

> **Status:** Documentation-first scaffold | **Version:** v0.1.0 | **Priority:** P0 | **Track:** C
>
> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](../../docs/documentation-vs-runnable-assets-guide.md).

## Overview

Agent Lifecycle and Deployment Governance extends Copilot supervision into the agent request, approval, sharing, and deployment layer introduced by the Microsoft 365 Admin Center agent management controls and Copilot Studio admin settings. In a financial services environment, Copilot agents — whether Microsoft-published, IT-developed, or user-created in Copilot Studio — can introduce supervisory, data-handling, and third-party risk obligations that sit within FINRA 3110 supervisory scope, OCC 2011-12 third-party risk management expectations, SEC recordkeeping requirements, and DORA ICT third-party risk oversight.

This solution provides a framework for inventorying agents, applying risk classification, routing approval requests, auditing org-wide sharing restrictions, and recording deployment gating decisions for approved agent use cases. It supports compliance with internal control programs by documenting which agents are available in the tenant, who approved their deployment, whether sharing policies restrict org-wide distribution, and whether ongoing monitoring is detecting new or unapproved agent activity.

## Features

| Capability | What ALG does | Compliance value |
|------------|---------------|------------------|
| Agent registry | Documents the structure for cataloging Microsoft-published agents, IT-developed agents, and user-created Copilot Studio agents with risk classification metadata. | `agent-registry` |
| Request/approval workflows | Provides a framework for routing agent deployment requests through security review, business owner attestation, and CISO sign-off before production enablement in the M365 Admin Center. | `approval-register` |
| Sharing policy governance | Documents the pattern for auditing org-wide sharing restrictions for Copilot Studio agents, verifying that admin controls restrict unapproved agent distribution. | `sharing-policy-audit` |
| Deployment gating | Records deployment gate decisions that tie approved agents to rollout ring controls maintained by solution 09. | `approval-register` |
| Agent catalog monitoring | Detects new agents, stale approvals, sharing policy drift, and overdue review actions for operational follow-up. | `agent-registry`, `approval-register` |

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not enumerate agents from live M365 Admin Center or Copilot Studio environments (inventory uses configuration-defined agent lists)
- ❌ Does not approve or block agents automatically (approval workflows are documented, not deployed)
- ❌ Does not deploy Power Automate flows (governance workflows are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)
- ❌ Does not enforce sharing restrictions in Copilot Studio (sharing policy controls are audited, not applied)
- ❌ Does not replace M365 Admin Center agent management UI (complements admin workflows with governance records)

## Architecture

```text
+--------------------------+      +--------------------------+      +--------------------------+
| M365 Admin Center        | ---> | ALG-AgentRegistry        | ---> | Risk classification      |
| Agent request/approval   |      | agent inventory flow     |      | published/IT/user/blocked|
| Copilot Studio admin     |      |                          |      |                          |
+--------------------------+      +--------------------------+      +--------------------------+
             |                                                                  |
             v                                                                  v
+--------------------------+      +--------------------------+      +--------------------------+
| 09-feature-management-   | ---> | ALG-ApprovalRouter       | ---> | Dataverse registry       |
| controller dependency    |      | security and CISO review |      | baseline/finding/evidence|
| 10-connector-plugin-     |      |                          |      |                          |
| governance dependency    |      +--------------------------+      +--------------------------+
+--------------------------+                                                    |
                                                                                v
                                  +--------------------------+      +--------------------------+
                                  | ALG-SharingPolicyAudit   | ---> | Monitor-Compliance.ps1   |
                                  | org-wide sharing check   |      | Export-Evidence.ps1      |
                                  +--------------------------+      +--------------------------+
```

## Quick Start

1. Review [Prerequisites](docs/prerequisites.md) and confirm that solutions `09-feature-management-controller` and `10-connector-plugin-governance` are already deployed.
2. Select the governance tier that matches the deployment scope:
   - `baseline` for Microsoft-published agent auto-approval with standard sharing controls
   - `recommended` for risk-based approvals across published, IT-developed, and user-created agents
   - `regulated` for full approval, mandatory CISO sign-off for user-created agents, and strict sharing restrictions
3. Review the JSON settings under `.\config\` and confirm agent risk categories, approval SLAs, and sharing policy controls.
4. Run the deployment script with tenant and environment details:

   ```powershell
   .\scripts\Deploy-Solution.ps1 `
     -ConfigurationTier recommended `
     -TenantId <tenant-guid> `
     -DataverseUrl https://contoso.crm.dynamics.com `
     -ApproverEmail alg-reviewers@contoso.com `
     -OutputPath .\artifacts
   ```

5. Review the generated agent registry and approval register, then run monitoring and evidence export:

   ```powershell
   .\scripts\Monitor-Compliance.ps1 -ConfigurationTier recommended -AlertOnNewAgents -OutputPath .\artifacts
   .\scripts\Export-Evidence.ps1 -ConfigurationTier recommended -OutputPath .\artifacts
   ```

6. Validate evidence outputs and integrate with solution 09 rollout controls before production enablement.

## Solution Components

| Path | Purpose |
|------|---------|
| `scripts\Deploy-Solution.ps1` | Catalogs agents, classifies risk, seeds approval requests, audits sharing policies, and generates the initial deployment manifest. |
| `scripts\Monitor-Compliance.ps1` | Compares current agent inventory to the approved baseline, checks sharing policy compliance, verifies review SLA adherence, and highlights new or overdue approvals. |
| `scripts\Export-Evidence.ps1` | Packages evidence outputs and control statuses using the shared evidence export contract. |
| `config\default-config.json` | Shared agent risk categories, default SLAs, sharing policy controls, Dataverse table names, and monitoring defaults. |
| `config\baseline.json` | Baseline governance settings, including Microsoft-published auto-approval and standard sharing controls. |
| `config\recommended.json` | Recommended governance settings with risk-based approval and moderate sharing restrictions. |
| `config\regulated.json` | Regulated governance settings with approval for all agents, mandatory CISO sign-off for user-created agents, and strict sharing restrictions. |
| `docs\architecture.md` | Documentation-first design for the Power Automate flows, Dataverse tables, and dependency integration points. |
| `docs\deployment-guide.md` | Step-by-step deployment guidance, including Dataverse import, approval routing, and initial inventory execution. |
| `docs\evidence-export.md` | Evidence output schema, export process, and audit usage for agent-registry, approval-register, and sharing-policy-audit. |
| `docs\prerequisites.md` | Licensing, roles, modules, and dependent solution prerequisites. |
| `docs\troubleshooting.md` | Common issues and resolutions organized by symptom. |
| `tests\19-agent-lifecycle-governance.Tests.ps1` | Pester tests for required files, config structure, comment-based help, and PowerShell syntax validation. |

## Deployment

Deployment follows a documentation-first pattern for Power Automate and Dataverse assets. Document and review the flow design and Dataverse schema before promoting agents into production approval routing, then use the PowerShell scripts to generate manifests, seed review records, and validate monitoring output.

Key deployment stages:

1. Import the Dataverse solution and create the `fsi_cg_alg_baseline`, `fsi_cg_alg_finding`, and `fsi_cg_alg_evidence` tables.
2. Configure the `ALG-AgentRegistry`, `ALG-ApprovalRouter`, and `ALG-SharingPolicyAudit` Power Automate flows with the target environment and reviewer account.
3. Run `Deploy-Solution.ps1` to generate the initial agent inventory, approval register, and sharing policy audit records.
4. Use solution `09-feature-management-controller` to gate production rollout until agents reach the approved state for the target ring.

See [Deployment Guide](docs/deployment-guide.md) for detailed step-by-step instructions.

## Prerequisites

- Solution `09-feature-management-controller` deployed in the same governance program.
- Solution `10-connector-plugin-governance` deployed for coordinated extensibility governance.
- Microsoft 365 Global Admin or Teams Admin access for agent management and sharing policy review.
- Copilot Studio Environment Admin access for agent catalog and sharing restriction configuration.
- Dataverse System Administrator access for solution import and table administration.
- Power Automate Premium licensing for approval workflows and scheduled agent inventory runs.
- A security reviewer mailbox or distribution group to receive approval workflow tasks.

See [Prerequisites](docs/prerequisites.md) for complete details.

## Related Controls

| Control | Title | How ALG supports compliance |
|---------|-------|-----------------------------|
| 1.13 | Third-party and custom agents extend the Copilot operating boundary and require formal risk review. | Maintains an agent inventory with risk classification records and flags where manual due diligence is still required for user-created or third-party agents. |
| 2.13 | Agent deployment boundaries must be documented before agents can operate in production Copilot scenarios. | Documents approved agent deployment scope and records sharing policy audit evidence for org-wide distribution controls. |
| 2.14 | Agent deployment requests need a repeatable approval path before tenant enablement. | Routes requests through security review, business owner attestation, and CISO or DLP decision points before recording approval or denial. |
| 4.1 | Feature management controls should govern which agents are available in each rollout ring. | Integrates with solution 09 to gate agent availability by rollout ring and prevent unapproved agents from reaching production users. |
| 4.13 | Operational monitoring must detect drift, new agents, sharing policy changes, and stale approvals after deployment. | Compares the current agent inventory to the approved baseline, audits sharing policy settings, and raises monitoring findings for new or overdue items. |

## Regulatory Alignment

| Regulation | Governance relevance | How this solution supports compliance with the requirement |
|------------|----------------------|------------------------------------------------------------|
| FINRA 3110 | Supervisory controls should cover technology-driven workflows and the AI agents that execute them. | Provides evidence that agent deployment is inventoried, approved, and monitored within a supervisory workflow. |
| SEC 17a-4 / 204-2 | Recordkeeping requirements extend to AI agent interactions and approvals in supervised environments. | Records agent approval decisions, sharing policy audits, and deployment gating evidence for supervisory review. |
| GLBA 501(b) | Safeguards rule requires controls over systems that access customer financial information, including AI agents. | Documents agent risk classification and deployment boundaries to support safeguards program documentation. |
| OCC 2011-12 | Third-party relationships and technology dependencies require risk assessment, ongoing monitoring, and governance escalation. | Classifies agent risk, records review decisions, and highlights unresolved approvals that need operational follow-up. |
| SOX 302/404 | Internal controls over financial reporting should account for AI agent access to financial data. | Provides agent registry and approval evidence that supports internal control documentation and testing. |
| DORA | ICT third-party dependencies and critical agent deployments must be documented and governed. | Records agent deployment decisions and highlights where the DORA ICT third-party register still needs manual reconciliation for agent dependencies. |
| FFIEC IT Handbook | IT governance expectations include inventory and risk management for AI-driven automation tools. | Documents agent lifecycle governance patterns that support FFIEC examination readiness. |

## Evidence Export

`Export-Evidence.ps1` packages agent governance artifacts into the shared JSON and SHA-256 evidence format. The expected outputs are:

| Evidence output | Description |
|-----------------|-------------|
| `agent-registry` | Current agent inventory with agent ID, publisher type, risk level, approval state, sharing policy status, and deployment scope. |
| `approval-register` | Review tasks and decisions for requested, approved, or denied agent deployments. |
| `sharing-policy-audit` | Sharing policy configuration records documenting org-wide sharing restrictions, external sharing settings, and catalog visibility controls. |

## Known Limitations

- Copilot Studio agent sharing restrictions require manual configuration in the Copilot Studio admin center; this solution audits but does not enforce those settings.
- M365 Admin Center agent request and approval workflows may evolve as Microsoft ships additional admin controls; governance patterns documented here should be reviewed against current admin center capabilities.
- User-created Copilot Studio agents may not appear in centralized inventory until admin center agent management features are enabled for the tenant.
- Risk classification supports compliance with governance objectives, but exceptional business context still requires human review before approval.
- Agent lifecycle governance complements but does not replace connector and plugin governance maintained by solution 10.
