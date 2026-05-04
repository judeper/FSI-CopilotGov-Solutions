# Changelog

All notable changes to this solution will be documented in this file.

The format is based on Keep a Changelog and this solution uses semantic versioning.

## [v0.2.1] - 2026-05-04

### Changed

- Clarified the Microsoft 365 Copilot and Copilot Chat DLP policy location, preview and generally available capability status, prompt-upload limitation, and complementary workload DLP baseline separation.
- Updated Copilot DLP prerequisite role guidance to distinguish policy create/edit roles from read-only review roles.

## [v0.2.0]

### Added

- Detailed solution documentation for DLP policy scope, deployment, evidence, prerequisites, and troubleshooting.
- Tier-specific configuration files for baseline, recommended, and regulated Copilot DLP governance.
- PowerShell implementations for baseline creation, compliance monitoring, and evidence export.
- Meaningful Pester checks for configuration, documentation, and script validation.

### Changed

- Replaced the scaffold-only content with solution-specific operational guidance for Microsoft Purview DLP and Power Automate exception routing.
- Updated evidence handling to produce `dlp-policy-baseline`, `policy-drift-findings`, and `exception-attestations` artifacts with SHA-256 companions.

## [v0.1.0]

### Added

- Initial scaffold for Solution 05 with placeholder documentation, scripts, and configuration files.
