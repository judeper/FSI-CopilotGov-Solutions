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

## Solution-Level Status Values

These values describe the overall implementation depth of a solution and appear in the solution README status line. They are distinct from the control-level status values above.

| Status | Meaning |
|--------|---------|
| Documentation-first scaffold | Solution provides governance scaffolds, templates, and scripts using representative sample data. Tenant binding required for production use. |
| Documentation-first with validation scripts | Solution provides scaffolds plus functional validation scripts that check configuration alignment. Tenant binding required for production use. |
| Requires tenant binding for production use | Solution scripts are ready for tenant integration but require authentication, connection references, and environment configuration. |

## Dataverse Naming

- Table pattern: `fsi_cg_{solution}_{purpose}`
- Purpose suffixes: `baseline`, `assessmenthistory`, `finding`, `evidence`
- Connection references: `fsi_cr_{solution}_{service}`
- Environment variables: `fsi_ev_{solution}_{setting}`

## Evidence Contract

- Every solution exports JSON evidence aligned to `data/evidence-schema.json`.
- Every evidence file receives a companion `.sha256` file.
- Unified evidence export aggregates solution packages into a single manifest with per-file hashes.

## Traceability Contract

- `data/frameworks-master.json` is the canonical registry for framework IDs, display names, aliases, mapped controls, and mapped solutions.
- `framework_ids` is the complete machine-readable framework crosswalk in `data/solution-catalog.json`, `data/solution-to-playbooks.json`, `data/control-coverage.json`, and `solutions/*/config/default-config.json`.
- `regulations` remains the concise reviewer-facing list; every value must resolve to a canonical framework ID through the framework registry aliases.
- Cross-repo framework playbook links published into `site-docs/` must be pinned to the documented `FSI-CopilotGov` commit rather than `main`.

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
