# AGENTS.md - Instructions for AI Agents

This repository contains documentation-first governance solution scaffolds for Microsoft 365 Copilot in regulated financial services.

## Core Expectations

- Treat `FSI-CopilotGov` as the source of truth for control intent, playbooks, and regulatory language.
- Keep this repository standalone at runtime; link back to framework docs, but do not introduce cross-repo execution dependencies.
- Use cautious language such as "supports compliance with" and "helps meet".
- Do not use overstated claims implying live API integration when scripts use representative sample data (e.g., avoid "performs Graph API-based scanning", "sequences license assignment", "aggregates evidence into Power BI").
- Do not commit exported Power Automate runtime artifacts; document how to build flows and apps instead.
- Use Dataverse logical names in lowercase without inserted underscores between words.
- Every solution README must include a `## Scope Boundaries` section listing what the solution does NOT do.
- Every solution README must use the standardized status line format: `> **Status:** Documentation-first scaffold | **Version:** vX.Y.Z | **Priority:** PX | **Track:** X`
- Every solution README must include a disclaimer banner linking to `docs/disclaimer.md` and `docs/documentation-vs-runnable-assets-guide.md`.

## Solution Catalog

| ID | Solution | Priority | Track | Controls |
|----|----------|----------|-------|----------|
| 01 | Copilot Readiness Assessment Scanner | P0 | A | 1.1, 1.5, 1.6, 1.7, 1.9 |
| 02 | Oversharing Risk Assessment and Remediation | P0 | A | 1.2, 1.3, 1.4, 1.6, 2.5, 2.12 |
| 03 | Sensitivity Label Coverage Auditor | P1 | A | 1.5, 2.2, 3.11, 3.12 |
| 04 | FINRA Supervision Workflow for Copilot | P0 | B | 3.4, 3.5, 3.6 |
| 05 | DLP Policy Governance for Copilot | P1 | B | 2.1, 3.10, 3.12 |
| 06 | Copilot Interaction Audit Trail Manager | P0 | B | 3.1, 3.2, 3.3, 3.11, 3.12 |
| 07 | Conditional Access Policy Automation for Copilot | P1 | B | 2.3, 2.6, 2.9 |
| 08 | License Governance and ROI Tracker | P1 | C | 1.9, 4.5, 4.6, 4.8 |
| 09 | Copilot Feature Management Controller | P1 | C | 2.6, 4.1, 4.2, 4.3, 4.4, 4.12, 4.13 |
| 10 | Copilot Connector and Plugin Governance | P1 | C | 1.13, 2.13, 2.14, 2.16, 4.13 |
| 11 | Risk-Tiered Rollout Automation | P0 | C | 1.9, 1.11, 1.12, 4.12 |
| 12 | Regulatory Compliance Dashboard | P0 | C | 3.7, 3.8, 3.12, 3.13, 4.5, 4.7 |
| 13 | DORA Operational Resilience Monitor | P1 | D | 2.7, 4.9, 4.10, 4.11 |
| 14 | Communication Compliance Configurator | P1 | D | 2.10, 3.4, 3.5, 3.6, 3.9 |
| 15 | Copilot Pages and Notebooks Compliance Gap Monitor | P2 | D | 2.11, 3.2, 3.3, 3.11 |
| 16 | Item-Level Oversharing Scanner | P1 | A | 1.2, 1.3, 1.4, 1.6, 2.5 |
| 17 | SharePoint Permissions Drift Detection | P1 | A | 1.2, 1.4, 1.6, 2.5 |
| 18 | Entra Access Reviews Automation | P1 | A | 1.2, 1.6, 2.5, 2.12 |
| 19 | Copilot Tuning Governance | P1 | A | 1.16, 3.8 |
| 20 | Generative AI Model Governance Monitor | P1 | D | 3.8a, 3.8, 3.1, 3.11, 3.12 |
| 21 | Cross-Tenant Agent Federation Auditor | P1 | B | 2.17, 2.16, 1.10, 2.13, 2.14, 4.13 |
| 22 | Pages and Notebooks Retention Tracker | P1 | D | 3.14, 3.2, 3.3, 3.11, 2.11 |
| 23 | Copilot Studio Agent Lifecycle Tracker | P1 | C | 4.14, 4.13, 1.10, 1.16, 4.5, 4.12 |

