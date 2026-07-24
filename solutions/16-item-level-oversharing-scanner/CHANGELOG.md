# Changelog

## [Unreleased]

### Changed

- Updated RSS/RCD guidance across README, prerequisites, deployment, troubleshooting, evidence export, checklist, and export script notes to align with Microsoft Learn: RSS retirement with new enablement blocked starting 2026-07-31, and RCD as the site-level discoverability control.
- Tightened SAM entitlement and role guidance to align with current Learn prerequisites: qualifying base subscription plus Copilot or SharePoint Advanced Management Plan 1 (and Microsoft 365 E7 where applicable), with SharePoint Administrator or SharePoint Advanced Management Administrator roles separated from Purview roles.
- Updated runtime wording to state that PowerShell 7.4 runtime is available in Azure Automation while keeping PnP module/app-registration compatibility project-documented and lab-validated.
- Added explicit Microsoft Graph `driveItem` permissions visibility limitation guidance for owner/non-owner callers while retaining least-privilege `Files.Read.All` application-permission guidance.

### Fixed

- Enforced `autoRemediationEnabled` as a global kill switch in `Invoke-BulkRemediation.ps1`; false or absent now forces approval-gate behavior for every tier.
- Preserved HIGH-risk approval requirements even when tier policy requests auto-remediation; added defensive AnyoneLink-to-HIGH enforcement for remediation routing.
- Added `SupportsShouldProcess` with high impact and `-WhatIf` behavior so auto-remediate branches report planned-no-change without mutation.
- Updated evidence package artifact entries to use package-relative paths while preserving an absolute returned `PackagePath` from `Export-Evidence.ps1`.

### Added

- Added `solutions/16-item-level-oversharing-scanner/lab/16-item-level-oversharing-scanner.lab.json` as a template/read-only/detect-only lab-validation contract with source-verified RSS/RCD/SAM/Graph claims and blocked-condition guidance.
- Added lab handoff guidance to solution README, deployment guide, and delivery checklist.

### Tests

- Expanded solution 16 Pester coverage with behavioral tests for AnyoneLink risk-tier override, global kill switch enforcement, mandatory HIGH approval routing, `-WhatIf` no-mutation behavior, and evidence hash/package round-trip validation.
- Updated Python lab-validator tests to assert real repository lab-contract discovery now that solution 16 ships a contract file.

## [v0.1.3] — 2026-06-05 — Microsoft Learn accuracy fixes

### Fixed

- Corrected Restricted SharePoint Search (RSS) description from "site-scoped" to "tenant-level control with a site allow-list" per Microsoft Learn documentation.

### Reviewed (no change)

- `OrgLink` vs `OrgLinkEdit` token inconsistency: confirmed intentional — `Export-OversharedItems.ps1` explicitly maps `OrgLink` → `OrgLinkEdit` for risk scoring. Sample data uses SharePoint's link-type name; scoring config uses the risk-category label.

## [v0.1.2] — 2026-05-23 — Council review remediation

### Fixed

- F3: Updated evidence export to package existing scan, scored, and remediation artifacts by default, with `-RunFreshMonitor` as an explicit opt-in for a run-specific monitor pass.
- F10: Made `TenantUrl` optional in sample-data scan and remediation scripts until tenant-specific PnP connection code uses it.
- F4: Narrowed content-category matching to item/library metadata instead of matching site URL path segments.
- F6: Logged unsupported remediation modes as skipped records instead of silently dropping them.
- F8: Sorted remediation evidence actions by numeric `WeightedScore` values after CSV import.
- F18: Removed fixed-year sample filenames so generated sample paths do not drift from dynamic dates.

### Documentation tightened

- F13: Removed the README statement that control 1.14 is listed in metadata for this scaffold.
- F14: Documented the BroadGroup-with-sensitive-label MEDIUM floor and threshold-based risk tiering.
- F15: Changed Microsoft.Graph from required to optional and implementation-dependent for the current scaffold.

### Dead config

- F1: Wired configured `riskThresholds` into weighted-score tier assignment.
- F7: Applied `maxSitesPerRun` in monitoring and passed `maxItemsPerLibrary` into the scan implementation, including `-1` unlimited handling.
- F11: Read `scanWorkloads` during monitoring and warn when OneDrive is configured as a roadmap-only workload in this documentation-first scaffold.

### Version drift

- None; no VERIFIED-VERSION-DRIFT findings were identified.

## [v0.1.1] - 2026-05-04

### Changed

- Clarified Restricted SharePoint Search and Restricted Content Discovery caveats for item-level oversharing evidence.
- Updated DSPM prerequisites to identify Microsoft Purview Data Security Posture Management as the current experience and DSPM for AI as classic.
- Separated SharePoint site collection access, Purview roles, and Microsoft Graph permission guidance for item-level permission enumeration.

## [v0.1.0] - 2026-03-17

### Added

- Initial scaffold for item-level oversharing scanner
- Get-ItemLevelPermissions.ps1 for PnP-based item permission enumeration
- Export-OversharedItems.ps1 for FSI risk scoring
- Invoke-BulkRemediation.ps1 for approval-gated remediation
- Risk threshold and remediation policy configuration files
