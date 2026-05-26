# Changelog

## Validation Sweep — 2026-05-25

### Verified

- All PowerShell scripts pass syntax validation.
- Graph permission `LicenseAssignment.ReadWrite.All` confirmed current for license assignment operations.
- Entra roles (Directory Writers, License Administrator, User Administrator, Groups Administrator) confirmed current for delegated license operations.
- Usage location requirement for license-assignment groups confirmed current.
- Wave-based rollout pattern and gate criteria documented accurately.
- Regulatory citations (OCC 2011-12, FINRA 3110, DORA) are accurate.
- Added `last_verified` to `config/default-config.json`.

## v0.1.2 — 2026-05-23 — Council review remediation

### Fixed

- F-02: Renamed the Wave 2 training gate to `analyticsFeedConfigured` so the gate reflects the configured analytics signal instead of claiming training-completion evidence.
- F-03: Added a separate `doraReviewCompleted` evidence marker so `doraGateRequired` no longer auto-passes the regulated DORA review gate.
- F-05: Split service-health and incident checks so service health reads representative service-health status and incidents read configured incident counts.
- F-06: Split remediation backlog evaluation from incident-threshold evaluation by using a dedicated backlog metric and threshold.
- F-09: Renamed the architecture note from License Assigner to Assignment Staging to match the diagram.

### Documentation tightened

- F-11: Qualified Wave 0 seat availability as a manual prerequisite outside `Monitor-Compliance.ps1` evaluation.

### Dead config

- F-07: Wired `manualReviewRequiredTiers` into deployment manifests so higher-risk tiers appear as manual-review users when excluded from a lower-tier wave.
- F-08: Wired `auditTrail.fullAuditTrailRequired` into the Wave 3 audit gate.

### Version drift

- F-10: Documented baseline-specific Wave 0 and Wave 1 sizing overrides against the canonical rollout design.
- F-12: Updated evidence-export field tables for emitted runtime, source-mode, warning, and generated timestamp fields.
- F-16: Added shared PowerShell modules to the local script dependency prerequisites.

## [v0.1.1] - 2026-05-04

- Updated license-assignment prerequisites to use least-privileged Microsoft Graph permission guidance, delegated Microsoft Entra role requirements, and Usage location preparation.
- Corrected the Microsoft 365 Copilot SKU part number in the default configuration.

## v0.1.0

- Replaced scaffold text with solution-specific guidance for risk-tiered Copilot rollout operations in financial-services environments.
- Documented architecture, deployment, prerequisites, evidence export, and troubleshooting for Tier 1, Tier 2, and Tier 3 rollout waves.
- Upgraded deployment, monitoring, and evidence-export PowerShell scripts to produce structured rollout manifests, gate checks, and evidence artifacts.
- Expanded configuration files for baseline, recommended, and regulated tiers with wave definitions, thresholds, approvals, and retention settings.
- Added meaningful Pester coverage for documentation presence, configuration integrity, script help, parameters, and syntax validation.
