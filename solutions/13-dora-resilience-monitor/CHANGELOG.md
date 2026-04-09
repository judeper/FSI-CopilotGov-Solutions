# Changelog

## [Unreleased]

## v0.2.0

- Added roadmap awareness section referencing 2026 Release Wave 1 AI governance capabilities relevant to DORA monitoring.

## v0.1.0 - 2025-01-15

### Added
- Initial solution scaffold with DORA-aligned incident classification schema
- Service health monitoring for Copilot-dependent M365 services (Exchange Online, SharePoint Online, Teams, Microsoft Graph)
- Incident register structure aligned to DORA Art. 17 ICT incident taxonomy (significant/major/minor)
- Resilience test evidence collection template (annual DORA ICT resilience testing framework)
- Deploy-Solution.ps1 with tier-aware configuration deployment
- Monitor-Compliance.ps1 with health-status polling and incident severity scoring
- Export-Evidence.ps1 with service-health-log, incident-register, and resilience-test-results artifacts
- Tiered configuration: baseline (monitoring + alerting), recommended (+ incident register), regulated (+ full DORA reporting)
- Pester tests covering config presence, required fields, and script parameter validation