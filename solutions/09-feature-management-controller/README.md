# Copilot Feature Management Controller

> **Status:** Scaffolded | **Version:** v0.1.0 | **Priority:** P1 | **Track:** C

## Overview

Centralizes Copilot feature toggles, rollout rings, and drift monitoring across applications and user cohorts. This scaffold establishes the required documentation, scripts, config files, and evidence-export pattern for later implementation work.

## Features

- Maps to the following controls: 2.6, 4.1, 4.2, 4.3, 4.4, 4.12, 4.13
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
| 2.6 | Copilot Web Search and Web Grounding Controls | [Portal Walkthrough](docs/playbooks/control-implementations/2.6/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/2.6/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/2.6/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/2.6/troubleshooting.md) |
| 4.1 | Copilot Admin Settings and Feature Management | [Portal Walkthrough](docs/playbooks/control-implementations/4.1/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/4.1/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/4.1/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/4.1/troubleshooting.md) |
| 4.2 | Copilot in Teams Meetings Governance | [Portal Walkthrough](docs/playbooks/control-implementations/4.2/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/4.2/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/4.2/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/4.2/troubleshooting.md) |
| 4.3 | Copilot in Teams Phone and Queues Governance | [Portal Walkthrough](docs/playbooks/control-implementations/4.3/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/4.3/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/4.3/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/4.3/troubleshooting.md) |
| 4.4 | Copilot in Viva Suite Governance | [Portal Walkthrough](docs/playbooks/control-implementations/4.4/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/4.4/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/4.4/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/4.4/troubleshooting.md) |
| 4.12 | Change Management for Copilot Feature Rollouts | [Portal Walkthrough](docs/playbooks/control-implementations/4.12/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/4.12/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/4.12/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/4.12/troubleshooting.md) |
| 4.13 | Copilot Extensibility Governance (Plugin Lifecycle, Connector Monitoring) | [Portal Walkthrough](docs/playbooks/control-implementations/4.13/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/4.13/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/4.13/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/4.13/troubleshooting.md) |

## Regulatory Alignment

This solution supports compliance with: SEC Reg FD, FINRA 3110.

## Evidence Export

The solution is expected to publish: feature-state-baseline, rollout-ring-history, drift-findings. Evidence packages must align to `../../data/evidence-schema.json`.

## Known Limitations

- This scaffold does not yet include tenant-specific implementation logic.
- Power Automate and Power BI artifacts remain documentation-led until the implementation track fills in workload details.
