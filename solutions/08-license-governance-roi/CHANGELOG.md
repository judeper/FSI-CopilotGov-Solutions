# Changelog

## [Unreleased]

### Fixed

- Reverted the stale beta-only Copilot usage-report routes back to the generally available Microsoft Graph `v1.0` endpoint. `getMicrosoft365CopilotUsageUserDetail` and `getMicrosoft365CopilotUserCountSummary` are documented on Microsoft Learn under `GET https://graph.microsoft.com/v1.0/copilot/reports/...` (verified 2026-07-14); the v0.1.4 change that moved these to `/beta/copilot/reports/` was a regression. Restored `/v1.0/copilot/reports/...` in `scripts/Monitor-Compliance.ps1`, `scripts/Deploy-Solution.ps1`, and `docs/architecture.md`. Clarified that the older `reportRoot` surface on `/beta/reports/` remains preview-only, that both functions require `Reports.Read.All` plus a role such as Reports Reader, and that usage-report user/display names may be concealed (hashed) when the tenant anonymization setting is enabled.
- Reconciled internal version drift: aligned `config/default-config.json`, `DELIVERY-CHECKLIST.md`, and the generated `solutions.json` / `solutions-graph.json` entries to the already released version `v0.1.4` (they were `v0.1.3`); no new release is introduced.
- Removed unverifiable and volatile Copilot Studio pricing precision from forward-facing docs. Deleted the specific `$0.01 per Copilot Credit` rate and the partial per-interaction credit-cost table from `README.md` and `docs/architecture.md`. Retained the verified prepaid capacity-pack quantity (25,000 Copilot Credits per month per pack), clarified that per-interaction credit consumption varies by interaction type, noted that employee-facing agent usage is generally included at no additional charge for Microsoft 365 Copilot-licensed users, and pointed operators to Microsoft's current pay-as-you-go meters and Copilot Studio billing-rates documentation for authoritative rates.
- Marked all remaining dollar-valued ROI/recovery fields as illustrative customer-provided planning assumptions, corrected sample evidence control states from implemented to partial/monitor-only, and made evidence packages portable while preserving absolute caller paths.

### Changed

- Updated `config/default-config.json` `last_verified` to `2026-07-14` after re-verifying license inventory, usage-report, permission, Copilot Studio credit/capacity, and Azure Cost Management budget claims against first-party Microsoft Learn documentation.

### Added

- Added a read-only, detect-only lab validation contract at `lab/08-license-governance-roi.lab.json` (`mutations: []`) covering tenant-identity confirmation, SKU/seat discovery via `/subscribedSkus`, the `v1.0/copilot/reports/` usage-report read (or a BLOCKED disposition when permission or report availability prevents it), and read-only inspection of PAYG/budget configuration. Tenant concealment is accepted as a valid report response; identity columns are removed immediately, raw files use ignored staging and are deleted fail-closed, and local staging is cleaned after evidence capture.

## [v0.1.4] - 2026-06-06

### Fixed

- Corrected the Microsoft 365 Copilot usage report endpoint references from `https://graph.microsoft.com/v1.0/copilot/reports/...` to `https://graph.microsoft.com/beta/copilot/reports/...` in `docs/architecture.md`, `scripts/Deploy-Solution.ps1`, and `scripts/Monitor-Compliance.ps1`. Live verification on Microsoft Learn confirms that `getMicrosoft365CopilotUsageUserDetail` and `getMicrosoft365CopilotUserCountSummary` are currently available only under the Microsoft Graph `beta` (preview) endpoint and are not yet generally available under `v1.0`. This supersedes the 2026-05-04 / 2026-05-25 entries that recorded the `/v1.0/copilot/reports` paths as "current." Added a note to `docs/architecture.md` clarifying the beta/preview status and the recommended `/copilot/reports/` going-forward path.

## [v0.1.3] - 2026-06-05

### Fixed

- Corrected Copilot Studio billing unit from "message meter / $0.01 per message" to "pay-as-you-go meter / $0.01 per Copilot Credit" in README.md and docs/architecture.md per MS Learn effective September 1, 2025. Rate ($0.01) unchanged; unit name updated. Added per-interaction credit costs (1 credit for classic answer, 2 credits for generative answer) to architecture.md billing section.
- Updated pass-1 CHANGELOG entry that described the old "$0.01-per-message" unit to reflect the corrected terminology.



### Fixed

- Corrected consumption-billing terminology: standardized on "Copilot Credits" and "Copilot Studio capacity packs" (25,000 credits/month/pack) per current Microsoft Learn documentation; removed outdated "message packs" / "25,000-message packs" phrasing.
- Corrected consumption-billing unit: "$0.01 per message" (Copilot Studio message meter) is now "$0.01 per Copilot Credit" (Copilot Studio pay-as-you-go meter) per Microsoft Learn effective September 1, 2025.
- Broadened billing policy scope language from "security groups" only to "security groups, distribution groups, or the entire tenant" per Microsoft Learn.
- Renamed config keys: `messagePacksEnabled` → `capacityPacksEnabled`, `highUsageThresholdMessagesPerDay` → `highUsageThresholdCreditsPerDay`, `billingPolicyScopeType` value updated to reflect broader scope options.
- Resolved internal README inconsistency between "credits" (scope boundaries) and "messages" (overview) — standardized on "Copilot Credits."

## [v0.1.1] - 2026-05-04

## Validation Sweep — 2026-05-25

### Verified

- All PowerShell scripts pass syntax validation.
- Microsoft Graph endpoints (`/v1.0/subscribedSkus`, `/v1.0/copilot/reports/getMicrosoft365CopilotUsageUserDetail`, `/v1.0/copilot/reports/getMicrosoft365CopilotUserCountSummary`) confirmed current.
- Graph permission `LicenseAssignment.Read.All` confirmed current and non-deprecated.
- Power BI Pro/Premium Per User licensing requirements confirmed current.
- Regulatory citations (OCC 2011-12, SOX 404, GLBA 501(b)) are accurate.
- PAYG consumption pricing of $0.01 per message (Copilot Studio message meter) and prepaid Copilot Studio capacity packs confirmed current.
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
