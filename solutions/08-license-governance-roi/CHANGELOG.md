# Changelog

## [v0.1.1] - 2026-05-04

## Validation Sweep — 2026-05-25

### Verified

- All PowerShell scripts pass syntax validation.
- Microsoft Graph endpoints (`/v1.0/subscribedSkus`, `/v1.0/copilot/reports/getMicrosoft365CopilotUsageUserDetail`, `/v1.0/copilot/reports/getMicrosoft365CopilotUserCountSummary`) confirmed current.
- Graph permission `LicenseAssignment.Read.All` confirmed current and non-deprecated.
- Power BI Pro/Premium Per User licensing requirements confirmed current.
- Regulatory citations (OCC 2011-12, SOX 404, GLBA 501(b)) are accurate.
- PAYG consumption pricing of $0.01 per message and prepaid message packs confirmed current.
- Added `last_verified` to `config/default-config.json`.

### Fixed

- Corrected Copilot PAYG introduction date from "April 2026" to "January 2025" in README.md and `docs/architecture.md`.

## [v0.1.1] - 2026-05-04

- Corrected Microsoft Graph Copilot report endpoint references to the current `/v1.0/copilot/reports` paths.
- Updated license inventory permission guidance to prefer least-privileged `LicenseAssignment.Read.All` for `subscribedSkus`.
- Clarified Copilot Dashboard/Viva impact availability, PAYG budget alerts, and sample-only utilization metrics.

## v0.2.0

- Added consumption-based billing governance: PAYG message metering, message pack tracking, billing policy assignment, Azure Cost Management integration, and high-usage user monitoring patterns.
- Updated README features table, scope boundaries, and overview to include consumption billing controls.
- Added consumption-based billing governance section to architecture documentation.
- Added PAYG billing policy settings to all tier configuration files.

## v0.1.0

- Replaced scaffold-only documentation with solution-specific guidance for license inventory, inactivity reviews, ROI measurement, and evidence packaging.
- Added deployment, monitoring, and evidence-export PowerShell stubs with comment-based help, tier-aware configuration loading, and structured JSON outputs.
- Expanded configuration tiers to reflect baseline, recommended, and regulated operating assumptions for inactivity thresholds, notifications, audit trail depth, and SOX 404 evidence handling.
- Added Pester coverage for documentation presence, script help, parameter contracts, and critical tier settings.
