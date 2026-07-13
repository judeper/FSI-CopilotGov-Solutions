# Changelog

All notable changes to this solution are documented in this file.

The format is based on Keep a Changelog and uses solution version tags instead of package release tags.

## [Unreleased]

### Fixed

- Hardened `Get-ReviewResults.ps1` for empty live-result handling, stable decision shape (`siteUrl`, `riskTier`) across sample/live paths, and tier-aware escalation behavior with optional threshold override.
- Updated `Deploy-Solution.ps1` dependency checks to report truthful `not-found` / `empty` / `validated` status without throwing on fresh checkout or `-WhatIf`.
- Updated `New-AccessReview.ps1` to source `autoApplyDecisions` from selected tier config, remove invalid `defaultDecision = 'None'`, and serialize recurrence via calendar-month intervals.
- Updated `Apply-ReviewDecisions.ps1` to avoid invalid `Recommendation` mapping and skip `applyDecisions` calls for non-completed instances.
- Updated `Invoke-RiskTriagedReviews.ps1` to support `ShouldProcess`, propagate `WhatIf` safely to decision application, and suppress interactive confirmation blocks.
- Updated `Monitor-Compliance.ps1` and `Export-Evidence.ps1` to prefer emitted artifacts when available and fall back to explicit sample-data mode when not.
- Updated `Export-Evidence.ps1` evidence package artifact paths to repository-relative entries while returning an absolute `PackagePath` in command output.

### Added

- Added `solutions/18-entra-access-reviews/lab/18-entra-access-reviews.lab.json` with read-only contract flow, source-reference verification (definitions/decisions/applyDecisions reference-only), upstream dependency coverage, and blocked-prerequisite evidence rules.
- Added behavioral Pester coverage for tier-driven escalation/auto-apply behavior, WhatIf orchestration safety, monitor/export artifact-source honesty, and evidence path handling.
- Added Python contract test coverage to assert repository contract validation includes the new solution 18 lab contract.

### Documentation

- Updated README, checklist, and solution docs to use monthly/quarterly/semiannual cadence language where recurrence serializes as `absoluteMonthly`.
- Added cautious limitation notes for preview-scoped agent identity access reviews and maintained human/group scope for current implementation.
- Updated generated site docs for solution 18 to match documentation and script behavior changes.

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
