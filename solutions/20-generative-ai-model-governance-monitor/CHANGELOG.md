# Changelog

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
