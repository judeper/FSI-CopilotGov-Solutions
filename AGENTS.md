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
| 10 | Copilot Connector and Plugin Governance | P1 | C | 1.13, 2.13, 2.14, 4.13 |
| 11 | Risk-Tiered Rollout Automation | P0 | C | 1.9, 1.11, 1.12, 4.12 |
| 12 | Regulatory Compliance Dashboard | P0 | C | 3.7, 3.8, 3.12, 3.13, 4.5, 4.7 |
| 13 | DORA Operational Resilience Monitor | P1 | D | 2.7, 4.9, 4.10, 4.11 |
| 14 | Communication Compliance Configurator | P1 | D | 2.10, 3.4, 3.5, 3.6, 3.9 |
| 15 | Copilot Pages and Notebooks Compliance Gap Monitor | P2 | D | 2.11, 3.2, 3.3, 3.11 |

## Directory Structure

```
FSI-CopilotGov-Solutions/
|-- docs/                     # Source documentation for the public site
|-- data/                     # Machine-readable control, solution, and evidence metadata
|-- scripts/                  # Build, validation, shared modules, and deployment utilities
|-- solutions/                # Fifteen Copilot governance solution folders
|-- templates/                # Policy templates, dashboard feed schema, and regulatory mapping assets
|-- site-docs/                # Generated MkDocs input built from docs/ and solution READMEs
```

## Validation Commands

```powershell
python scripts/build-docs.py
python scripts/validate-contracts.py
python scripts/validate-solutions.py
python scripts/validate-documentation.py
pwsh -Command "Get-ChildItem -Recurse -Filter *.ps1 | ForEach-Object { [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$null) | Out-Null }"
```
