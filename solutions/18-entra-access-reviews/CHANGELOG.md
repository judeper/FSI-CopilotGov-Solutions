# Changelog

All notable changes to this solution are documented in this file.

The format is based on Keep a Changelog and uses solution version tags instead of package release tags.

## [v0.1.1] - 2026-05-04

### Fixed

- Corrected Microsoft Entra access review scope language to focus on groups and access packages associated with SharePoint access.
- Updated licensing and administrator role prerequisites to match current Microsoft Learn terminology.
- Corrected the access review applyDecisions endpoint and monthly recurrence pattern.
- Replaced legacy identity-brand parameter help text with Microsoft Entra ID branding.

## [v0.1.0]

### Added

- Initial scaffold for Entra Access Reviews Automation solution
- README with overview, scope boundaries, controls, regulatory alignment, and evidence handling
- Architecture, deployment, prerequisites, evidence-export, and troubleshooting documentation
- Risk-triaged access review creation script (New-AccessReview.ps1) with Graph API patterns
- Review results collection script (Get-ReviewResults.ps1) with expiry monitoring
- Decision application script (Apply-ReviewDecisions.ps1) with evidence logging
- Orchestrator script (Invoke-RiskTriagedReviews.ps1) for end-to-end review lifecycle
- Standard deployment, monitoring, and evidence export scripts
- Tier-aware configuration for review cadence, reviewer mapping, and evidence retention
- Pester test coverage for solution structure, configuration, and script syntax validation
- Delivery checklist tailored to access review deployment scenarios

### Notes

- All scripts use representative sample data and do not connect to live Microsoft Entra ID or Microsoft Graph services.
- Control statuses remain `partial` and `monitor-only` until tenant-specific API integration is fully connected.
