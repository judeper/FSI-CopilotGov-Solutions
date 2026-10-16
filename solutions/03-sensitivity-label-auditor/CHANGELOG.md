# Changelog

## [Unreleased]

### Technical re-verification - 2026-10-15

- Re-checked the README's Microsoft product claims against live Microsoft Learn and refreshed Last Verified without changing the released version or regulatory mappings.
- Updated remediation planning to the dedicated auto-labeling article's currently documented 500,000-files-per-tenant daily ceiling, explicitly recording the conflicting 100,000 reference in SharePoint/OneDrive PDF guidance.
- Distinguished label classification from encryption, access restriction, and actual Copilot exposure; documented unknown/error collection cases and extraction metadata-refresh behavior.
- Clarified beta label-definition route permissions, unsupported production use, feature-specific licensing, and non-mutating taxonomy review.
- Propagated the review into implementation, troubleshooting, checklist, and evidence guidance; retained protected and metered assignment prerequisites verified against current sources.

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
