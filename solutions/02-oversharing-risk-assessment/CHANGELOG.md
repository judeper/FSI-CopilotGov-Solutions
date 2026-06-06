# Changelog

All notable changes to this solution are documented in this file.

The format is based on Keep a Changelog and uses solution version tags instead of package release tags.

## [v0.2.3] - 2026-06-06

### Security

- Converted `[string]$ClientSecret` parameter in `scripts/Monitor-Compliance.ps1` to `[System.Security.SecureString]$ClientSecret` with IDENTITY-STANDARD marker comment (Issue #221, Stage 1). The SecureString flows through to `scripts/common/GraphAuth.psm1` (shared module) which converts to plaintext only at the token request body — no logging.
- Updated `.PARAMETER ClientSecret` help text and `.EXAMPLE` to reflect SecureString usage.
- Stage 3 audit workflow tracked as follow-up (CI workflow not added in this commit).

### Changed

- Tightened SAM licensing prerequisite in `docs/prerequisites.md` to enumerate the supported base subscriptions (Microsoft 365 E1/E3/E5/A5; Office 365 E3/E5/A5; GCC/GCC High/DoD), the SharePoint K/P1/P2 sub-dependency for the SAM Plan 1 add-on path, and the restricted-site-creation note per MS Learn (Issue #101). Citation: https://learn.microsoft.com/en-us/sharepoint/sharepoint-advanced-management-prerequisites



### Fixed

- Corrected PnP.PowerShell minimum version from "PowerShell 7.2 or later" to "PowerShell 7.4.0 or later" per current PnP install docs.
- Updated Azure Automation note to reflect availability of PowerShell 7.4 runtime (GA) instead of implying PS 7.2 is the only option.
- Tightened SAM add-on name to "SharePoint Advanced Management Plan 1" (dropped incorrect "Microsoft" prefix) across README, prerequisites, deployment guide, delivery checklist, and Deploy-Solution.ps1.

## [v0.2.1] - 2026-05-04

### Changed

- Updated SharePoint Advanced Management prerequisite language to include the Microsoft 365 Copilot entitlement path and standalone license path.
- Replaced current-state DSPM for AI references with Microsoft Purview Data Security Posture Management (DSPM) guidance and classic-DSPM caveats where relevant.
- Clarified Restricted SharePoint Search limitations, sensitivity-label governance semantics, Power Platform data policy troubleshooting, and Microsoft Graph sensitivity-label extraction behavior.

## [v0.2.0] - 2026-03-07

### Added

- Detailed README content for oversharing detection, remediation, controls, regulatory alignment, and evidence handling
- Architecture, deployment, prerequisites, evidence-export, and troubleshooting documentation specific to SharePoint, OneDrive, and Teams
- Tier-aware configuration values for workload scope, risk thresholds, retention, notifications, and Restricted SharePoint Search
- Credible implementation stubs for deployment, monitoring, and evidence export workflows
- Pester coverage for solution structure, configuration expectations, script syntax, dependency references, and evidence types

### Changed

- Replaced scaffold-only language with FSI-specific oversharing guidance and realistic operational limitations
- Updated version metadata from `v0.1.0` to `v0.2.0`
- Expanded delivery checklist to include licensing, site owner communications, and remediation wave planning

### Notes

- Power Automate remains documentation-first in this release and must be implemented in the target tenant environment.
- Control statuses remain mixed across `partial` and `monitor-only` states until tenant-specific API integration and approval workflows are fully connected.

## [v0.1.0]

### Added

- Initial scaffold for documentation, scripts, configuration, and basic tests
