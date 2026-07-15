# Changelog

All notable changes to this solution will be documented in this file.

The format is based on Keep a Changelog and this project follows Semantic Versioning.

## [Unreleased] — Microsoft-currency review and lab-readiness

### Fixed
- VERIFIED-BUG: `Export-Evidence.ps1` now records package-relative artifact paths, so the evidence package validates from any working directory and stays portable when relocated. The previously documented relative `-OutputPath` no longer fails package validation. Regenerated the committed sample evidence package.
- Preserved absolute artifact paths in the caller result, added relocation coverage, and made `-LiveExport` fail closed when the output path is inside the repository because live rows can contain supervisory identities and review notes.
- Kept live-export control status at `partial`; Dataverse row presence alone does not establish implemented supervisory controls.

### Changed
- Documented current Microsoft Purview Communication Compliance terminology for detecting Microsoft 365 Copilot and Microsoft 365 Copilot Chat interactions (the **Detect Microsoft Copilot interactions** template and **Microsoft Copilot experiences** location) and the least-privileged reviewer role groups (Communication Compliance Analysts, Investigators, Viewers) with the policy-reviewer requirement.
- Clarified the supported alert-launched Power Automate handoff and the pay-as-you-go billing boundary that applies only to non-Microsoft 365 AI locations.
- Added Dataverse Web API guidance to confirm each table's `EntitySetName` from metadata instead of assuming the default plural collection name, and clarified lookup-column addressing for live export.
- Replaced unqualified immutable-log wording with an append-only governance pattern that does not claim WORM or platform-level immutability.

### Added
- Added a read-only, detect-only lab validation contract (`lab/04-finra-supervision-workflow.lab.json`) with a lab handoff in the deployment guide and delivery checklist.
- Hardened the contract with out-of-band tenant proof, least-privilege read roles, runtime-bound Dataverse metadata lookup, ignored local staging, and fail-closed cleanup.
- Added a regression test covering package-relative evidence artifact paths.

## [v0.2.3] — 2026-06-05 — Microsoft product/feature accuracy fix

### Fixed
- Clarified Dataverse API rate limit in `docs/troubleshooting.md`: the 6,000-request/5-min limit is enforced per user, per web server (not a flat per-user cap), per MS Learn documentation.

## [v0.2.2] — 2026-05-23 — Council review remediation

### VERIFIED-BUG
- Aligned the supervision review flow sample with the Dataverse `fsi_cg_fsw_log` action pattern and contracted evidence artifact names.
- Regenerated committed sample evidence artifacts and SHA-256 companion files using the shared evidence exporter.
- Documented retention rationale for baseline, recommended, and regulated evidence defaults with FINRA Rule 4511 and SEC Rule 17a-4 references.
- Normalized the architecture diagram box widths.

### VERIFIED-VERSION-DRIFT
- Updated solution version metadata from v0.2.1 to v0.2.2 and regenerated the sample evidence package with exportVersion 1.1.0.

## [v0.2.1] - 2026-05-04

### Fixed
- Updated Communication Compliance license and role guidance to use current Microsoft Purview terminology.
- Reframed ingestion guidance around customer-validated alert, export, or audit-log handoffs instead of unsupported scheduled polling.
- Updated live Dataverse export guidance to use configured EntitySet names for Web API collection paths.

## [v0.2.0] - 2026-03-07

### Added
- Replaced scaffold documentation with FINRA supervision workflow guidance for Dataverse tables, Power Automate flows, deployment, evidence export, prerequisites, and troubleshooting.
- Added tier-aware configuration files for baseline, recommended, and regulated deployments.
- Added solution-specific PowerShell implementations for deployment manifest generation, compliance monitoring, and evidence packaging.
- Added expanded Pester coverage for documentation, configuration, and script validation.

### Changed
- Updated regulatory alignment to focus on controls 3.4, 3.5, and 3.6 and evidence outputs specific to supervision operations.
- Updated solution language to use documentation-first deployment guidance for manual Power Platform implementation.

### Fixed
- Removed placeholder scaffold text from the solution folder.

## [v0.1.0] - 2025-12-01

### Added
- Initial scaffold for FINRA Supervision Workflow for Copilot.
- Placeholder configuration, documentation, scripts, and tests for repository onboarding.
