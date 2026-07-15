# Changelog

All notable changes to this solution will be documented in this file.

The format is based on Keep a Changelog and this solution uses semantic versioning.

## [Unreleased] — Microsoft currency review and read-only lab contract

### Fixed

- Corrected `externalWebSearchGroundingRestriction` availability from `preview` to `generallyAvailable` in default-config.json; Microsoft Learn no longer marks the web-search grounding restriction as preview and the M365 roadmap records it as launched.
- Hardened `Export-Evidence.ps1` workload-location resolution so a live baseline without `complementaryWorkloadDlpPolicyLocations` no longer throws under `Set-StrictMode`.
- Made evidence-package artifact paths package-relative for relocation safety while preserving absolute artifact paths in the caller result.

### Added

- Documented the external-email grounding exclusion capability **(preview)** for the Microsoft 365 Copilot and Copilot Chat policy location (sender-domain metadata only; email body not inspected).
- Documented rule-condition exclusivity (a sensitive-information-type condition and a sensitivity-label condition require separate rules in the same policy), Custom-template-only availability, policy simulation mode, and the up-to-four-hour policy propagation delay.
- Refined DLP-for-Copilot licensing guidance to separate the E5/Purview-suite requirement for sensitivity-label blocking from the all-Copilot-user availability of prompt and web-search protection.
- Added the read-only lab validation contract `lab/05-dlp-policy-governance.lab.json` (detect-only, `mutations: []`) plus lab handoff notes in the deployment guide and delivery checklist.
- Added view-only DLP role guidance and retained `EnforcementPlanes` and `Locations` in lab policy evidence so the contract can prove Copilot scope instead of inferring it from policy name.
- Added behavioral Pester tests for the DLP policy template, capability currency, monitoring drift detection, and the evidence-export workload fallback.

### Marked illustrative

- Annotated `defaults.sensitivityConditions` in default-config.json as an illustrative reference list; scripts consume the per-tier `sensitivityConditions` objects only.

## [v0.2.3] — 2026-06-05 — Microsoft product/feature accuracy corrections

### Fixed

- Corrected `sensitiveInformationTypesInPrompts` availability from `generallyAvailable` to `preview` in default-config.json per Microsoft Learn.
- Corrected `externalWebSearchGroundingRestriction` availability from `generallyAvailable` to `preview` in default-config.json per Microsoft Learn.
- Added preview qualifiers to README capability descriptions and Known limitations section.
- Corrected Microsoft Graph scope description: Graph supplies sensitivity-label and Entra ID policy metadata only; DLP policy metadata comes from Security & Compliance PowerShell (`Get-DlpCompliancePolicy`).

## [v0.2.2] — 2026-05-23 — Council review remediation

### Dead config

- Finding 7: Marked `defaults.baselineStoragePath` as illustrative metadata, changed the sample path to a platform-neutral relative path, and clarified that scripts compute artifact paths from runtime output parameters.

## [v0.2.1] - 2026-05-04

### Changed

- Clarified the Microsoft 365 Copilot and Copilot Chat DLP policy location, preview and generally available capability status, prompt-upload limitation, and complementary workload DLP baseline separation.
- Updated Copilot DLP prerequisite role guidance to distinguish policy create/edit roles from read-only review roles.

## [v0.2.0]

### Added

- Detailed solution documentation for DLP policy scope, deployment, evidence, prerequisites, and troubleshooting.
- Tier-specific configuration files for baseline, recommended, and regulated Copilot DLP governance.
- PowerShell implementations for baseline creation, compliance monitoring, and evidence export.
- Meaningful Pester checks for configuration, documentation, and script validation.

### Changed

- Replaced the scaffold-only content with solution-specific operational guidance for Microsoft Purview DLP and Power Automate exception routing.
- Updated evidence handling to produce `dlp-policy-baseline`, `policy-drift-findings`, and `exception-attestations` artifacts with SHA-256 companions.

## [v0.1.0]

### Added

- Initial scaffold for Solution 05 with placeholder documentation, scripts, and configuration files.
