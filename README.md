# FSI-CopilotGov-Solutions

Governance solution scaffolds and documentation patterns for the [FSI-CopilotGov](https://github.com/judeper/FSI-CopilotGov) framework.

This repository translates the framework's 54 controls and 216 playbooks into solution scaffolds, reusable modules, policy templates, and evidence-export patterns for Microsoft 365 Copilot governance in financial services.

## What This Repository Contains

- A shared contract layer for governance tiers, solution naming, evidence export, and dashboard integration
- Root deployment utilities, documentation-build automation, and validation workflows
- Fifteen solution folders aligned to the solution backlog identified in the planning report
- Machine-readable mappings that connect solutions back to FSI-CopilotGov controls, playbooks, and regulations

## Solution Catalog

| ID | Solution | Priority | Track | Controls |
|----|----------|----------|-------|----------|
| 01 | [Copilot Readiness Assessment Scanner](./solutions/01-copilot-readiness-scanner/README.md) | P0 | A | 1.1, 1.5, 1.6, 1.7, 1.9 |
| 02 | [Oversharing Risk Assessment and Remediation](./solutions/02-oversharing-risk-assessment/README.md) | P0 | A | 1.2, 1.3, 1.4, 1.6, 2.5, 2.12 |
| 03 | [Sensitivity Label Coverage Auditor](./solutions/03-sensitivity-label-auditor/README.md) | P1 | A | 1.5, 2.2, 3.11, 3.12 |
| 04 | [FINRA Supervision Workflow for Copilot](./solutions/04-finra-supervision-workflow/README.md) | P0 | B | 3.4, 3.5, 3.6 |
| 05 | [DLP Policy Governance for Copilot](./solutions/05-dlp-policy-governance/README.md) | P1 | B | 2.1, 3.10, 3.12 |
| 06 | [Copilot Interaction Audit Trail Manager](./solutions/06-audit-trail-manager/README.md) | P0 | B | 3.1, 3.2, 3.3, 3.11, 3.12 |
| 07 | [Conditional Access Policy Automation for Copilot](./solutions/07-conditional-access-automation/README.md) | P1 | B | 2.3, 2.6, 2.9 |
| 08 | [License Governance and ROI Tracker](./solutions/08-license-governance-roi/README.md) | P1 | C | 1.9, 4.5, 4.6, 4.8 |
| 09 | [Copilot Feature Management Controller](./solutions/09-feature-management-controller/README.md) | P1 | C | 2.6, 4.1, 4.2, 4.3, 4.4, 4.12, 4.13 |
| 10 | [Copilot Connector and Plugin Governance](./solutions/10-connector-plugin-governance/README.md) | P1 | C | 1.13, 2.13, 2.14, 4.13 |
| 11 | [Risk-Tiered Rollout Automation](./solutions/11-risk-tiered-rollout/README.md) | P0 | C | 1.9, 1.11, 1.12, 4.12 |
| 12 | [Regulatory Compliance Dashboard](./solutions/12-regulatory-compliance-dashboard/README.md) | P0 | C | 3.7, 3.8, 3.12, 3.13, 4.5, 4.7 |
| 13 | [DORA Operational Resilience Monitor](./solutions/13-dora-resilience-monitor/README.md) | P1 | D | 2.7, 4.9, 4.10, 4.11 |
| 14 | [Communication Compliance Configurator](./solutions/14-communication-compliance-config/README.md) | P1 | D | 2.10, 3.4, 3.5, 3.6, 3.9 |
| 15 | [Copilot Pages and Notebooks Compliance Gap Monitor](./solutions/15-pages-notebooks-gap-monitor/README.md) | P2 | D | 2.11, 3.2, 3.3, 3.11 |

## Implementation Depth

> ⚠️ This is a **documentation-first** repository. All solutions provide governance scaffolds, templates,
> and scripts using representative sample data. No solution connects to live Microsoft 365 services
> in its repository form. See [Disclaimer](./docs/disclaimer.md) and
> [Documentation vs Runnable Assets Guide](./docs/documentation-vs-runnable-assets-guide.md).

| ID | Solution | Scripts | Live API Calls | Data Source | Tenant Binding Required |
|----|----------|---------|---------------|-------------|------------------------|
| 01 | Copilot Readiness Scanner | ✅ | ❌ | Representative sample scores | Graph, Purview |
| 02 | Oversharing Risk Assessment | ✅ | ❌ | Representative sample data | Graph, SharePoint |
| 03 | Sensitivity Label Auditor | ✅ | ❌ | Representative sample data | Purview |
| 04 | FINRA Supervision Workflow | ✅ | ❌ | Representative sample data | Purview Communication Compliance |
| 05 | DLP Policy Governance | ✅ | ❌ | Local config baseline comparison | Purview DLP |
| 06 | Audit Trail Manager | ✅ | ❌ | Tier configuration validation | UAL, Purview, eDiscovery |
| 07 | Conditional Access Automation | ✅ | ❌ | Generated policy templates | Entra ID, Graph |
| 08 | License Governance ROI | ✅ | ❌ | Representative sample usage data | Graph, Viva Insights |
| 09 | Feature Management Controller | ✅ | ❌ | Tier-defined feature templates | M365 Admin, Graph, Teams Admin |
| 10 | Connector Plugin Governance | ✅ | ❌ | Config-defined connector lists | Power Platform Admin |
| 11 | Risk-Tiered Rollout | ✅ | ❌ | Wave manifest generation | Graph (license assignment) |
| 12 | Regulatory Compliance Dashboard | ✅ | ❌ | Seeded reference data | Dataverse, Power BI |
| 13 | DORA Resilience Monitor | ✅ | ❌ | Local stub sample data | Graph (service health), Sentinel |
| 14 | Communication Compliance Config | ✅ | ❌ | Policy template generation | Purview Communication Compliance |
| 15 | Pages Notebooks Gap Monitor | ✅ | ❌ | Representative sample data | Audit, eDiscovery |

## Connectivity Readiness

This table summarizes which Microsoft 365 and Azure services each solution requires for production use.

| ID | Graph API | Dataverse | Power BI | Power Automate | Purview | Entra ID | Other |
|----|-----------|-----------|----------|----------------|---------|----------|-------|
| 01 | ✅ | ✅ | ✅ | ✅ | ✅ | — | SharePoint |
| 02 | ✅ | ✅ | ✅ | ✅ | — | — | SharePoint |
| 03 | — | ✅ | ✅ | ✅ | ✅ | — | — |
| 04 | — | ✅ | — | ✅ | ✅ | — | — |
| 05 | — | ✅ | ✅ | ✅ | ✅ | — | Exchange |
| 06 | — | ✅ | ✅ | ✅ | ✅ | — | eDiscovery |
| 07 | ✅ | ✅ | ✅ | ✅ | — | ✅ | — |
| 08 | ✅ | ✅ | ✅ | ✅ | — | — | Viva Insights |
| 09 | ✅ | ✅ | ✅ | ✅ | — | — | Teams Admin |
| 10 | — | ✅ | ✅ | ✅ | — | — | Power Platform |
| 11 | ✅ | ✅ | — | ✅ | — | — | — |
| 12 | — | ✅ | ✅ | ✅ | — | — | — |
| 13 | ✅ | ✅ | ✅ | ✅ | — | — | Sentinel |
| 14 | — | ✅ | ✅ | ✅ | ✅ | — | — |
| 15 | — | ✅ | ✅ | ✅ | ✅ | — | eDiscovery |

## Delivery Model

1. **Preflight contract gate** — freeze templates, shared contracts, mappings, and validation rules.
2. **Repository foundation** — bootstrap docs, site generation, workflows, and reusable modules.
3. **Full solution scaffold** — create all 15 solution folders with consistent placeholders and delivery checklists.
4. **Fleet execution** — implement track-specific logic only after the shared contracts are stable.
5. **Integration and publication** — aggregate evidence, validate docs, and publish the site.

## Working Agreement

- Solutions provide documentation, scripts, templates, and evidence packaging guidance.
- Exported Power Automate runtime artifacts are intentionally excluded; the repository documents how to build flows and apps safely in each tenant.
- Documentation should use precise FSI language such as "supports compliance with" or "helps meet" rather than absolute claims.

## Operator Handoff

- Start with [Common Prerequisites](./docs/getting-started/prerequisites.md) and [Identity and Secrets Prep](./docs/getting-started/identity-and-secrets-prep.md).
- Use [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) for wave sequencing, [Operational Handbook](./docs/operational-handbook.md) for ownership and support expectations, and [Documentation vs Runnable Assets Guide](./docs/documentation-vs-runnable-assets-guide.md) to keep the documentation-first boundary clear.
- Run `pwsh -File scripts\deployment\Validate-Prerequisites.ps1` and capture the result in `DELIVERY-CHECKLIST-TEMPLATE.md` before customer handoff or production execution.

## Local Validation

```powershell
python scripts/build-docs.py
python scripts/validate-contracts.py
python scripts/validate-solutions.py
python scripts/validate-documentation.py
```

## License

This project is licensed under the MIT License.
