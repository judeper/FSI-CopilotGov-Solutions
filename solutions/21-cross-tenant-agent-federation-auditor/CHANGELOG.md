# Changelog

## [v0.1.3] — 2026-06-05 — Microsoft Learn accuracy fixes

### Fixed
- **MAJOR:** Corrected licensing reference from "Microsoft 365 E7" to "Microsoft 365 E5" (or component Entra ID P1/P2 + Global Secure Access) per Microsoft Learn agent security feature requirements. Fixed in `docs/prerequisites.md` and prior changelog entry.
- **MINOR:** Updated product brand from "Microsoft Entra External Identities" to current "Microsoft Entra External ID" in README, architecture, and default configuration.
- **MINOR:** Replaced shorthand `authenticationType = 'Microsoft Entra ID'` with verbatim Copilot Studio UI options ("Authenticate with Microsoft" / "Authenticate manually (Microsoft Entra ID)") in sample data.

## Validation Sweep — 2026-05-25

### Verified

- All Microsoft Learn URLs (Entra built-in roles) resolve and content matches claims.
- All PowerShell scripts pass syntax validation.
- MCP Streamable transport naming confirmed current (SSE deprecated August 2025).
- Microsoft Entra Agent ID roles (Agent ID Administrator, Agent ID Developer) confirmed in Entra roles reference.
- Microsoft 365 E5 and Microsoft Agent 365 licensing references confirmed accurate (corrected from E7 — Microsoft Learn specifies E5 for agent security features).
- Regulatory citations (GLBA §501(b), FFIEC IT Handbook, SEC Reg S-P, OCC 2023-17, FINRA 3110) are accurate.
- Added `last_verified` to `config/default-config.json`.

## v0.1.2 — 2026-05-23 — Council review remediation

### VERIFIED-BUG
- Replaced custom evidence package assembly with the shared `Export-SolutionEvidencePackage` helper while preserving sample-mode metadata, controls, and artifact references.
- Extended CTAF configuration validation to require tier fields consumed by deployment output.

### VERIFIED-DOC-OVERCLAIM
- Corrected the regulated retention label from seven years to five years for the configured 1825-day value.
- Clarified troubleshooting guidance so required-field documentation matches the validator.

### VERIFIED-DEAD-CONFIG
- Loaded `mcpAttestationRevalidationRequired` from tier configuration and surfaced it in deployment manifests, defaulting to `false` when absent.

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
