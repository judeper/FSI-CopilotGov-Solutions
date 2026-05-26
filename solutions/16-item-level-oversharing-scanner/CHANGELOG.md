# Changelog

## [Unreleased]

### Validation sweep — 2026-05-25

- Verified PnP PowerShell cmdlets (`Connect-PnPOnline`, `Get-PnPSite`, `Get-PnPList`, `Get-PnPListItem`) are current and not deprecated.
- Verified PnP.PowerShell v3.x prerequisite note (PS 7.4+, .NET 8.0, own app registration since Sept 2024) is accurate.
- Verified Microsoft Graph API permissions (`Files.Read.All`, `Sites.Read.All`) are current for the documented endpoints.
- Verified SharePoint Advanced Management and DSPM terminology is current.
- Verified cross-solution reference to 02-oversharing-risk-assessment is valid.
- Verified script parameter names and shared module imports match implementation.
- No corrections required; all content verified accurate as of 2026-05-25.

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
