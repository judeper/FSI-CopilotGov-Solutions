# Changelog

All notable changes to this solution are documented in this file.

The format is based on Keep a Changelog and uses solution version tags instead of package release tags.

## [v0.1.3] — 2026-06-05 — Microsoft Learn accuracy fixes

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
