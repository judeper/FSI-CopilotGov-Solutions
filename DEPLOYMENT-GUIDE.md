# Deployment Guide

This guide maps common Microsoft 365 Copilot governance needs to the solution set in this repository.

## Operator Preflight

1. Review `docs\getting-started\prerequisites.md` and `docs\getting-started\identity-and-secrets-prep.md` before planning tenant changes.
2. Confirm named owners, escalation paths, and the operating cadence in `docs\operational-handbook.md`, `docs\operational-raci.md`, `docs\operational-cadence.md`, and `docs\escalation-procedures.md`.
3. Use `docs\documentation-vs-runnable-assets-guide.md` to decide which repository assets are authoritative documentation, starter templates, or directly runnable scripts.
4. Run `pwsh -File scripts\deployment\Validate-Prerequisites.ps1` and record any gaps in `DELIVERY-CHECKLIST-TEMPLATE.md`.

## Recommended Wave Sequence

### Wave 0 — Operator preflight and non-production validation

- Confirm identity ownership, secret storage, evidence destination, and change-window approvals.
- Validate the intended deployment sequence in a non-production tenant before scheduling a production wave.

### Wave 1 — Readiness and oversharing foundation

- Run the readiness and oversharing solutions before enabling broad Copilot access.

### Wave 2 — Security and compliance controls

- Add supervision, DLP, audit trail, and Conditional Access controls for regulated workloads.

### Wave 3 — Rollout orchestration and reporting

- Layer in rollout orchestration, feature management, connector governance, and compliance reporting.

### Wave 4 — Resilience and compensating controls

- Finish with resilience, communication-compliance, and compensating-control solutions.

## Use-Case Mapping

| Customer Need | Solutions |
|---------------|-----------|
| Copilot readiness, label posture, and oversharing cleanup | 01, 02, 03 |
| Broker-dealer supervision and communications oversight | 04, 06, 14 |
| DLP, Conditional Access, and feature-state governance | 05, 07, 09 |
| License optimization, phased rollout, and control reporting | 08, 11, 12 |
| Connector approvals and extensibility governance | 10 |
| DORA resilience and Pages/Notebooks compensating controls | 13, 15 |

## Shared Platform Dependencies

- `data/controls-master.json` and `data/control-coverage.json` define the control contract for every solution.
- `data/evidence-schema.json` defines the required evidence package format.
- `scripts/common/IntegrationConfig.psm1` freezes tier names, status values, and naming patterns.
- `templates/dashboard/control-feed-schema.json` defines the feed contract for dashboard integration.

## Connectivity Readiness

Before scheduling a deployment wave, confirm that the required service connections are approved and available. All solutions require Dataverse capacity for evidence and baseline storage.

| Wave | Solutions | Graph API | Power BI | Power Automate | Purview | Entra ID | Other |
|------|-----------|-----------|----------|----------------|---------|----------|-------|
| 1 | 01, 02, 03 | ✅ | ✅ | ✅ | ✅ | — | SharePoint |
| 2 | 04, 05, 06, 07 | ✅ | ✅ | ✅ | ✅ | ✅ | eDiscovery, Exchange |
| 3 | 08, 09, 10, 11, 12 | ✅ | ✅ | ✅ | — | — | Viva Insights, Teams Admin, Power Platform |
| 4 | 13, 14, 15 | ✅ | ✅ | ✅ | ✅ | — | Sentinel, eDiscovery |

> **Important:** All solutions in this repository are documentation-first scaffolds using representative
> sample data. The service connections listed above are required when the customer implements
> tenant-specific integration. See [Documentation vs Runnable Assets Guide](./docs/documentation-vs-runnable-assets-guide.md).

## Publication Workflow

- `scripts/build-docs.py` rebuilds `site-docs/` from root docs and solution READMEs.
- `scripts/validate-contracts.py`, `scripts/validate-solutions.py`, and `scripts/validate-documentation.py` are the required pre-publish gates.
- `.github/workflows/publish_docs.yml` runs the build and publishes the site on pushes to `main`.
