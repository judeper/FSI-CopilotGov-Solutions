# Changelog

All notable changes to this solution are documented in this file.

The format is based on Keep a Changelog and uses solution version tags instead of package release tags.

## [Unreleased]

### Added

- Lab validation contract `lab/19-copilot-tuning-governance.lab.json` for a read-only, detect-only validation cycle. The contract is read-only (`mutations: []`), scoped to US commercial-cloud Microsoft 365, and defines setup/exercise/verify/cleanup phases, read-backs, required evidence, negative-state capture, and Microsoft Learn source claims.
- Lab validation handoff sections in `docs/deployment-guide.md` and `DELIVERY-CHECKLIST.md`.
- Cloud availability and data residency guidance (commercial-cloud scope, Advanced Data Residency waiver, EU Data Boundary, Multi-Geo not applicable during public preview) and a read-only reviewer role (AI Reader / Global Reader) in `docs/prerequisites.md`.
- Regression tests asserting the evidence package uses package-relative artifact paths, stays valid after relocation, and that the lab contract is read-only and covers the solution controls and required phases.

### Fixed

- `Export-Evidence.ps1` now records package-relative artifact paths inside the evidence package so an exported package still validates after it is moved to an archive or WORM store, while surfacing absolute artifact paths to the caller.

### Changed

- Registered the solution 19 lab contract in the shared `scripts/test_lab_validation_contracts.py` default-discovery test.
- Documented the Agent 365 portal as Microsoft's authoritative tuned-agent inventory and lifecycle surface (view, block/disable, delete) in the README and `docs/architecture.md`, clarifying that this solution's model-inventory patterns are a governance overlay.
- Clarified that Microsoft's Copilot Tuning source-data snapshot retention (tenant-isolated, maximum two years, tied to agent lifecycle, with source DLP/retention not applied to snapshots) is distinct from this solution's governance-evidence retention (README, `docs/architecture.md`, `docs/evidence-export.md`).
- Re-verified Microsoft currency against Microsoft Learn as of 2026-07-14: Copilot Tuning remains an early access preview capability (Frontier access planned for April 2026, features and requirements subject to change), the public-preview eligibility threshold remains at least 5,000 Microsoft 365 Copilot licenses with the capability enabled by default for eligible tenants, AI admins manage tuning through the Copilot control system in the Microsoft 365 admin center, and no public API or PowerShell surface for Copilot Tuning management is documented. Updated the README "Last Verified" date. The M365 roadmap lists a planned general-availability date, but the conservative preview state is retained until Microsoft Learn reflects general availability.

## [v0.1.4] — 2026-06-05 — MS Learn accuracy pass-2 correction

### Fixed

- Corrected product name "Microsoft 365 Copilot Agent Builder" → "Agent Builder in Microsoft 365 Copilot" per MS Learn canonical naming (README.md scope boundaries and known limitations sections).
- Corrected product name "Agent 365" → "Microsoft Agent 365" in the same two locations per MS Learn.



### Fixed

- Replaced bare "Agent Builder" with the full brand name "Microsoft 365 Copilot Agent Builder" (README, troubleshooting).

### Added

- Noted the open-source / external base-model admin control as a real governance lever not yet covered (Known Limitations).

## Validation Sweep — 2026-05-25

### Verified

- All Microsoft Learn URLs resolve and content matches documented claims.
- All PowerShell scripts pass syntax validation.
- Admin role names (AI Administrator, Global Administrator) match current Entra built-in roles.
- Copilot Tuning eligibility language aligns with current Microsoft 365 admin center UX.
- Regulatory citations (GLBA 501(b), OCC 2011-12, SR 11-7, Interagency AI Guidance, EU AI Act) are accurate.
- Added `last_verified` to `config/default-config.json`.

## [v0.1.2] — 2026-05-23 — Council review remediation

### Fixed

- F04: Corrected delivery-checklist customer validation references to existing solution docs or repository-root relative docs.
- F12: Added GUID-format validation for the `TenantId` deployment parameter before deployment artifacts are written.

### Documentation tightened

- F13: Labeled `Microsoft.Graph` as optional and forward-looking because the documentation-first scripts do not use Graph cmdlets.

### Dead config

- F05: Wired `minimumLicenseThreshold` into license-check notes and the deployment manifest configuration snapshot.

## [v0.1.1] - 2026-05-04

### Changed

- Clarified that Microsoft 365 Copilot Tuning is an early access preview capability with limited customer availability and public-preview eligibility requirements.
- Replaced non-current Copilot administrator role references with AI Administrator guidance.
- Updated tuning availability, SharePoint snapshot data, and admin center governance language to align with current Microsoft Learn documentation.

## [v0.1.0]

### Added

- Initial scaffold for Copilot Tuning Governance solution
- README with overview, scope boundaries, controls, regulatory alignment, and evidence handling
- Architecture, deployment, prerequisites, evidence-export, and troubleshooting documentation
- Standard deployment, monitoring, and evidence export scripts
- Tier-aware configuration for tuning governance: disabled (baseline), approval-gated (recommended), and full model risk management (regulated)
- Pester test coverage for solution structure, configuration, and script syntax validation
- Delivery checklist tailored to Copilot Tuning governance deployment scenarios

### Notes

- All scripts use representative sample data and do not connect to live Microsoft 365 or Copilot Tuning services.
- Control statuses remain `partial` and `monitor-only` until tenant-specific integration with supported Microsoft 365 admin center or Agent 365 experiences is fully connected.