## Directory Structure

```
FSI-CopilotGov-Solutions/
|-- docs/                     # Source documentation for the public site
|-- data/                     # Machine-readable control, solution, and evidence metadata
|-- scripts/                  # Build, validation, shared modules, and deployment utilities
|-- solutions/                # Twenty-three Copilot governance solution folders
|-- templates/                # Policy templates, dashboard feed schema, and regulatory mapping assets
|-- site-docs/                # Generated MkDocs input built from docs/ and solution READMEs
```

## Validation Commands

```powershell
python scripts/test_docs_protection.py
python scripts/build-docs.py
python scripts/validate-contracts.py
python scripts/validate-solutions.py
python scripts/validate-documentation.py
python scripts/validate_solutions_json.py
python scripts/validate_solutions_graph.py
python scripts/validate_data_classification.py
python scripts/verify_readme_counts.py
python scripts/verify_commercial_scope.py
python scripts/validate-lab-contracts.py
python scripts/validate-lab-result.py
python scripts/test_lab_validation_contracts.py
python -m mkdocs build --strict
pwsh -Command "Get-ChildItem -Recurse -Filter *.ps1 | ForEach-Object { [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$null) | Out-Null }"
```

## Documentation Autonomy Protection

- `.github/branch-protection.json` is the committed source of truth for the proposed `main` protection policy. Changing it does not apply live GitHub settings.
- `Docs Autonomy Gate` must run on every pull request. It runs the deterministic documentation, contract, solution-index, evidence, and strict MkDocs validators when documentation-impacting paths change; otherwise it returns a successful shim result so non-documentation pull requests cannot deadlock.
- Keep every context in `required_status_checks.contexts` backed by an unfiltered `pull_request` workflow job with the exact same display name.
- External network link checks are intentionally non-required because network availability is not deterministic.

## Review and Lab Validation Lifecycle

- The current program reviews each solution one at a time for Microsoft product and feature accuracy, then hardens it for read-only lab validation. The authoritative status snapshot, blockers, and resume sequence live in `docs/project-handoff.md` — read it before starting or resuming work.
- **Contract vs executor ownership.** `FSI-CopilotGov-Solutions` owns versioned lab contracts (`lab/<solution>.lab.json`), result and package validation, schemas, and fixtures. The separate `studio-video-factory` lane owns Playwright execution and evidence capture. Keep this repository documentation-first; do not add browser automation or attended tenant runs here.
- **Read-only first cycle and dispositions.** The first lab cycle is read-only/detect-only; contracts normally declare `mutations: []`, and any non-null `mutationRef` must resolve to a declared mutation. Dispositions are `PASS`, `PARTIAL`, `BLOCKED`, `NOT-APPLICABLE`, and `FAIL`. Accepted `BLOCKED` and `NOT-APPLICABLE` require negative evidence **and** source verification and must not claim implemented control state.
- **Evidence and path portability.** Package artifact paths are relative (relocatable); caller-returned artifact paths are absolute. Resolve PowerShell paths provider-aware — never use raw `GetFullPath` on relative input. Do not place raw identifiers, secrets, or PII in evidence.
- **Pester.** Pin Pester `5.7.1` and set `Run.Exit` to `true` so failing tests return a non-zero exit code.
- **Pester data-driven tests.** Do not define Pester tests inside a PowerShell `foreach` loop that relies on captured loop variables; use Pester's `-ForEach` parameter so values remain available at run time.
- **Strict MkDocs.** The site must build clean under `python -m mkdocs build --strict`.
- **Commercial-only contracts.** Forward-facing solution contracts omit the optional `prohibitedClouds` field and rely on the commercial-scope constants.

## Worktree and Branch Hygiene

- One modifying agent per worktree; a modifying agent owns its worktree exclusively. Never run `git checkout` in another agent's worktree.
- After a branch is pushed and its local worktree is clean, remove the worktree and local branch and prune merged worktrees.
- Preserve remote branches that back an open PR. Merged foundation remote branches (for example #315, #316, #318) may be deleted.
