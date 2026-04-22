# Changelog

## [Unreleased]

## v0.1.0 - 2025-01-15

### Added
- Initial Pages and Notebooks Retention Tracker (PNRT) scaffold
- Tiered configuration covering Copilot Pages retention, OneNote Notebook retention, branching audit, and Loop component provenance
- Deploy-Solution.ps1 with tier-aware deployment manifest generation
- Monitor-Compliance.ps1 with sample-data inventory of Pages, Notebooks, Loop components, and branching events
- Export-Evidence.ps1 producing pages-retention-inventory, notebook-retention-log, loop-component-lineage, and branching-event-log artifacts with SHA-256 companions
- Pester smoke tests covering file presence, configuration shape, and script parameter validation
- Documentation set: architecture, deployment guide, evidence export, prerequisites, troubleshooting
