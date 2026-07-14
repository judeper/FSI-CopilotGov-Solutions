# Changelog

## [Unreleased]

### Added

- Read-only lab validation contract `lab/23-copilot-studio-lifecycle-tracker.lab.json` (`mutations: []`) with the handoff consolidated into the existing deployment guide and delivery checklist. The contract cites verified generally-available Microsoft Learn sources and validates with `scripts/validate-lab-contracts.py`. Control 4.14 is intentionally excluded from the contract's `controls` array because it is not yet present in `data/controls-master.json`.
- `## Application Lifecycle Management (ALM)` section in `docs/architecture.md` describing Power Platform solution export/import, managed vs. unmanaged behavior, environment variables and connection references, pipelines, and the publish/republish requirement. Citations: https://learn.microsoft.com/microsoft-copilot-studio/guidance/alm, https://learn.microsoft.com/microsoft-copilot-studio/authoring-solutions-import-export, https://learn.microsoft.com/microsoft-copilot-studio/authoring-solutions-overview, https://learn.microsoft.com/microsoft-copilot-studio/authoring-variables-about, https://learn.microsoft.com/microsoft-copilot-studio/publication-fundamentals-publish-channels
- Cross-platform Microsoft Power Platform CLI (`pac`) noted as a supported alternative to the legacy admin module in `docs/prerequisites.md` and `docs/deployment-guide.md`. Citation: https://learn.microsoft.com/power-platform/developer/cli/introduction
- Pester coverage for the lab contract (presence, read-only `mutations: []`, US commercial scope, null mutation references, framework-known controls).

### Fixed

- Fixed a runtime failure in `Monitor-Compliance.ps1` where an empty lifecycle-review result set unrolled to `$null`, causing `The property 'Count' cannot be found on this object.` under `Set-StrictMode -Version Latest`. Inventory, approval, and finding collections are now normalized with `@(...)` so the monitor runs cleanly on all tiers.
- Aligned the `.NOTES` version in `Deploy-Solution.ps1`, `Monitor-Compliance.ps1`, and `Export-Evidence.ps1` from `v0.1.3` to the current `v0.1.4` to remove stale in-script version references.
- Made Deploy/Monitor/Export output paths PowerShell-provider aware, made evidence packages relocatable while returning absolute caller paths, and added fail-closed ignored lab staging cleanup.
- Replaced evidence-immutability overstatement with an external storage requirement and clarified that `version-history`/rollback fields are customer-supplied solution/change evidence, not Copilot Studio product telemetry.

### Verified

- 2026-07-14 accuracy review against first-party Microsoft Learn sources. Confirmed accurate: Microsoft Agent 365 GA "As of May 1, 2026 ... for the Commercial segment on a per user basis" and the "works best when using Microsoft E5 as a pre-requisite" guidance (https://learn.microsoft.com/microsoft-agent-365/overview); agent registry navigation "Agents > All Agents > Registry" (https://learn.microsoft.com/microsoft-365/admin/manage/agent-registry); Copilot Studio draft/publish/republish model with no canonical rollback API (https://learn.microsoft.com/microsoft-copilot-studio/publication-fundamentals-publish-channels); `Microsoft.PowerApps.Administration.PowerShell` requires Windows PowerShell 5.x and uses .NET Framework, incompatible with PowerShell 6.0 and later (https://learn.microsoft.com/power-platform/admin/powerapps-powershell); and Power Platform API "delegated permissions only at this time" with RBAC roles for service principals (https://learn.microsoft.com/power-platform/admin/programmability-authentication-v2).

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
