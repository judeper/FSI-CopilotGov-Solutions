# Changelog

## [Unreleased]

### Validation sweep — 2026-05-25

- Verified Copilot Pages file extension (`.page`) and Copilot Notebooks file extension (`.pod`) against Microsoft Learn compliance summary.
- Verified SharePoint Embedded container storage model and shared container with Loop My workspace is current.
- Verified Purview retention policies via "All SharePoint Sites" enforcement is current.
- Verified eDiscovery support and full-text search limitation for `.page` files in review sets is current.
- Verified legal hold manual container addition per user is current.
- Verified retention labels limited manual support status is current.
- Verified Information Barriers not supported for SharePoint Embedded is current.
- Verified regulatory citations (SEC 17a-4, FINRA 4511, SOX 404) are correct.
- Verified cross-solution reference to 06-audit-trail-manager is valid.
- Added no end-user recycle bin for Copilot Notebooks to architecture platform limitations per current Microsoft Learn guidance.
- Added sensitivity labels available for Copilot Pages only (not Copilot Notebooks) to architecture platform limitations per current Microsoft Learn guidance.
- Added DLP support with end-user policy tips to architecture platform limitations per current Microsoft Learn guidance.

## [v0.1.3] - 2026-06-05 — Microsoft Learn accuracy fixes

### Fixed
- Removed uncited `.loop` extension from Purview eDiscovery review-set full-text search limitation; Learn scopes this only to `.page` files.
- Removed uncited `.loop` extension from "All SharePoint Sites" retention policy scope statement; Learn scopes this only to Copilot Pages and Copilot Notebooks.

## [v0.1.2] - 2026-05-23 — Council review remediation

### VERIFIED-BUG
- Standardized per-gap regulation metadata on `affectedRegulation` across deployment, monitoring, and evidence outputs.
- Added `SupportsShouldProcess` handling to the compliance monitor file write path for `-WhatIf` previews.
- Simplified redundant compensating-control status logic without changing the resulting status model.

### VERIFIED-DEAD-CONFIG
- Wired configured regulatory `framework_ids` into generated manifest, status, and evidence metadata.

## [v0.1.1] - 2026-05-04

### Changed
- Updated Pages and Notebooks guidance to reflect current Microsoft Learn support for SharePoint Embedded storage, Purview retention policies, eDiscovery, legal hold, retention labels, and Information Barriers limitations.
- Reframed seeded gap register and sample evidence from broad platform-update gaps to supported-but-validate checks and documented remaining limitations.
- Corrected license and Microsoft Graph permission prerequisites for Copilot Pages, Copilot Notebooks, and sensitivity-label lookup.

## v0.1.0 - 2025-01-15

### Added
- Initial solution scaffold for Copilot Pages and Notebooks Compliance Gap Monitor
- Gap discovery framework for Copilot Pages storage and retention policy validation
- Gap discovery for Notebooks (OneNote in Teams/SharePoint) Microsoft Purview eDiscovery limitations
- Compensating control registration schema: manual export procedures, enhanced audit logging, access restriction controls
- Preservation exception register aligned to SEC 17a-4 Rule 17a-4(f) electronic records requirements
- Platform capability tracker: monitors Microsoft release notes for gap closure announcements
- Deploy-Solution.ps1 with tier-aware gap register initialization
- Monitor-Compliance.ps1 with gap status assessment and compensating control validation
- Export-Evidence.ps1 with gap-findings, compensating-control-log, and preservation-exception-register
- Tiered configuration: baseline (gap documentation), recommended (+ compensating controls), regulated (+ full preservation exception register)
- Pester tests covering configuration, script syntax, and documentation content
