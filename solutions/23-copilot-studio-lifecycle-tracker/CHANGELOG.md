# Changelog

## [Unreleased]

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
