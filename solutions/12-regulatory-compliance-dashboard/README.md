# Regulatory Compliance Dashboard

> **Status:** Scaffolded | **Version:** v0.1.0 | **Priority:** P0 | **Track:** C

## Overview

Aggregates solution outputs into a control-centric dashboard that highlights implementation state, evidence freshness, and regulatory coverage. This scaffold establishes the required documentation, scripts, config files, and evidence-export pattern for later implementation work.

## Features

- Maps to the following controls: 3.7, 3.8, 3.12, 3.13, 4.5, 4.7
- Supports the `baseline`, `recommended`, and `regulated` configuration tiers
- Reuses the shared modules under `../../scripts/common/`
- Publishes evidence with the shared JSON and SHA-256 packaging pattern

## Architecture

The scaffold uses a documentation-first pattern for Power Automate and Power BI assets, a PowerShell entry point for deployment and monitoring, and configuration files that align to the repository-wide contract.

## Quick Start

1. Review [Prerequisites](./docs/prerequisites.md).
2. Review [Deployment Guide](./docs/deployment-guide.md).
3. Validate the scaffold with `python scripts/validate-solutions.py` from the repository root.
4. Add workload-specific implementation logic in this solution track after shared contracts are frozen.

## Solution Components

| Path | Purpose |
|------|---------|
| `scripts/Deploy-Solution.ps1` | Tier-aware deployment entry point for the solution scaffold |
| `scripts/Monitor-Compliance.ps1` | Control-status snapshot and monitoring placeholder |
| `scripts/Export-Evidence.ps1` | Evidence export entry point aligned to the shared schema |
| `config/*.json` | Default, baseline, recommended, and regulated settings |
| `docs/*.md` | Architecture, prerequisites, deployment, evidence, and troubleshooting guidance |
| `tests/*.Tests.ps1` | Pester placeholder coverage for the scaffold |

## Deployment

Use `scripts/Deploy-Solution.ps1` for tier-aware deployment manifests and `scripts/Monitor-Compliance.ps1` for scaffolded status output.

## Prerequisites

- Microsoft 365 and workload permissions appropriate for the mapped controls
- Shared contract files under `data/` and `scripts/common/`
- A chosen governance tier for the target deployment

## Related Controls

| Control | Title | Playbooks |
|---------|-------|-----------|
| 3.7 | Regulatory Reporting (FINRA, SEC, SOX, GLBA, CFPB UDAAP) | [Portal Walkthrough](docs/playbooks/control-implementations/3.7/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/3.7/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/3.7/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/3.7/troubleshooting.md) |
| 3.8 | Model Risk Management Alignment (OCC 2011-12 / SR 11-7) | [Portal Walkthrough](docs/playbooks/control-implementations/3.8/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/3.8/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/3.8/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/3.8/troubleshooting.md) |
| 3.12 | Evidence Collection and Audit Attestation | [Portal Walkthrough](docs/playbooks/control-implementations/3.12/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/3.12/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/3.12/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/3.12/troubleshooting.md) |
| 3.13 | FFIEC IT Examination Handbook Alignment | [Portal Walkthrough](docs/playbooks/control-implementations/3.13/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/3.13/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/3.13/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/3.13/troubleshooting.md) |
| 4.5 | Copilot Usage Analytics and Adoption Reporting | [Portal Walkthrough](docs/playbooks/control-implementations/4.5/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/4.5/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/4.5/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/4.5/troubleshooting.md) |
| 4.7 | Copilot Feedback and Telemetry Data Governance | [Portal Walkthrough](docs/playbooks/control-implementations/4.7/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/4.7/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/4.7/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/4.7/troubleshooting.md) |

## Regulatory Alignment

This solution supports compliance with: FINRA 4511, FINRA 3110, SEC 17a-4, OCC 2011-12, DORA, GLBA 501(b).

## Evidence Export

The solution is expected to publish: control-status-snapshot, framework-coverage-matrix, dashboard-export. Evidence packages must align to `../../data/evidence-schema.json`.

## Known Limitations

- This scaffold does not yet include tenant-specific implementation logic.
- Power Automate and Power BI artifacts remain documentation-led until the implementation track fills in workload details.
