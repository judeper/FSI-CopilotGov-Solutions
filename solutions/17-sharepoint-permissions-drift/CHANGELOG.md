# Changelog — SharePoint Permissions Drift Detection

All notable changes to this solution are documented in this file.

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
