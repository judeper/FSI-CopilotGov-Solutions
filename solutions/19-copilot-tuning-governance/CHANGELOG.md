# Changelog

All notable changes to this solution are documented in this file.

The format is based on Keep a Changelog and uses solution version tags instead of package release tags.

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
