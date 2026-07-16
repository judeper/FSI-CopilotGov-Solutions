# Changelog

All notable changes to this solution are documented in this file.

The format is based on Keep a Changelog and uses solution version tags instead of package release tags.

## [Unreleased]

## [v0.2.5] — 2026-07-16 — Current-source review and accepted lab validation

### Changed

- Updated Restricted SharePoint Search guidance across solution 02 to legacy transition posture only and documented retirement with new enablement blocked starting 2026-07-31.
- Added Restricted Content Discovery planning posture across docs, config, and deployment manifest output as the go-forward discoverability control.
- Updated SharePoint Advanced Management prerequisite language to include Microsoft 365 E7 entitlement path where supported and clarified role boundaries for SharePoint/SAM versus Purview/DSPM tasks.
- Added `lab\02-oversharing-risk-assessment.lab.json` and integrated lab contract handoff references in README, deployment guide, and delivery checklist.

### Fixed

- `Monitor-Compliance.ps1` sensitivity-label sample coverage now uses the supplied `ScannedSites` count and only uses a seven-site fallback when `ScannedSites` is not supplied.
- `Deploy-Solution.ps1 -WhatIf` now returns a preview dependency result with warning output when upstream solution 01 artifacts are missing; non-WhatIf deployment remains blocking.
- `Export-Evidence.ps1` now generates owner-attestation records automatically for regulated tier exports with `requireOwnerAttestation: true`.
- Evidence package artifact paths are now package-relative filenames while `PackagePath` in script output remains absolute.

### Validated

- Rechecked all five first-party Microsoft source claims on 2026-07-16; each remained unchanged.
- Accepted read-only lab result: `PASS`, `accepted: true`, `controlImplementation: implemented`, 8/8 steps PASS, cleanup `not-required`, no tenant mutation.
- Restricted Content Discovery control surface was authenticated but not exposed (`observedAvailability: false`), recorded as an honest availability read-back.
- Graph `GET /v1.0/sites/root` succeeded with delegated `Sites.Read.All`; response body, token, site identifiers, and tenant identifiers were not retained.
- Both authoritative validators passed (`validate-lab-result.py` and `validate-lab-package.ps1`).
- Result SHA-256: `19240ff458f97fa3b78c299c86a9b27bba57cf506fcf75fe18f578fbeb750bda`.
- Portable evidence package SHA-256: `51700b6478e4e6787d70de9016835c5fee0a3408e6599e11735c91ac7d83b197`.
- Studio companion PR [#16](https://github.com/judep_microsoft/studio-video-factory/pull/16) merged as `b608bce686cc2efcb92e3440dc91ec987095399d`; accepted PR record: https://github.com/judeper/FSI-CopilotGov-Solutions/pull/319#issuecomment-4987169791.

## [v0.2.4] - 2026-06-07

### Fixed

- `Invoke-GraphWithRetry` in `scripts/Monitor-Compliance.ps1` now retries on the transient HTTP `423 Locked` and `503 Service Unavailable` responses in addition to `429`. The scanner calls the `driveItem: extractSensitivityLabels` action, which Microsoft Learn documents can return `423 Locked` when the target file is in use by another process — a transient condition that should be retried rather than thrown. This also aligns the wrapper with the shared `Invoke-CopilotGovGraphRequest` helper, which already retries `429`/`503`. Citation: https://learn.microsoft.com/graph/api/driveitem-extractsensitivitylabels

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
