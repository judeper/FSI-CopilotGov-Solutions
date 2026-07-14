# Changelog

## [Unreleased]

### Fixed

- Downgraded overstated evidence control statuses from `implemented` to `partial` in `scripts/Export-Evidence.ps1`. All seven controls (2.6, 4.1, 4.2, 4.3, 4.4, 4.12, 4.13) now report `partial` with notes clarifying that the exported evidence is representative sample data derived from tier templates, not live tenant collection. Added `runtimeMode`/`dataSourceMode` package metadata markers and a `statusSemantics` summary note so reviewers do not treat sample control states as proof of live enforcement.
- Made the evidence package portable: artifact references now use package-relative file names (absolute paths are returned only to the caller), and the output path resolves via the PowerShell provider location (`Resolve-Path`) so the package validates after relocation and no longer embeds local filesystem paths.
- `scripts/Monitor-Compliance.ps1` no longer reports a zero-drift stub result as `implemented`; a representative-sample current-state collection is reported as `partial`, and the result now carries `RuntimeMode`/`DataSourceMode` markers.

### Changed

- Updated `config/default-config.json` `last_verified` to `2026-07-14` after re-verifying Copilot Control System routes, web-search control surfaces, Teams Copilot policy cmdlets/values, admin roles, and Graph-API scope against first-party Microsoft Learn documentation.
- Documentation currency: distinguished the Cloud Policy `Allow web search in Copilot` on/off toggle (Microsoft 365 Apps admin center) from the Microsoft Purview DLP `Performing Web Searches` content-triggered action (governed by solution 05); documented the exact Teams Copilot policy cmdlets and values (`Set-CsTeamsMeetingPolicy -Copilot` and `Set-CsTeamsCallingPolicy -Copilot`); clarified the Microsoft Agent 365 / converged agent registry / Entra Agent ID boundary (Agent 365 generally available for commercial tenants since 2026-05-01); noted the AI Administrator least-privilege deployment role and PIM; and recorded that no documented Microsoft Graph API for Copilot feature or admin settings was identified as of 2026-07-14.
- Added Teams Copilot `policyCmdlets` reference metadata and a Purview DLP web-search boundary note to `config/default-config.json`.

### Added

- Read-only, detect-only lab validation contract at `lab/09-feature-management-controller.lab.json` (`mutations: []`) covering tenant-identity confirmation, Copilot Control System settings inspection, the Cloud Policy versus Purview DLP web-search boundary, supported-cmdlet reads of Teams meeting and calling Copilot policy, Microsoft Agent 365 / agent-registry availability inspection (classified out of scope for this feature-policy solution), and offline sample-script runs. No setting, policy, ring, agent, or license is changed.
- Regression tests in `tests/09-feature-management-controller.Tests.ps1` covering evidence-package portability (package-relative artifact paths, absolute caller paths, relocation validity), the honest `partial` control statuses, runtime markers, and documentation currency (Teams cmdlets, web-search boundary, Agent 365 boundary, and absence of an invented Copilot feature-management Graph endpoint).

## v0.1.3 — 2026-06-05 — Microsoft accuracy fixes

### Fixed

- Corrected Copilot Control System location from non-existent "Adoption Hub" to Microsoft 365 admin center > Copilot (per MS Learn citation).
- Removed unverifiable "Baseline Security Mode (BSM)" product name from scope-exclusion; rephrased as generic baseline security posture exclusion.

## Validation Sweep — 2026-05-25

### Verified

- All PowerShell scripts pass syntax validation.
- Cloud Policy service `Allow web search in Copilot` policy confirmed as current admin surface.
- Regulatory citations (SEC Reg FD, FINRA 3110) are accurate.
- Microsoft Graph `featureRolloutPolicies` correctly documented as out of scope for Copilot feature management.
- Ring definitions (Preview Ring, Early Adopters, General Availability, Restricted) align with documented admin patterns.
- Added `last_verified` to `config/default-config.json`.

### Fixed

- Corrected admin role name from "Copilot Administrator" to "AI Administrator" in README.md, `docs/deployment-guide.md`, and `docs/prerequisites.md`.

## v0.1.2 — 2026-05-23 — Council review remediation

### Fixed

- [13] Added Pester coverage for matching, mismatched, and missing SHA-256 baseline companion files.
- [22] Updated the delivery validation path to monitor the generated `feature-state-baseline.json` artifact instead of a raw tier config.
- [9] Corrected the `Monitor-Compliance.ps1` help example to use the generated feature-state baseline artifact.
- [14] Added `Get-PowerAutomateFlowPlan` coverage for `-BaselineOnly` ring-promotion deferral.
- [7] Passed configured FMC evidence output names into shared evidence package completeness validation.

### Documentation tightened

- [19] Softened control 4.3 and 4.4 README support language so Teams Phone/Queues and Viva Suite coverage is described as an extension pattern until tenant-specific feature metadata is added.

### Dead config

- [15] Aligned rollout ring schemas and merged default ring state/audience metadata into tier rollout plans.

### Version drift

- None; no VERIFIED-VERSION-DRIFT findings were included in this remediation brief.

## [v0.1.1] - 2026-05-04

- Corrected Copilot feature source guidance to remove Microsoft Graph featureRolloutPolicies from FMC inventory and rollout planning.
- Reframed web grounding governance around the documented `Allow web search in Copilot` Cloud Policy control, with domain and source lists treated as customer-defined planning metadata.
- Updated Teams and Power Platform source labels to distinguish documented Teams meeting/event controls, Teams chat inventory limitations, and Power Automate tenant-level support.
- Bumped documentation-first solution metadata from v0.1.0 to v0.1.1.

## v0.1.0

- Replaced shallow scaffold text with solution-specific guidance for Copilot feature governance in financial services environments.
- Added deployment, architecture, prerequisites, evidence, and troubleshooting documentation for feature inventory, rollout rings, and drift monitoring.
- Upgraded PowerShell scripts with structured deployment and monitoring stubs, baseline capture logic, and realistic evidence export notes.
- Expanded configuration profiles and Pester coverage for rollout rings, drift thresholds, retention, and script contract validation.
