# Deployment Guide

This guide maps common Microsoft 365 Copilot governance needs to the solution set in this repository.

## Recommended Sequence

1. Run the readiness and oversharing solutions before enabling broad Copilot access.
2. Add supervision, DLP, audit trail, and Conditional Access controls for regulated workloads.
3. Layer in rollout orchestration, feature management, connector governance, and compliance reporting.
4. Finish with resilience, communication-compliance, and compensating-control solutions.

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

## Publication Workflow

- `scripts/build-docs.py` rebuilds `site-docs/` from root docs and solution READMEs.
- `scripts/validate-contracts.py`, `scripts/validate-solutions.py`, and `scripts/validate-documentation.py` are the required pre-publish gates.
- `.github/workflows/publish_docs.yml` runs the build and publishes the site on pushes to `main`.
