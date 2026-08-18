# Changelog

All notable changes to this solution are documented in this file.

The format is based on Keep a Changelog, and this project follows semantic versioning.

## [Unreleased]

### Verified
- Re-verified all Microsoft product and feature claims against current Microsoft Learn sources on 2026-08-16 (issue #440); no technical drift found, so the solution version is unchanged and only the README Last Verified date was refreshed. Confirmed the Copilot audit event names (`CopilotInteraction`, `ConnectedAIAppInteraction`, `AIAppInteraction`), Audit (Standard) and Audit (Premium) tiers and their default retention, audit record availability guidance (typically 60-90 minutes for core services), the unified Microsoft Purview eDiscovery experience, the retention policy cmdlets, the audit and eDiscovery roles, the Microsoft Graph `AuditLogsQuery.Read.All` and service-specific `AuditLogsQuery-*.Read.All` permissions, and the Microsoft 365 E5 / Microsoft Purview Suite / Microsoft 365 E5 eDiscovery and Audit add-on licensing.

## [v0.2.3] — 2026-06-05 — MS Learn accuracy fix

### Fixed
- Renamed deprecated "Microsoft Purview compliance portal" / "the compliance portal" to "Microsoft Purview portal" per current Microsoft Learn branding (https://learn.microsoft.com/purview/audit-get-started).

## [v0.2.2] — 2026-05-23 — Council review remediation

### Fixed
- F-05: Derived the evidence package overall status from all ATM control statuses instead of only retention gap count.
- F-11: Documented the PowerShell 7.0+ runtime prerequisite to match script `#Requires -Version 7.0` declarations.

## [v0.2.1] - 2026-05-04

### Changed
- Updated audit event naming to use `CopilotInteraction` and `FileAccessed`, with `ConnectedAIAppInteraction` or `AIAppInteraction` noted only for custom or third-party AI app scopes.
- Updated Microsoft Purview Audit tier, licensing, audit role, Graph Audit Search permission, retention policy cmdlet, Copilot retention location, and audit latency terminology based on Microsoft Learn references.

## [v0.2.0] - 2026-03-07

### Added
- Detailed README with regulatory context, deployment workflow, monitoring guidance, and limitations.
- Detailed architecture, deployment, prerequisite, evidence export, and troubleshooting documentation.
- ATM-specific baseline, recommended, and regulated configuration files with retention, audit, and Microsoft Purview eDiscovery settings.
- PowerShell implementations for deployment manifest generation, compliance monitoring, and evidence export.
- Pester coverage for configuration, documentation, script presence, syntax validation, and content assertions.

### Changed
- Replaced the initial scaffold content with solution-specific material for Copilot interaction audit retention and evidence packaging.
- Expanded evidence handling to include audit-log-completeness, retention-policy-state, and ediscovery-readiness-package outputs.

## [v0.1.0] - 2025-11-15

### Added
- Initial repository scaffold for Solution 06 with placeholder documentation, scripts, configuration, and tests.
