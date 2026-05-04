# Deployment Guide

> **Status:** v1.0 — promoted from documentation-first scaffold | **Pinned framework:** see [FRAMEWORK-VERSION](./FRAMEWORK-VERSION) | **Tier model:** baseline / recommended / regulated

> ⚠️ **Documentation-first repository.** All 23 solution scaffolds use representative sample data. Tenant binding is the operator's responsibility; nothing in this repository connects to live Microsoft 365 services as shipped. See [Disclaimer](./docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](./docs/documentation-vs-runnable-assets-guide.md).

## What this guide is — and is not

**This guide IS:**
- A wave plan for sequencing deployment of the 23 documentation-first solution scaffolds in a regulated FSI tenant.
- A tier-applicability matrix indicating which of aseline / ecommended / egulated each solution targets.
- A licensing footprint summary you can use when sizing a Copilot governance pilot.
- A concrete pilot path that you can execute end-to-end against a non-production tenant in a controlled change window.

**This guide is NOT:**
- A turnkey installer — every solution requires tenant-specific configuration and tenant binding.
- A substitute for solution-level docs/deployment-guide.md — those contain solution-specific steps.
- A substitute for the FSI-CopilotGov framework's playbooks — those contain control implementation guidance.
- An auditable evidence package — the evidence-export scripts produce sample JSON only until tenant binding is implemented.

## Tier-applicability matrix

The tier column indicates the recommended default tier per solution. P0 solutions default to egulated; P1/P2 solutions default to ecommended. All 23 solutions support all three tiers; tier choice modulates retention, audit-trail dependency, and evidence-export depth.
| ID | Solution | Priority | Recommended tier | Tiers supported | Maturity |
|----|----------|----------|------------------|-----------------|----------|
| 01 | Copilot Readiness Assessment Scanner | P0 | reg | base / rec / reg | documentation-first-scaffold |
| 02 | Oversharing Risk Assessment and Remediation | P0 | reg | base / rec / reg | documentation-first-scaffold |
| 03 | Sensitivity Label Coverage Auditor | P1 | rec | base / rec / reg | documentation-first-scaffold |
| 04 | FINRA Supervision Workflow for Copilot | P0 | reg | base / rec / reg | documentation-first-scaffold |
| 05 | DLP Policy Governance for Copilot | P1 | rec | base / rec / reg | documentation-first-scaffold |
| 06 | Copilot Interaction Audit Trail Manager | P0 | reg | base / rec / reg | documentation-first-scaffold |
| 07 | Conditional Access Policy Automation for Copilot | P1 | rec | base / rec / reg | documentation-first-scaffold |
| 08 | License Governance and ROI Tracker | P1 | rec | base / rec / reg | documentation-first-scaffold |
| 09 | Copilot Feature Management Controller | P1 | rec | base / rec / reg | documentation-first-scaffold |
| 10 | Copilot Connector and Plugin Governance | P1 | rec | base / rec / reg | documentation-first-scaffold |
| 11 | Risk-Tiered Rollout Automation | P0 | reg | base / rec / reg | documentation-first-scaffold |
| 12 | Regulatory Compliance Dashboard | P0 | reg | base / rec / reg | documentation-first-scaffold |
| 13 | DORA Operational Resilience Monitor | P1 | rec | base / rec / reg | documentation-first-scaffold |
| 14 | Communication Compliance Configurator | P1 | rec | base / rec / reg | documentation-first-scaffold |
| 15 | Copilot Pages and Notebooks Compliance Gap Monitor | P2 | rec | base / rec / reg | documentation-first-scaffold |
| 16 | Item-Level Oversharing Scanner | P1 | rec | base / rec / reg | documentation-first-scaffold |
| 17 | SharePoint Permissions Drift Detection | P1 | rec | base / rec / reg | documentation-first-scaffold |
| 18 | Entra Access Reviews Automation | P1 | rec | base / rec / reg | documentation-first-scaffold |
| 19 | Copilot Tuning Governance | P1 | rec | base / rec / reg | documentation-first-scaffold |
| 20 | Generative AI Model Governance Monitor | P1 | rec | base / rec / reg | documentation-first-scaffold |
| 21 | Cross-Tenant Agent Federation Auditor | P1 | rec | base / rec / reg | documentation-first-scaffold |
| 22 | Pages and Notebooks Retention Tracker | P1 | rec | base / rec / reg | documentation-first-scaffold |
| 23 | Copilot Studio Agent Lifecycle Tracker | P1 | rec | base / rec / reg | documentation-first-scaffold |

