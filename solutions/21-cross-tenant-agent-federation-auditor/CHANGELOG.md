# Changelog

## v0.1.0 — 2026-04-22

### Added
- Initial documentation-first scaffold for the Cross-Tenant Agent Federation Auditor (CTAF).
- Tiered configuration: `baseline`, `recommended`, `regulated` with federation review cadence, MCP attestation, Entra Agent ID signing, and cross-tenant audit retention settings.
- `Deploy-Solution.ps1` — tier-aware deployment manifest generation (sample data).
- `Monitor-Compliance.ps1` — sample federation inventory, cross-tenant trust assessment, MCP trust log, and Entra Agent ID attestation collection.
- `Export-Evidence.ps1` — evidence artifacts (`agent-federation-inventory`, `cross-tenant-trust-assessment`, `mcp-trust-relationship-log`, `agent-id-attestation-evidence`) with JSON + SHA-256 companion files.
- `CtafConfig.psm1` — shared configuration loading and validation module.
- Documentation set: architecture, deployment guide, evidence export, prerequisites, troubleshooting.
- Pester smoke tests for file presence, configuration content, and script parse validity.
