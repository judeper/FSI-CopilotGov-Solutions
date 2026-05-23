# Changelog

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
