# Changelog

## [Unreleased]

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
