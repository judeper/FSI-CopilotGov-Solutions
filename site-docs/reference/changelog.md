# Changelog

All notable changes to FSI-CopilotGov-Solutions are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## v0.3.0

### Added
- Solution 16: Item-Level Oversharing Scanner — scans individual SharePoint files and folders for overshared permissions, applies FSI risk scoring, and provides approval-gated remediation.
- Solution 17: SharePoint Permissions Drift Detection — captures baseline permissions, detects drift over time, and supports approval-gated reversion with examiner-ready evidence export.
- Solution 18: Entra Access Reviews Automation — automates Entra ID Access Reviews prioritized by risk tier from Solutions 02 and 16.
- Upgraded `scripts/common/GraphAuth.psm1` from placeholder stub to live authentication module with `Connect-CopilotGovGraph` (app-only and delegated auth) and `Invoke-CopilotGovGraphRequest` (retry, throttle handling, paging).

### Changed
- Solution 02 `Monitor-Compliance.ps1` refactored to use live Microsoft Graph API calls when authentication parameters are supplied; falls back to representative sample data when no auth is provided.
- Updated repository metadata for 18 solutions: `solution-config.yml`, `solution-catalog.json`, `solution-to-playbooks.json`, `frameworks-master.json`, `control-coverage.json`, `examination-readiness.md`.
- Updated AGENTS.md, README.md, and architecture documentation to reflect 18 solutions.

## v0.2.1

### Changed
- Standardized all 15 solution README status lines to use consistent "Documentation-first scaffold" taxonomy.
- Added disclaimer banner to all 15 solution READMEs linking to the expanded disclaimer and documentation-vs-runnable-assets guide.
- Added "Scope Boundaries" section to all 15 solution READMEs with explicit lists of what each solution does not do.
- Softened overstated semantic claims in solutions 01, 05, 06, 07, 09, 10, 11, 13, and 14 to use documentation-first language.
- Removed non-existent `Check-AuditLogCompleteness` function reference from solution 06.
- Changed root README opening from "Deployable automation patterns" to "Governance solution scaffolds and documentation patterns".
- Changed AGENTS.md from "deployable governance solution scaffolds" to "documentation-first governance solution scaffolds".
- Expanded `docs/disclaimer.md` from two sentences to comprehensive FSI disclaimer covering sample data, no compliance guarantee, and customer responsibility.
- Added module-level `.SYNOPSIS` to `EvidenceExport.psm1` clarifying schema and hash validation scope.
- Added solution-level status value enum to `docs/reference/shared-modules-contract.md`.
- Added customer understanding checkbox to `DELIVERY-CHECKLIST-TEMPLATE.md`.
- Added Implementation Depth matrix and Connectivity Readiness table to root README.
- Added Connectivity Readiness section to `DEPLOYMENT-GUIDE.md`.
- Expanded `docs/reference/architecture.md` with detailed layer descriptions and shared module inventory.
- Extended `validate-documentation.py` with overstated claim pattern detection, status line format validation, and Scope Boundaries section presence check.
- Added `allTestResults.xml` and `testResults.xml` to `.gitignore`.

## v0.2.0

### Added
- Full solution implementations for all 15 governance solutions with Deploy-Solution.ps1, Monitor-Compliance.ps1, and Export-Evidence.ps1 scripts.
- Tiered configuration files (baseline, recommended, regulated) for each solution with graduated evidence retention and governance controls.
- Comprehensive documentation suite for each solution: architecture, deployment guide, evidence export, prerequisites, and troubleshooting.
- Pester test coverage across all 15 solutions (167 tests).
- Delivery checklists with sign-off sections for each solution.
- Evidence export with SHA-256 companion files and schema validation.
- Shared PowerShell modules: GraphAuth, EvidenceExport, DataverseHelpers, EntraHelpers, IntegrationConfig, PurviewHelpers, TeamsNotification.
- Deployment utilities: Validate-Prerequisites.ps1, Deploy-Solution.ps1, Export-CopilotGovernanceEvidence.ps1, Test-EvidenceIntegrity.ps1, New-SolutionScaffold.ps1.
- Operator documentation: prerequisites, identity-and-secrets-prep, operational handbook, RACI, cadence, escalation procedures.
- DEPLOYMENT-GUIDE.md with five-wave sequencing and use-case mapping.
- GitHub Actions workflows for contract, solution, documentation, and evidence validation.
- MkDocs site generation with Material theme and automated build pipeline.

### Changed
- Runtime hardening: softened overstated implementation claims in solutions 01, 11, 12, and 13 to use documentation-first language.
- Added .SYNOPSIS help text to five shared PowerShell modules for clarity on documentation-first scope.
- Fixed misspelled configuration key in solution 06 (audit trail manager).

## v0.1.0

- Bootstrapped the repository foundation for FSI-CopilotGov-Solutions.
- Added shared contracts, mappings, validation scripts, docs publishing, and scaffolds for all 15 planned solutions.
