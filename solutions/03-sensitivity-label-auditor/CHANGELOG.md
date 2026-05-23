# Changelog

## [v0.2.2] — 2026-05-23 — Council review remediation

### VERIFIED-BUG

- Normalized missing upstream dependency paths in deployment output to absolute paths.
- Removed unused `PnP.PowerShell` from the required prerequisites list.
- Documented the regulated tier `maxItemsPerScan: -1` convention as no configured per-workload cap.

### VERIFIED-VERSION-DRIFT

- Documented configured regulatory mappings for SEC 17a-3, SEC Reg S-P, SOX 302/404, and FFIEC IT Handbook.
- Aligned README, delivery checklist, and default configuration version metadata to v0.2.2.

## [v0.2.1] - 2026-05-04

- Corrected Microsoft Graph sensitivity label API versioning, protected API prerequisites, current licensing and role terminology, and Exchange collection caveats for accuracy-review findings.
- Updated deployment and monitoring stubs to distinguish v1.0 drive item actions from beta label definition enumeration and document supported SharePoint and OneDrive extraction patterns.

## v0.2.0

- Replaced scaffold documentation with solution-specific guidance for sensitivity label coverage monitoring in SharePoint, OneDrive, and Exchange.
- Added tier-aware configuration for workload scope, coverage thresholds, label taxonomy, remediation limits, and regulated retention.
- Rebuilt deployment, monitoring, and evidence export PowerShell stubs to support taxonomy snapshots, gap analysis, and SHA-256 packaged evidence.
- Expanded Pester coverage to validate documentation, configuration content, dependency declarations, evidence types, and script syntax.

## v0.1.0

- Added the initial scaffold for Sensitivity Label Coverage Auditor.
