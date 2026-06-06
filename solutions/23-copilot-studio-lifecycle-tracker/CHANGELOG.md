# Changelog

## [Unreleased]

## [v0.1.4] — 2026-06-06 — Agent 365 prerequisites and architecture enhancements

### Changed

- Added Microsoft Agent 365 GA date (2026-05-01), per-user licensing note, and plans link to `docs/prerequisites.md` (Issues #73/#75 optional enhancement). Citation: https://learn.microsoft.com/en-us/microsoft-agent-365/overview
- Added M365 admin center navigation path (Agents > All Agents > Registry) to the Microsoft Agent 365 registry Integration Point in `docs/architecture.md`. Citation: https://learn.microsoft.com/en-us/microsoft-365/admin/manage/agent-registry



### Fixed
- Aligned "Power Platform admin API" → "Power Platform API" in README.md, Monitor-Compliance.ps1 to match official Microsoft Learn naming (`api.powerplatform.com`) and the solution's own prerequisites/network sections.

## Validation Sweep — 2026-05-25

### Verified

- All Microsoft Learn URLs (Copilot Studio publishing) resolve and content matches claims.
- All PowerShell scripts pass syntax validation.
- Microsoft Agent 365 registry context confirmed accurate (GA May 1, 2026).
- Microsoft.PowerApps.Administration.PowerShell Windows PowerShell 5.x limitation confirmed current.
- Power Platform API delegated permission guidance confirmed accurate.
- Regulatory citations (FFIEC IT Handbook, FINRA 3110, OCC 2023-17, SOX §§302/404) are accurate.
- Added `last_verified` to `config/default-config.json`.

## v0.1.2 — 2026-05-23 — Council review remediation

### Fixed
- F-02: Routed `scripts/Export-Evidence.ps1` through `Export-SolutionEvidencePackage` so package creation runs shared schema, hash, and artifact-completeness validation.

### Documentation tightened
- F-01: Aligned evidence-export guidance with the shared evidence package helper now used by the export script.
- F-04: Reconciled the documented `EvidenceExport.psm1` dependency with the export script by importing and using the shared module.

## [v0.1.1] - 2026-05-04

### Changed
- Added Microsoft Agent 365 registry and lifecycle-governance context to the README and architecture guidance.
- Clarified Power Platform API permission, RBAC, and PowerShell runtime prerequisites for future live integration.
- Qualified Copilot Studio publish/version evidence language and customer-supplied rollback references.

## v0.1.0 - 2025-01-15

### Added
- Initial documentation-first scaffold for Copilot Studio agent lifecycle governance
- Tier configuration files for baseline, recommended, and regulated postures covering publishing approval, versioning retention, deprecation notice window, and lifecycle review cadence
- `Deploy-Solution.ps1` with tier-aware manifest generation
- `Monitor-Compliance.ps1` with agent inventory, publishing approval, and lifecycle review snapshot collection from a local stub
- `Export-Evidence.ps1` producing `agent-lifecycle-inventory`, `publishing-approval-log`, `version-history`, and `deprecation-evidence` artifacts with SHA-256 companions
- `CsltConfig.psm1` shared configuration module
- Pester smoke tests covering file presence, configuration shape, and script parameter validation
- Documentation set: architecture, deployment guide, evidence export, prerequisites, troubleshooting
