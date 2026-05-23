# Changelog

All notable changes to this solution are documented in this file.

The format is based on Keep a Changelog and uses solution version tags instead of package release tags.

## v0.1.2 — 2026-05-23 — Council review remediation

### Fixed

- Finding 1: Added `ConfigurationTier` passthrough in the orchestrator so evidence export uses the selected tier instead of hardcoded baseline.
- Finding 4: Added `ShouldProcess` confirmation support before posting live `applyDecisions` requests.
- Finding 5: Replaced the fallback reviewer role label with a sample resolvable UPN in `review-schedule.json`.
- Finding 12: Mapped non-deny and unknown review decisions to `no-action` or `unsupported-decision` instead of `maintain-access`.
- Finding 13: Carried `siteUrl` into applied-action evidence from review definition mappings or live definition metadata.

### Documentation tightened

- Finding 10: Clarified that `reminderDays` is reference metadata until scheduling is wired to tenant automation.
- Finding 11: Removed `PnP.PowerShell` from required modules and marked it optional for future SharePoint owner-resolution work.
- Finding 16: Updated the orchestrator description to state that review creation follows HIGH, MEDIUM, then LOW risk order.

### Dead config

- Finding 2: Marked `reviewer-mapping.json` as a non-runtime reference template until tenant role-to-user resolution is added.
- Finding 8: Wired selected tier `maxSitesPerRun` into review creation and added an override parameter.
- Finding 14: Reported regulated-tier attestation and examiner-ready evidence flags in the deployment manifest as manual checks.

### Version drift

- None; no verified version-drift finding was included in the remediation brief.

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
