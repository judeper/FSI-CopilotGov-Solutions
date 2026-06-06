# Changelog

All notable changes to this solution are documented in this file.

The format is based on Keep a Changelog and uses solution version tags instead of package release tags.

## [Unreleased]

## v0.1.5 — 2026-06-06 — SecureString hardening (Issue #221, Stage 1)

### Security

- Converted `[string]$ClientSecret` parameters to `[System.Security.SecureString]$ClientSecret` across all four sol-18 scripts: `Apply-ReviewDecisions.ps1`, `Get-ReviewResults.ps1`, `Invoke-RiskTriagedReviews.ps1`, `New-AccessReview.ps1`. Each site carries the IDENTITY-STANDARD marker comment. The SecureString flows through to `scripts/common/GraphAuth.psm1` (shared module) which converts to plaintext only at the token request body — no logging.
- Updated `.PARAMETER ClientSecret` help text in all four scripts.
- Replaced `[string]::IsNullOrWhiteSpace($ClientSecret)` checks with `$null -ne $ClientSecret` where applicable.
- Stage 3 audit workflow tracked as follow-up (CI workflow not added in this commit).



### Fixed

- Replaced outdated "Enterprise Mobility + Security (EMS) E5" licensing reference in docs/prerequisites.md with current MS Learn licensing statement: "Microsoft Entra ID Governance, Microsoft Entra Suite, or Microsoft Entra ID P2". EMS E5 is not listed as a current named licensing option in the access reviews documentation.



### Changed

- Corrected feature branding: "Microsoft Entra ID Access Reviews" → "access reviews in Microsoft Entra ID Governance" per Microsoft Learn canonical naming (README, architecture, scripts).

### Validation sweep — 2026-05-25

- Verified Microsoft Graph Access Reviews API (`/identityGovernance/accessReviews/definitions`) is current in v1.0.
- Verified `AccessReview.ReadWrite.All` permission is current for access review creation and management.
- Verified `applyDecisions` endpoint path and monthly recurrence pattern structure are current per API reference.
- Verified licensing requirements: Microsoft Entra ID Governance, Microsoft Entra Suite, or Microsoft Entra ID P2 for supported scenarios.
- Verified admin roles (Identity Governance Administrator, User Administrator) are current per Microsoft Learn.
- Verified cross-solution reference to 02-oversharing-risk-assessment is valid.
- Verified script parameter names and shared module imports match implementation.
- No corrections required; all content verified accurate as of 2026-05-25.

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
