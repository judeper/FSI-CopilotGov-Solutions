# Changelog

## [Unreleased]

### Added

- Lab-validation contract `lab/11-risk-tiered-rollout.lab.json` for the external lab executor. The first cycle is read-only/detect-only (`mutations: []`): verifies tenant identity, discovers the Microsoft 365 Copilot SKU from `GET /subscribedSkus` by `skuPartNumber`, reads test cohort group metadata and current `assignedLicenses`, and confirms documentation source claims. Disposable license assignment is deferred until safe prior-state capture and ownership can be enforced.
- `Deploy-Solution.ps1` `-ConfirmAssignmentIntentStaging` switch and `-ReadinessArtifactPath` override. `-TriggerLicenseAssignment` previews only; staged intents always require explicit confirmation. Regression tests added.
- Portable evidence export now stores package-relative artifact paths, preserves absolute caller paths, and resolves relative output from the current PowerShell provider location.

### Changed

- Documented tenant Microsoft 365 Copilot SKU discovery via `GET /subscribedSkus` (match `skuPartNumber` `Microsoft_365_Copilot`; legacy `M365_Copilot`), distinguishing product display name, `skuPartNumber`, and tenant `skuId`; no SKU GUID is hardcoded. Added least-privileged `LicenseAssignment.Read.All` for SKU/assignment reads.
- Tightened rollback guidance: capture prior direct-vs-inherited assignment state and ownership before removal; inherited (group) licenses are removed only at the group scope; documented group-based licensing error classes and the nested-group limitation.
- Emitted wave manifest now records the dry-run posture and `skuIdSource: tenant-subscribedSkus-discovery` with a resolution note.
- Scoped lab group/user reads to the approved disposable cohort, removed the write-capable License Administrator role from the read-only cycle, and treated tenant-wide `consumedUnits` only as corroborating evidence because concurrent licensing activity can change it.

## v0.1.3 — 2026-06-05 — Documentation/branding corrections

### Fixed

- Corrected non-Microsoft "Copilot Chat Basic vs Premium" phrasing to "Microsoft 365 Copilot Chat (free) vs Microsoft 365 Copilot (paid)" per current Microsoft branding.
- Broadened narrow "E3 or E5" base-license statement to include all qualifying bases (E3/E5, Business Standard/Premium, Office 365 E3/E5) per Microsoft 365 Copilot feature-availability documentation.

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
