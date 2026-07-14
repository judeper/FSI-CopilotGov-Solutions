# Changelog

## [Unreleased]

### Added
- Read-only lab validation contract at `lab/22-pages-notebooks-retention-tracker.lab.json` (template binding, `mutations: []`) with verified Microsoft source claims for the shared SharePoint Embedded container model, retention policy/label behavior, eDiscovery and legal hold, the no-recycle-bin/no-recovery limitation for Copilot Notebooks, and the rollout-sensitive eDiscovery review-set indexing/HTML export enhancements (Microsoft 365 Roadmap 561492).
- Lab Validation Handoff guidance in `docs/deployment-guide.md` and a lab-handoff item in `DELIVERY-CHECKLIST.md`.
- Platform lifecycle and rollout notes in `docs/architecture.md`, a non-recoverable Copilot Notebook troubleshooting entry, and an eDiscovery rollout note in `docs/evidence-export.md`, aligned to current Microsoft Learn guidance (`cpcn-storage`, `cpcn-compliance-summary`, verified 2026-07-13).
- Pester regression tests covering read-only `-WhatIf` execution, evidence-package portability after relocation, and lab-contract shape.

### Changed
- `Monitor-Compliance.ps1` and `Export-Evidence.ps1` now support `SupportsShouldProcess`/`-WhatIf`, so lab validation can run them read-only (no snapshot, artifacts, or package files written) while still returning the sample inventory and evidence plan via `-PassThru`.

### Fixed
- Evidence package now records package-relative artifact paths so the package continues to validate after the evidence directory is relocated, while `Export-Evidence.ps1` still returns usable absolute artifact and package paths to callers.

## [v0.1.3] - 2026-06-05 — Copilot Notebooks accuracy correction

### Fixed
- Corrected product model: replaced OneNote section-file storage references with the correct Copilot Notebooks SharePoint Embedded container model per Microsoft Learn.
- Updated Graph permission scope from `Notes.Read.All` to `Sites.Read.All` (SharePoint Embedded container scope) for Copilot Notebook inventory.
- Fixed terminology in config, README, architecture, evidence-export schema, monitor sample data, and prerequisites to consistently use "Copilot Notebooks" instead of legacy OneNote notebook terminology where the solution tracks Copilot Notebook content.
- Resolved prerequisites.md self-contradiction (required OneNote while tracking Copilot Notebooks).
- Softened "Microsoft Purview compliance endpoints" to "Microsoft Purview service endpoints" to avoid evoking the retired compliance portal brand.

## Validation Sweep — 2026-05-25

### Verified

- All PowerShell scripts pass syntax validation.
- Copilot Pages and Copilot Notebooks terminology confirmed current per Microsoft Learn.
- SharePoint Embedded storage model for Pages/Notebooks confirmed accurate.
- Retention label caveats (cannot view/apply from Copilot Page) confirmed per Microsoft Learn.
- Regulatory citations (SEC Rule 17a-4, FINRA Rule 4511(a), SOX §§302/404) are accurate with proper qualifiers.
- Added `last_verified` to `config/default-config.json`.

## v0.1.2 — 2026-05-23 — Council review remediation

### Fixed
- F-04: Added configuration range checks for evidence retention days, Pages retention days, Notebook retention days, and retention-label coverage percentages.
- F-07: Added Pester smoke tests that execute deployment, monitoring, and evidence export scripts with a test output path and recompute SHA-256 companion hashes.
- F-12: Replaced imprecise Graph module prerequisite wording with exact Microsoft Graph PowerShell submodule names.

### Dead config
- F-10: Wired `branchingAuditRequired` into configuration validation, deployment manifests, and internal sample lineage generation.

## [v0.1.1] - 2026-05-04

### Changed
- Corrected PNRT documentation and script terminology to align Copilot Pages and Notebooks evidence with SharePoint Embedded storage, Purview audit logs, retention policies/limited labels, and version-history surfaces documented by Microsoft Learn.
- Reframed OneNote evidence as section and folder retention coverage grouped by Notebook metadata rather than direct Notebook-level retention-label assignment.
- Qualified `branching-event-log` rows as repository-only internal sample lineage taxonomy, not Microsoft 365 branch/fork/mutability lifecycle events.

## v0.1.0 - 2025-01-15

### Added
- Initial Pages and Notebooks Retention Tracker (PNRT) scaffold
- Tiered configuration covering Copilot Pages retention, OneNote section/folder retention grouped by Notebook metadata, internal sample lineage mode, and Loop component provenance
- Deploy-Solution.ps1 with tier-aware deployment manifest generation
- Monitor-Compliance.ps1 with sample-data inventory of Pages, OneNote sections, Loop components, and internal sample lineage events
- Export-Evidence.ps1 producing pages-retention-inventory, notebook-retention-log, loop-component-lineage, and branching-event-log (internal sample lineage) artifacts with SHA-256 companions
- Pester smoke tests covering file presence, configuration shape, and script parameter validation
- Documentation set: architecture, deployment guide, evidence export, prerequisites, troubleshooting
