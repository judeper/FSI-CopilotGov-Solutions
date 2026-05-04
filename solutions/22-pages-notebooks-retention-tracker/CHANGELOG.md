# Changelog

## [Unreleased]

## [v0.1.1] - 2026-05-04

### Changed
- Corrected PNRT documentation and script terminology to align Copilot Pages and Notebooks evidence with SharePoint Embedded storage, Purview audit logs, retention policies/limited labels, and version-history surfaces documented by Microsoft Learn.
- Reframed OneNote evidence as section and folder retention coverage grouped by Notebook metadata rather than direct Notebook-level retention-label assignment.
- Qualified `branching-event-log` rows as repository-only internal sample lineage taxonomy, not Microsoft 365 branch/fork/mutability lifecycle events.

## v0.1.0 - 2025-01-15

### Added
- Initial Pages and Notebooks Retention Tracker (PNRT) scaffold
- Tiered configuration covering Copilot Pages retention, OneNote section/folder retention grouped by Notebook metadata, internal sample lineage mode, and Loop component provenance
- Deploy-Solution.ps1 with tier-aware deployment manifest generation
- Monitor-Compliance.ps1 with sample-data inventory of Pages, OneNote sections, Loop components, and internal sample lineage events
- Export-Evidence.ps1 producing pages-retention-inventory, notebook-retention-log, loop-component-lineage, and branching-event-log (internal sample lineage) artifacts with SHA-256 companions
- Pester smoke tests covering file presence, configuration shape, and script parameter validation
- Documentation set: architecture, deployment guide, evidence export, prerequisites, troubleshooting
