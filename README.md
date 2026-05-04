# FSI-CopilotGov-Solutions

Governance solution scaffolds and documentation patterns for the [FSI-CopilotGov](https://github.com/judeper/FSI-CopilotGov) framework.

This repository translates the framework's 58 controls and 243 playbooks into solution scaffolds, reusable modules, policy templates, and evidence-export patterns for Microsoft 365 Copilot governance in financial services.

## Quickstart

Want to deploy one solution against a non-production tenant? Follow this minimum path:

1. **Pick a tier.** Choose `baseline`, `recommended`, or `regulated` based on your obligations (see [Pick a tier](#pick-a-tier) below and [Tier Applicability](./docs/reference/tier-applicability.md)).
2. **Pick a solution.** Use the [Solution Catalog](#solution-catalog) below; the *Tiers* column shows the recommended tier for each solution.
3. **Read the disclaimer.** This is a documentation-first repository; scripts use representative sample data. See [Disclaimer](./docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](./docs/documentation-vs-runnable-assets-guide.md).
4. **Run preflight.** `pwsh -File scripts\deployment\Validate-Prerequisites.ps1` and resolve any gaps.
5. **Follow the deployment guide.** [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) for the wave plan and tier matrix; the chosen solution's `docs/deployment-guide.md` for solution-specific steps.
6. **Export evidence.** Each solution's `scripts/Export-Evidence.ps1` produces sample JSON for evidence-export-ready controls.

## Pick a tier

| Tier | Use when | Defaults |
|------|----------|----------|
| `baseline` | Pilot, sandbox, or non-regulated department | Minimum controls; no audit-trail dependency |
| `recommended` | Standard production rollout for regulated FSI tenants | Default for P1/P2 solutions |
| `regulated` | Highest assurance — supervised business units, FINRA/SEC/DORA scope | Default for P0 solutions; full audit-trail + retention |

See [Tier Applicability](./docs/reference/tier-applicability.md) for the per-solution matrix and [Control Coverage Honesty](./docs/reference/control-coverage-honesty.md) for what each control mapping actually demonstrates today.

## What This Repository Contains

- A shared contract layer for governance tiers, solution naming, evidence export, and dashboard integration
- Root deployment utilities, documentation-build automation, and validation workflows
- Twenty-three solution folders aligned to the solution backlog identified in the planning report
- Machine-readable mappings that connect solutions back to FSI-CopilotGov controls, playbooks, and regulations

## Solution Catalog

> **Tiers column:** `base` / `rec` / `reg` show which tiers each solution supports. **Bold** marks the recommended default tier. See [Tier Applicability](./docs/reference/tier-applicability.md).

| ID | Solution | Priority | Track | Tiers | Controls |
|----|----------|----------|-------|-------|----------|
| 01 | [Copilot Readiness Assessment Scanner](./solutions/01-copilot-readiness-scanner/README.md) | P0 | A | base / rec / **reg** | 1.1, 1.5, 1.6, 1.7, 1.9 |
| 02 | [Oversharing Risk Assessment and Remediation](./solutions/02-oversharing-risk-assessment/README.md) | P0 | A | base / rec / **reg** | 1.2, 1.3, 1.4, 1.6, 2.5, 2.12 |
| 03 | [Sensitivity Label Coverage Auditor](./solutions/03-sensitivity-label-auditor/README.md) | P1 | A | base / **rec** / reg | 1.5, 2.2, 3.11, 3.12 |
| 04 | [FINRA Supervision Workflow for Copilot](./solutions/04-finra-supervision-workflow/README.md) | P0 | B | base / rec / **reg** | 3.4, 3.5, 3.6 |
| 05 | [DLP Policy Governance for Copilot](./solutions/05-dlp-policy-governance/README.md) | P1 | B | base / **rec** / reg | 2.1, 3.10, 3.12 |
| 06 | [Copilot Interaction Audit Trail Manager](./solutions/06-audit-trail-manager/README.md) | P0 | B | base / rec / **reg** | 3.1, 3.2, 3.3, 3.11, 3.12 |
| 07 | [Conditional Access Policy Automation for Copilot](./solutions/07-conditional-access-automation/README.md) | P1 | B | base / **rec** / reg | 2.3, 2.6, 2.9 |
| 08 | [License Governance and ROI Tracker](./solutions/08-license-governance-roi/README.md) | P1 | C | base / **rec** / reg | 1.9, 4.5, 4.6, 4.8 |
| 09 | [Copilot Feature Management Controller](./solutions/09-feature-management-controller/README.md) | P1 | C | base / **rec** / reg | 2.6, 4.1, 4.2, 4.3, 4.4, 4.12, 4.13 |
| 10 | [Copilot Connector and Plugin Governance](./solutions/10-connector-plugin-governance/README.md) | P1 | C | base / **rec** / reg | 1.13, 2.13, 2.14, 4.13 |
| 11 | [Risk-Tiered Rollout Automation](./solutions/11-risk-tiered-rollout/README.md) | P0 | C | base / rec / **reg** | 1.9, 1.11, 1.12, 4.12 |
| 12 | [Regulatory Compliance Dashboard](./solutions/12-regulatory-compliance-dashboard/README.md) | P0 | C | base / rec / **reg** | 3.7, 3.8, 3.12, 3.13, 4.5, 4.7 |
| 13 | [DORA Operational Resilience Monitor](./solutions/13-dora-resilience-monitor/README.md) | P1 | D | base / **rec** / reg | 2.7, 4.9, 4.10, 4.11 |
| 14 | [Communication Compliance Configurator](./solutions/14-communication-compliance-config/README.md) | P1 | D | base / **rec** / reg | 2.10, 3.4, 3.5, 3.6, 3.9 |
| 15 | [Copilot Pages and Notebooks Compliance Gap Monitor](./solutions/15-pages-notebooks-gap-monitor/README.md) | P2 | D | base / **rec** / reg | 2.11, 3.2, 3.3, 3.11 |
| 16 | [Item-Level Oversharing Scanner](./solutions/16-item-level-oversharing-scanner/README.md) | P1 | A | base / **rec** / reg | 1.2, 1.3, 1.4, 1.6, 2.5 |
| 17 | [SharePoint Permissions Drift Detection](./solutions/17-sharepoint-permissions-drift/README.md) | P1 | A | base / **rec** / reg | 1.2, 1.4, 1.6, 2.5 |
| 18 | [Entra Access Reviews Automation](./solutions/18-entra-access-reviews/README.md) | P1 | A | base / **rec** / reg | 1.2, 1.6, 2.5, 2.12 |
| 19 | [Copilot Tuning Governance (Microsoft 365 Copilot Tuning early access preview; eligible tenants only)](./solutions/19-copilot-tuning-governance/README.md) | P1 | A | base / **rec** / reg | 1.16, 3.8 |
| 20 | [Generative AI Model Governance Monitor](./solutions/20-generative-ai-model-governance-monitor/README.md) | P1 | D | base / **rec** / reg | 3.8a, 3.8, 3.1, 3.11, 3.12 |
| 21 | [Cross-Tenant Agent Federation Auditor](./solutions/21-cross-tenant-agent-federation-auditor/README.md) | P1 | B | base / **rec** / reg | 2.17, 2.16, 1.10, 2.13, 2.14, 4.13 |
| 22 | [Pages and Notebooks Retention Tracker](./solutions/22-pages-notebooks-retention-tracker/README.md) | P1 | D | base / **rec** / reg | 3.14, 3.2, 3.3, 3.11, 2.11 |
| 23 | [Copilot Studio Agent Lifecycle Tracker](./solutions/23-copilot-studio-lifecycle-tracker/README.md) | P1 | C | base / **rec** / reg | 4.14, 4.13, 1.10, 1.16, 4.5, 4.12 |

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
| 16 | Item-Level Oversharing Scanner | ✅ | ❌ | Representative sample data | PnP PowerShell, SharePoint |
| 17 | SharePoint Permissions Drift | ✅ | ❌ | Representative sample data | PnP PowerShell, Graph |
| 18 | Entra Access Reviews Automation | ✅ | ❌ | Representative sample data | Graph, Entra ID |
| 19 | Copilot Tuning Governance (Microsoft 365 Copilot Tuning early access preview; eligible tenants only) | ✅ | ❌ | Representative sample data | Microsoft 365 admin center (eligible tenants with at least 5,000 Microsoft 365 Copilot licenses), Graph |
| 20 | Generative AI Model Governance Monitor | ✅ | ❌ | Representative sample data | Model Risk Committee, Microsoft attestations |
| 21 | Cross-Tenant Agent Federation Auditor | ✅ | ❌ | Representative sample data | Entra Agent ID, Copilot Studio, MCP |
| 22 | Pages and Notebooks Retention Tracker | ✅ | ❌ | Representative sample data | Purview, SharePoint, OneNote, Loop |
| 23 | Copilot Studio Agent Lifecycle Tracker | ✅ | ❌ | Representative sample data | Power Platform Admin, Copilot Studio |

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
| 16 | ✅ | — | — | — | — | — | SharePoint (PnP) |
| 17 | ✅ | — | — | — | — | — | SharePoint (PnP) |
| 18 | ✅ | — | — | — | — | ✅ | SharePoint |
| 19 | ✅ | — | — | — | — | — | Microsoft 365 admin center (early access preview; eligible tenants with at least 5,000 Microsoft 365 Copilot licenses) |
| 20 | — | — | — | — | — | — | Model Risk Committee workflow |
| 21 | ✅ | — | — | — | — | ✅ | Copilot Studio, MCP |
| 22 | — | — | — | — | ✅ | — | SharePoint, OneNote, Loop |
| 23 | — | — | — | — | — | — | Power Platform Admin |

## Delivery Model

1. **Preflight contract gate** — freeze templates, shared contracts, mappings, and validation rules.
2. **Repository foundation** — bootstrap docs, site generation, workflows, and reusable modules.
3. **Full solution scaffold** — create all 23 solution folders with consistent placeholders and delivery checklists.
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