See [Tier Applicability](./docs/reference/tier-applicability.md) for per-solution tier guidance and configuration deltas, and [Control Coverage Honesty](./docs/reference/control-coverage-honesty.md) for what each control mapping actually demonstrates today.

## Operator preflight

1. Review `docs/getting-started/prerequisites.md` and `docs/getting-started/identity-and-secrets-prep.md` before planning tenant changes.
2. Confirm named owners, escalation paths, and the operating cadence in `docs/operational-handbook.md`, `docs/operational-raci.md`, `docs/operational-cadence.md`, and `docs/escalation-procedures.md`.
3. Use `docs/documentation-vs-runnable-assets-guide.md` to decide which repository assets are authoritative documentation, starter templates, or directly runnable scripts.
4. Run `pwsh -File scripts/deployment/Validate-Prerequisites.ps1` and record any gaps in `DELIVERY-CHECKLIST-TEMPLATE.md`.
5. Review the [Threat Model](./docs/security/threat-model.md) and [Managed Identity Standard](./docs/security/managed-identity-standard.md) before any production rollout.
6. Confirm the [Data Classification Matrix](./docs/reference/data-classification.md) entries match your tenant's residency and retention obligations.

## Recommended wave sequence

### Wave 0 — Operator preflight and non-production validation

- Confirm identity ownership, secret storage, evidence destination, and change-window approvals.
- Validate the intended deployment sequence in a non-production tenant before scheduling a production wave.

### Wave 1 — Readiness and oversharing foundation

- Run the readiness and oversharing solutions before enabling broad Copilot access.
- Solutions 16 (Item-Level Oversharing Scanner), 17 (SharePoint Permissions Drift Detection), and 18 (Entra Access Reviews Automation) extend the Wave 1 foundation with item-level scanning, permissions drift detection, and access-review automation.

### Wave 2 — Security and compliance controls

- Add supervision, DLP, audit trail, and Conditional Access controls for regulated workloads.

### Wave 3 — Rollout orchestration and reporting

- Layer in rollout orchestration, feature management, connector governance, and compliance reporting.

### Wave 4 — Resilience and compensating controls

- Finish with resilience, communication-compliance, and compensating-control solutions.

## Use-case mapping

| Customer Need | Solutions |
|---------------|-----------|
| Copilot readiness, label posture, and oversharing cleanup | 01, 02, 03, 16, 17, 18 |
| Broker-dealer supervision and communications oversight | 04, 06, 14 |
| DLP, Conditional Access, and feature-state governance | 05, 07, 09 |
| License optimization, phased rollout, and control reporting | 08, 11, 12 |
| Connector approvals and extensibility governance | 10, 21 |
| DORA resilience and Pages/Notebooks compensating controls | 13, 15, 22 |
| Generative-AI model governance and Copilot Studio agent lifecycle | 19, 20, 23 |

## Licensing footprint

The solutions in this repository document patterns that depend on Microsoft 365 Copilot, Microsoft Purview, Microsoft Power Platform, and Microsoft Entra ID. Confirm tenant licensing before scheduling a wave.

| Capability | Required for | Typical license |
|------------|--------------|-----------------|
| Microsoft 365 Copilot | All Copilot governance solutions | Microsoft 365 Copilot add-on per user |
| Purview Information Protection / DLP | Solutions 03, 05, 14, 15, 22 | Microsoft 365 E5 Compliance (or E5 Information Protection & Governance) |
| Purview Audit (Premium) / eDiscovery | Solutions 04, 06, 14 | Microsoft 365 E5 Compliance |
| Microsoft Defender for Cloud Apps / Insider Risk | Solutions 02, 14 | Microsoft 365 E5 Security / E5 Compliance |
| Microsoft Entra ID Governance (Access Reviews, PIM) | Solutions 07, 18 | Microsoft Entra ID P2 + Entra ID Governance |
| Power Platform (Power Automate, Power BI Pro/Premium) | Solutions producing dashboards or workflow automation (most solutions) | Power Automate Premium per user; Power BI Pro/Premium per workspace |
| Microsoft Sentinel / Defender XDR | Solutions 13, 21 | Sentinel ingestion + Defender XDR |
| Copilot Studio | Solutions 23 (and 21 cross-tenant federation considerations) | Copilot Studio per-tenant + per-user entitlements |

