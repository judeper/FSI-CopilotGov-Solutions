# Changelog

## [Unreleased]

### Added

- Lab validation contract `lab/03-sensitivity-label-auditor.lab.json` for lab-ready validation. The contract is read-only and detect-only (`mutations: []`), scoped to US commercial-cloud Microsoft 365, and defines setup/exercise/verify/cleanup phases, read-backs, required evidence, and Microsoft Learn source claims.
- Lab validation handoff sections in `docs/deployment-guide.md` and `DELIVERY-CHECKLIST.md`.
- Regression tests that assert the evidence package uses package-relative artifact paths and stays valid after relocation.

### Fixed

- `Export-Evidence.ps1` now records package-relative artifact paths so an exported evidence package still validates after it is moved to an archive or WORM store, while preserving absolute artifact paths in the caller result.
- Removed the government-only `G5` SKU from Solution 03 licensing guidance so forward-facing prerequisites match the repository's US commercial-cloud scope.

### Changed

- Registered the solution 03 lab contract in the shared `scripts/test_lab_validation_contracts.py` default-discovery test.
- Re-verified Microsoft currency against Microsoft Learn as of 2026-07-13: `driveItem: extractSensitivityLabels` and `assignSensitivityLabel` remain v1.0 GA (assign is protected and metered, Global service only), organization label-definition enumeration via `/security/informationProtection/sensitivityLabels` remains beta, the service-side auto-labeling cap of 100,000 files/day per organization and lower-priority override behavior are current, and Purview roles/role groups and label-group migration guidance are unchanged. Updated the README "Last Verified" date.

## [v0.2.4] — 2026-06-05 — MS Learn accuracy pass-2 correction

### Fixed

- Removed unverifiable historical parenthetical "(previously only emails)" from the auto-labeling label-override statement in README.md. Current MS Learn documentation shows no email-only restriction for service-side auto-labeling policy label overrides; the operative guidance is preserved.



### Fixed

- Corrected auto-labeling throughput cap from "per policy" to "per tenant" in 4 locations (README.md, docs/architecture.md, docs/deployment-guide.md) per MS Learn source of truth.
- Added metered/billable API note for `assignSensitivityLabel` in README.md and docs/troubleshooting.md; bulk remediation cost planning requires metered API enablement.

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
