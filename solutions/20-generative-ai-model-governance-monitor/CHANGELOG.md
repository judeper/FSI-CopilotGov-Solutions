# Changelog

## [Unreleased]

### Added
- Read-only, detect-only lab validation contract (`lab/20-generative-ai-model-governance-monitor.lab.json`) with `mutations: []`, honest negative-validation paths (no subscription, no Foundry resource/project, no read-only role, unavailable region/feature, no deployments), and least-privilege read-only prerequisites with evidence minimization.
- Lab validation handoff guidance in the deployment guide and delivery checklist, and registration of the contract in `scripts/test_lab_validation_contracts.py`.

### Changed
- Replaced the legacy Foundry classic content-filter citation with the canonical Azure OpenAI-in-Microsoft-Foundry default Guardrail source and narrowed wording to Azure OpenAI default Guardrails plus provider/deployment-native guardrails for non-Azure-OpenAI deployments only where documentation and read-only portal evidence confirm them (README, prerequisites, architecture, evidence-export, deployment guide, and representative config values).
- Separated evidence-integrity and evidence-minimization assertions in the lab contract: `step-verify-evidence-integrity` now attests SHA-256 sidecar verification only, and `step-review-evidence-minimization` adds a read-only prohibited-content review attestation required for PASS evidence.
- Added Scope Boundaries stating the solution does not govern or independently validate the Microsoft-hosted foundation models behind Microsoft 365 Copilot or Copilot Chat, and does not equate Microsoft 365 Copilot governance with Azure or Microsoft Foundry model governance.

### Verified
- Confirmed against first-party Microsoft sources as of 2026-07-14: Microsoft Foundry branding (Azure AI Studio / Azure AI Foundry are prior names; earlier portal is Foundry (classic); current model is a Foundry resource with projects), the model-catalog provider set, Microsoft Entra AI Administrator and AI Reader roles, the Cognitive Services User Azure built-in role, and the generally available Microsoft Graph `auditLogQuery` API.

## [v0.1.3] — 2026-06-05 — Microsoft Learn accuracy fixes

### Fixed
- Corrected Azure built-in role name from "Cognitive Services Users" to "Cognitive Services User" (singular) in prerequisites.
- Replaced informal "Audit Search Graph API" with the correct Microsoft Graph `auditLogQuery` API name in architecture documentation.

## Validation Sweep — 2026-05-25

### Verified

- All Microsoft Learn URLs resolve and content matches documented claims (Foundry, Content Safety, Purview, Entra roles).
- All PowerShell scripts pass syntax validation.
- SR 26-2 / OCC Bulletin 2026-13 generative AI exclusion correctly documented.
- SR 11-7 / OCC Bulletin 2011-12 interim genAI applicability accurately described.
- NIST AI RMF 1.0 and ISO/IEC 42001 references are current.
- Admin role names (AI Administrator, AI Reader) match current Entra built-in roles.
- Microsoft Foundry branding is current (not Azure AI Foundry / Azure AI Studio).
- Added `last_verified` to `config/default-config.json`.

## v0.1.2 — 2026-05-23 — Council review remediation

### Fixed
- F-10: Aligned GMG regulatory metadata and framework IDs with the documented SR 26-2 / OCC 2026-13, SR 11-7 / OCC 2011-12, NIST AI RMF 1.0, and ISO/IEC 42001 mapping.
- F-06: Regulated-tier sample validation records now mark independent challenge as `required-pending` when tier configuration enables annual independent challenge.

## v0.1.1 — 2026-05-04

### Changed
- Broadened the documentation-first inventory scope to include Microsoft Foundry, Azure OpenAI or Foundry deployments, and approved Foundry partner/community provider sources.
- Added content safety and guardrail evidence coverage for Azure AI Content Safety, Prompt Shields, groundedness, protected-material, filter-threshold, exception, and review-cadence evidence where applicable.
- Updated representative configuration, evidence export scripts, and smoke tests for five evidence artifacts.
## v0.1.0 — 2026-04-22

### Added
- Initial documentation-first scaffold for the Generative AI Model Governance Monitor (GMG)
- Tiered configuration files (baseline, recommended, regulated) covering inventory review cadence, validation scope, monitoring cadence, monitoring log retention, and third-party review cadence
- Deploy-Solution.ps1 stub for tier-aware deployment manifest generation
- Monitor-Compliance.ps1 stub that emits a representative sample model-inventory and monitoring snapshot
- Export-Evidence.ps1 stub that writes four JSON evidence artifacts (copilot-model-inventory, validation-summary, ongoing-monitoring-log, third-party-due-diligence) with SHA-256 sidecars
- GmgConfig.psm1 shared configuration module
- Pester smoke tests for file presence, configuration shape, and PowerShell parse validation
- Documentation set: architecture, deployment guide, evidence export, prerequisites, troubleshooting
- Mapping notes covering Federal Reserve SR 11-7 / OCC Bulletin 2011-12 interim generative AI applicability after SR 26-2 / OCC Bulletin 2026-13 excluded generative AI from its scope
