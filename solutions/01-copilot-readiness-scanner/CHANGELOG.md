# Changelog

All notable changes to this solution are documented in this file.

## [Unreleased]

### Added

- Added `lab/01-copilot-readiness-scanner.lab.json` as the first read-only lab validation contract handoff for Solution 01.
- Added delivery and deployment-guide handoff guidance for the lab contract.

### Fixed

- Restored the current Microsoft Learn product name `Microsoft 365 Copilot Optimization Assessment` in Solution 01 documentation.
- Updated Retrieval API licensing wording to distinguish add-on licensed inclusion from preview pay-as-you-go consumption for non-licensed users.
- Added Restricted Content Discovery as a documented temporary control 1.7 readiness input with explicit non-security-boundary language.
- Corrected architecture scoring text to match current representative fixed/tier-adjusted sample scoring behavior and identify percentage-of-passed-checks as a tenant-bound extension model.
- Updated `Deploy-Solution.ps1` so `-WhatIf` warns and continues when heavy Microsoft modules are missing, while real deployments still fail prerequisite checks.
- Updated `Export-Evidence.ps1` package artifact paths to use package-relative filenames.

## [v0.2.3] — 2026-06-05 — Microsoft product/feature accuracy corrections

### Fixed

- README.md:9 — Softened unverifiable "Microsoft 365 Copilot Optimization Assessment" named offering to generic "Microsoft 365 Copilot readiness and optimization guidance" (no MS Learn page documents that exact product name).
- README.md:107 — Corrected "Microsoft Copilot Retrieval API" to "Microsoft 365 Copilot Retrieval API" (official name per MS Learn).
- docs/prerequisites.md:30 — Corrected Entra role name "Directory Reader" to "Directory Readers" (plural, per MS Learn permissions reference).

## [v0.2.2] — 2026-05-23 — Council review remediation

### Fixed

- Finding #3: Corrected the evidence package contract schema path in `docs/evidence-export.md` to use the docs-relative `../../../data/evidence-schema.json`.

### Version drift

- Council version drift note: Aligned README, default configuration, delivery checklist, and catalog metadata to `v0.2.2`.

## [v0.2.1] - 2026-05-04

### Changed

- Updated README, architecture, and prerequisites guidance to align with current Microsoft Learn terminology for the Microsoft 365 Copilot Optimization Assessment, Copilot > Settings scenarios, licensing, Copilot Control System management controls, administrator roles, and least-privileged licensing permissions.
- Added reference to Microsoft 365 admin center Copilot > Settings scenarios as supplemental readiness input in README and architecture documentation.

## [v0.2.0] - 2026-03-07

### Added

- Added a solution-specific README with deployment, evidence, control mapping, and regulatory context for the Copilot Readiness Assessment Scanner.
- Added detailed architecture, deployment, prerequisites, evidence export, and troubleshooting documentation for the six-domain scanning model.
- Added realistic tier configuration for baseline, recommended, and regulated operating modes, including retention, scope, and alerting differences.
- Added implementation-ready PowerShell stubs for deployment, compliance monitoring, and evidence export workflows.
- Added Pester coverage for file structure, configuration validation, changelog presence, documentation content, and PowerShell syntax parsing.

### Changed

- Replaced shallow scaffold text with financial services-focused content aligned to controls 1.1, 1.5, 1.6, 1.7, and 1.9.
- Updated evidence handling to document schema-aligned package generation, readiness artifacts, and SHA-256 companion files.
- Updated monitoring logic to model domain-level readiness scoring across licensing, identity, Defender, Purview, Power Platform, and Copilot configuration.

## [v0.1.0] - 2025-01-01

- Added the initial scaffold for Copilot Readiness Assessment Scanner.
