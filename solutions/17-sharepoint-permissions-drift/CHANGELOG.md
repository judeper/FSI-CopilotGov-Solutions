# Changelog — SharePoint Permissions Drift Detection

All notable changes to this solution are documented in this file.

## [v0.1.4] — 2026-06-05 — MS Learn accuracy pass-2 correction

### Fixed

- Corrected SharePoint Advanced Management Data Access Governance report name in docs/architecture.md: "Permission state reports" → "Site permissions" report per current MS Learn documentation. "Sharing links report" and "EEEU" references were already correct.



### Fixed

- Corrected synthetic sharing-link label `OrganizationView` to use real Microsoft Graph sharing-link properties (`linkScope = 'organization'`, `linkType = 'view'`).
- Corrected `HasUniqueRoleAssignments` usage from `-Fields` column reference to securable-object property access pattern (it is a property, not a field-selectable column).

### Added

- Enhancement note in architecture.md grounding future tenant binding in SharePoint Advanced Management (SAM) Data Access Governance reports (Permission state, Sharing links, EEEU insights).

## [Unreleased]

### Fixed

- Hardened `Invoke-DriftScan.ps1` for StrictMode by wrapping filtered collections before `.Count`, preventing empty-category crashes.
- Added OrganizationWide drift weighting in risk scoring and aligned representative sample scoring with the active scorer.
- Updated `Monitor-Compliance.ps1` to return truthful baseline status values (`Missing`, `Stale`, `Current`, `Invalid`) and to surface `ScanFailed` with error detail when drift scans fail.
- Updated `Invoke-DriftReversion.ps1` so approval emails and file writes are gated behind `ShouldProcess`; `-WhatIf` now performs no mail or file mutations.
- Updated `Invoke-DriftReversion.ps1 -AutoRevert` handling to fail loudly when LOW/MEDIUM scopes are disabled while preserving HIGH-risk approval-gate safety.
- Updated `Deploy-Solution.ps1` to source manifest version from `config/default-config.json` (`v0.1.4`) instead of a stale hardcoded value.
- Normalized rooted artifact paths to package-relative paths in `Export-SolutionEvidencePackage` while keeping returned package file paths absolute.
- Updated `Invoke-DriftScan.ps1` to fail closed on missing risk configuration, load scoring from `config/default-config.json` (or explicit `-ConfigPath`), and apply illustrative principal-type + threshold calibration consistently across ADDED/CHANGED risk scoring.

### Added

- Added read-only lab validation contract `lab/17-sharepoint-permissions-drift.lab.json` with controls 1.2/1.4/1.6/2.5, upstream Solution 02 context, and BLOCKED-state prerequisite handling.
- Added regression and behavior tests for drift-scan StrictMode handling, monitor failure signaling, auto-revert safety, and rooted artifact path packaging.
- Added README and delivery/deployment handoff components linking checklist and lab contract materials.

### Deferred

- Deferred broad dead-config cleanup for comparison-extension fields; `Compare-PermissionSet` and related illustrative config remain documented as tenant-binding extension targets.

## [v0.1.2] — 2026-05-23 — Council review remediation

### Fixed

- Finding 3: Updated Graph `sendMail` usage so sender mailbox/user ID is separate from alert and approval recipients.
- Finding 8: Aligned the External Consultant sample drift score and tier with scaffold scoring logic.
- Finding 10: Merged `pending-approvals.json` records across runs instead of overwriting existing pending approvals.
- Finding 14: Added minimum-version comparisons for PnP.PowerShell and Microsoft.Graph prerequisite checks.
- Finding 20: Added SHA-256 companion hash generation and artifact metadata for CSV evidence output.

### Documentation tightened

- Finding 1: Clarified that drift scan output is representative sample drift until tenant-bound current-state comparison is added.
- Finding 5: Marked the PnP permissions enumeration block as illustrative and documented the tenant-binding limitation.
- Finding 7: Reduced documented drift coverage to scaffold permission-entry samples and tenant-binding design targets.
- Finding 11: Clarified that approval responses and timeout escalation require an external workflow.
- Finding 15: Marked classifier, concurrent-drift, and Solution 02 risk scoring as future integration factors.
- Finding 19: Softened baseline feature language for sharing links and external users to representative sample scenarios.
- Finding 22: Replaced stale latest-report examples with timestamped report paths.

### Dead config

- Finding 2: Marked `driftTypeWeights` as illustrative design weights pending tenant-bound scoring.
- Finding 24: Removed unused tier-level notification and high-risk approval flags; approval behavior remains in `auto-revert-policy.json`.

### Version drift

- Finding 23: Removed stale extra-control coverage text and aligned version metadata to v0.1.2.

## [v0.1.1] — 2026-05-04

### Fixed

- Corrected read-only SharePoint permission inventory prerequisites to avoid relying on directory reader roles alone.
- Updated Microsoft Entra ID terminology and Azure Automation runtime guidance.
- Normalized sample SharePoint permission-level values to the canonical `Full Control` display name.

## [v0.1.0] — 2025-07-01

### Added

- Initial documentation-first scaffold for SharePoint Permissions Drift Detection
- `New-PermissionsBaseline.ps1` — captures site-level permissions baseline snapshots
- `Invoke-DriftScan.ps1` — detects and classifies permissions drift against baseline
- `Invoke-DriftReversion.ps1` — approval-gate and auto-revert workflow for drifted permissions
- `Export-DriftEvidence.ps1` — packages drift evidence for regulatory examination response
- `Deploy-Solution.ps1` — validates configuration and prerequisites
- `Monitor-Compliance.ps1` — orchestrates baseline check and drift scan
- `Export-Evidence.ps1` — standard evidence export using shared modules
- Three-tier configuration (baseline, recommended, regulated) with auto-revert policy
- Pester test suite validating structure, configuration, and script syntax
- Architecture, deployment, evidence-export, prerequisites, and troubleshooting documentation
- Delivery checklist aligned with FSI governance requirements

### Notes

- All scripts use representative sample data and do not connect to live Microsoft 365 services
- Auto-reversion documents the pattern but does not execute live permission changes
- Complements Solution 02 (Oversharing Risk Assessment) with temporal drift monitoring
