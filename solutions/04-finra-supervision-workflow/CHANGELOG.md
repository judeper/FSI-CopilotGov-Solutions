# Changelog

All notable changes to this solution will be documented in this file.

The format is based on Keep a Changelog and this project follows Semantic Versioning.

## [v0.2.1] - 2026-05-04

### Fixed
- Updated Communication Compliance license and role guidance to use current Microsoft Purview terminology.
- Reframed ingestion guidance around customer-validated alert, export, or audit-log handoffs instead of unsupported scheduled polling.
- Updated live Dataverse export guidance to use configured EntitySet names for Web API collection paths.

## [0.2.0] - 2026-03-07

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

## [0.1.0] - 2025-12-01

### Added
- Initial scaffold for FINRA Supervision Workflow for Copilot.
- Placeholder configuration, documentation, scripts, and tests for repository onboarding.