> Costs vary by tenant footprint, region, and EA terms. Treat this table as a checklist input, not a quote.

## Pilot path (recommended for first deployment)

A concrete 5-step pilot path for an FSI tenant evaluating this repository:

1. **Scope the pilot.** Choose one regulated business unit and one non-regulated business unit; clone this repository at the pinned [FRAMEWORK-VERSION](./FRAMEWORK-VERSION).
2. **Foundation wave.** Deploy solution 01 (Readiness Scanner) and solution 02 (Oversharing) in the regulated unit at tier `regulated`. Validate the evidence-export samples end-to-end.
3. **Supervision wave.** Add solution 04 (FINRA Supervision Workflow) and solution 06 (Audit Trail Manager). Confirm the [Hybrid Flow Validation Proposal](./docs/reference/hybrid-flow-validation-proposal.md) approach matches your Power Automate ALM model.
4. **Reporting wave.** Add solution 12 (Regulatory Compliance Dashboard). Confirm the dashboard feed schema matches your downstream BI consumer.
5. **Pilot retrospective.** Run all validators (`python scripts/build-docs.py`, `validate-contracts.py`, `validate-solutions.py`, `validate-documentation.py`, `validate_solutions_json.py`, `validate_data_classification.py`, `verify_readme_counts.py`). Record gaps in `DELIVERY-CHECKLIST-TEMPLATE.md` and decide which controls require tenant binding before broader rollout.

## Shared platform dependencies

- `data/controls-master.json` and `data/control-coverage.json` define the control contract for every solution.
- `data/evidence-schema.json` defines the required evidence package format.
- `data/data-classification.json` defines per-solution data classification, residency, and retention defaults.
- `scripts/common/IntegrationConfig.psm1` freezes tier names, status values, and naming patterns.
- `templates/dashboard/control-feed-schema.json` defines the feed contract for dashboard integration.

## Connectivity readiness

Before scheduling a deployment wave, confirm that the required service connections are approved and available. All solutions require Dataverse capacity for evidence and baseline storage.

| Wave | Solutions | Graph API | Power BI | Power Automate | Purview | Entra ID | Other |
|------|-----------|-----------|----------|----------------|---------|----------|-------|
| 1 | 01, 02, 03, 16, 17, 18 | ✅ | ✅ | ✅ | ✅ | ✅ | SharePoint, Entra ID |
| 2 | 04, 05, 06, 07 | ✅ | ✅ | ✅ | ✅ | ✅ | eDiscovery, Exchange |
| 3 | 08, 09, 10, 11, 12 | ✅ | ✅ | ✅ | — | — | Viva Insights, Teams Admin, Power Platform |
| 4 | 13, 14, 15, 19, 20, 21, 22, 23 | ✅ | ✅ | ✅ | ✅ | — | Sentinel, eDiscovery, Copilot Studio |

> **Important:** All solutions in this repository are documentation-first scaffolds using representative sample data. The service connections listed above are required when the customer implements tenant-specific integration. See [Documentation vs Runnable Assets Guide](./docs/documentation-vs-runnable-assets-guide.md).

## Publication workflow

- `scripts/build-docs.py` rebuilds `site-docs/` from root docs and solution READMEs.
- `scripts/validate-contracts.py`, `scripts/validate-solutions.py`, `scripts/validate-documentation.py`, `scripts/validate_solutions_json.py`, `scripts/validate_solutions_graph.py`, and `scripts/validate_data_classification.py` are the required pre-publish gates.
- `.github/workflows/publish_docs.yml` runs the build and publishes the site on pushes to `main`.

## Revision history

- **v1.0** — Promoted to v1.0: added status banner, what is/is-not preamble, tier-applicability matrix, licensing footprint, concrete pilot path, threat-model and data-classification cross-references.
- **v0.x** — Initial documentation-first scaffolding (wave plan + use-case mapping + connectivity readiness).