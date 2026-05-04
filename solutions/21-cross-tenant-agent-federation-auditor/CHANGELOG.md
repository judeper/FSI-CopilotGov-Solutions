# Changelog

## [v0.1.1] - 2026-05-04

### Changed
- Corrected Copilot Studio terminology to focus on channels, authentication settings, and organization sharing controls.
- Recast MCP evidence as connection/authentication review records instead of a Microsoft-defined attestation or signing-key mechanism.
- Recast Microsoft Entra Agent ID evidence as identity, blueprint, ownership, access, Conditional Access, and audit review metadata.
- Updated the sample monitoring schema to emit channel/authentication/sharing fields for Copilot Studio agents and `serverUrl` plus `transportType = streamable` for MCP records.

## v0.1.0 — 2026-04-22

### Added
- Initial documentation-first scaffold for the Cross-Tenant Agent Federation Auditor (CTAF).
- Tiered configuration: `baseline`, `recommended`, `regulated` with federation review cadence, MCP connection review, Entra Agent ID identity-governance review, and cross-tenant audit retention settings.
- `Deploy-Solution.ps1` — tier-aware deployment manifest generation (sample data).
- `Monitor-Compliance.ps1` — sample federation inventory, cross-tenant trust assessment, MCP connection review log, and Entra Agent ID governance review evidence.
- `Export-Evidence.ps1` — evidence artifacts (`agent-federation-inventory`, `cross-tenant-trust-assessment`, `mcp-trust-relationship-log`, `agent-id-attestation-evidence`) with JSON + SHA-256 companion files.
- `CtafConfig.psm1` — shared configuration loading and validation module.
- Documentation set: architecture, deployment guide, evidence export, prerequisites, troubleshooting.
- Pester smoke tests for file presence, configuration content, and script parse validity.
