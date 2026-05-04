# Changelog

All notable changes to this solution will be documented in this file.

The format is based on Keep a Changelog, and this repository uses semantic versioning for solution content.

## [v0.2.1] - 2026-05-04

### Fixed

- Replaced unverifiable individual Copilot app IDs and the Microsoft Flow Service app ID with the Microsoft Graph `Office365` Conditional Access app-suite target plus tenant-verified app-ID guidance.
- Separated named-location display labels from Graph `namedLocationIds` so generated commands do not emit display-name placeholders.
- Modeled legacy-authentication and unknown-device-state safeguards as separate block-policy templates.
- Updated Copilot licensing and Conditional Access portal guidance to align with current Microsoft Learn references.

## [0.2.0] - 2026-03-07

### Added

- Detailed solution-specific documentation for architecture, deployment, prerequisites, evidence export, and troubleshooting.
- Tier-specific configuration files for baseline, recommended, and regulated Copilot Conditional Access patterns.
- PowerShell implementations for deployment packaging, compliance monitoring, and evidence export.
- Pester checks for configuration integrity, documentation presence, script syntax, and required content.

### Changed

- Replaced generic scaffold text with Conditional Access automation guidance for Copilot.
- Updated evidence outputs to `ca-policy-state`, `drift-alert-summary`, and `access-exception-register`.
- Documented Copilot application IDs, Graph permissions, risk-tier policy patterns, and exception handling requirements.

## [0.1.0] - Initial scaffold

### Added

- Initial track B scaffold for Conditional Access Policy Automation for Copilot.
- Placeholder docs, config files, scripts, and tests aligned to the repository contract.
