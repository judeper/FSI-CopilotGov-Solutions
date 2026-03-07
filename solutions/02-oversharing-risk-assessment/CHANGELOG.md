# Changelog

All notable changes to this solution are documented in this file.

The format is based on Keep a Changelog and uses solution version tags instead of package release tags.

## [v0.2.0] - 2026-03-07

### Added

- Detailed README content for oversharing detection, remediation, controls, regulatory alignment, and evidence handling
- Architecture, deployment, prerequisites, evidence-export, and troubleshooting documentation specific to SharePoint, OneDrive, and Teams
- Tier-aware configuration values for workload scope, risk thresholds, retention, notifications, and Restricted SharePoint Search
- Credible implementation stubs for deployment, monitoring, and evidence export workflows
- Pester coverage for solution structure, configuration expectations, script syntax, dependency references, and evidence types

### Changed

- Replaced scaffold-only language with FSI-specific oversharing guidance and realistic operational limitations
- Updated version metadata from `v0.1.0` to `v0.2.0`
- Expanded delivery checklist to include licensing, site owner communications, and remediation wave planning

### Notes

- Power Automate remains documentation-first in this release and must be implemented in the target tenant environment.
- Control statuses remain mixed across `partial` and `monitor-only` states until tenant-specific API integration and approval workflows are fully connected.

## [v0.1.0]

### Added

- Initial scaffold for documentation, scripts, configuration, and basic tests
