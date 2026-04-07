# Changelog

## [Unreleased]

## v0.1.0 - 2025-01-15

### Added
- Initial solution scaffold for Copilot Pages and Notebooks Compliance Gap Monitor
- Gap discovery framework for Copilot Pages (Loop-based content) retention coverage
- Gap discovery for Notebooks (OneNote in Teams/SharePoint) Microsoft Purview eDiscovery limitations
- Compensating control registration schema: manual export procedures, enhanced audit logging, access restriction controls
- Preservation exception register aligned to SEC 17a-4 Rule 17a-4(f) electronic records requirements
- Platform capability tracker: monitors Microsoft release notes for gap closure announcements
- Deploy-Solution.ps1 with tier-aware gap register initialization
- Monitor-Compliance.ps1 with gap status assessment and compensating control validation
- Export-Evidence.ps1 with gap-findings, compensating-control-log, and preservation-exception-register
- Tiered configuration: baseline (gap documentation), recommended (+ compensating controls), regulated (+ full preservation exception register)
- Pester tests covering configuration, script syntax, and documentation content
