# Changelog

## [v0.1.1] - 2026-05-04

### Changed

- Clarified Restricted SharePoint Search and Restricted Content Discovery caveats for item-level oversharing evidence.
- Updated DSPM prerequisites to identify Microsoft Purview Data Security Posture Management as the current experience and DSPM for AI as classic.
- Separated SharePoint site collection access, Purview roles, and Microsoft Graph permission guidance for item-level permission enumeration.

## [v0.1.0] - 2026-03-17

### Added

- Initial scaffold for item-level oversharing scanner
- Get-ItemLevelPermissions.ps1 for PnP-based item permission enumeration
- Export-OversharedItems.ps1 for FSI risk scoring
- Invoke-BulkRemediation.ps1 for approval-gated remediation
- Risk threshold and remediation policy configuration files
