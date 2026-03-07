# Shared Modules Contract

This document defines the shared naming, evidence, and integration rules that all FSI-CopilotGov-Solutions content must follow.

## Governance Tiers

| Value | Label | Purpose |
|-------|-------|---------|
| 1 | baseline | Minimum viable governance for initial Microsoft 365 Copilot rollout |
| 2 | recommended | Strong production posture for most regulated deployments |
| 3 | regulated | Examination-ready posture for high-risk or heavily supervised environments |

## Status Values

| Status | Meaning | Dashboard Score |
|--------|---------|-----------------|
| implemented | Solution fully covers the mapped control intent | 100 |
| partial | Solution covers part of the control intent and requires manual follow-up | 50 |
| monitor-only | Solution reports posture but does not remediate automatically | 25 |
| playbook-only | Framework playbooks remain the primary implementation source | 10 |
| not-applicable | Control is intentionally out of scope for the target deployment | 0 |

## Dataverse Naming

- Table pattern: `fsi_cg_{solution}_{purpose}`
- Purpose suffixes: `baseline`, `assessmenthistory`, `finding`, `evidence`
- Connection references: `fsi_cr_{solution}_{service}`
- Environment variables: `fsi_ev_{solution}_{setting}`

## Evidence Contract

- Every solution exports JSON evidence aligned to `data/evidence-schema.json`.
- Every evidence file receives a companion `.sha256` file.
- Unified evidence export aggregates solution packages into a single manifest with per-file hashes.

## Required Solution Docs

- README.md
- DELIVERY-CHECKLIST.md
- docs/architecture.md
- docs/deployment-guide.md
- docs/evidence-export.md
- docs/prerequisites.md
- docs/troubleshooting.md

## Immutability Rules

- Tier names and status values are contract-controlled.
- Any dashboard feed schema change requires a version bump in the evidence schema and release notes in `CHANGELOG.md`.
- Existing control IDs and solution slugs are stable identifiers and must not be renamed casually.
