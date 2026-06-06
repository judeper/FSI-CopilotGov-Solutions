# Changelog — SharePoint Permissions Drift Detection

All notable changes to this solution are documented in this file.

## [v0.1.3] — 2026-06-05 — Microsoft Learn accuracy fixes

### Fixed

- Corrected synthetic sharing-link label `OrganizationView` to use real Microsoft Graph sharing-link properties (`linkScope = 'organization'`, `linkType = 'view'`).
- Corrected `HasUniqueRoleAssignments` usage from `-Fields` column reference to securable-object property access pattern (it is a property, not a field-selectable column).

### Added

- Enhancement note in architecture.md grounding future tenant binding in SharePoint Advanced Management (SAM) Data Access Governance reports (Permission state, Sharing links, EEEU insights).

## [Unreleased]

### Validation sweep — 2026-05-25

- Verified PnP PowerShell cmdlets and minimum version (2.3.0) are current.
- Verified PnP.PowerShell v3.x prerequisite note (PS 7.4+, .NET 8.0, own app registration since Sept 2024) is accurate.
- Verified Microsoft Graph API permissions (`Files.Read.All`, `Sites.Read.All`, `Sites.FullControl.All`, `Mail.Send`, `User.Read.All`, `GroupMember.Read.All`) are current.
- Verified Microsoft.Graph minimum version (2.0.0) is reasonable for the documented endpoints.
- Verified cross-solution reference to 02-oversharing-risk-assessment is valid.
- Verified script parameter names and shared module imports match implementation.
- No corrections required; all content verified accurate as of 2026-05-25.

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
