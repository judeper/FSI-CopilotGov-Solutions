# Copilot Connector and Plugin Governance

> **Status:** Scaffolded | **Version:** v0.1.0 | **Priority:** P1 | **Track:** C

## Overview

Inventories connectors and plugins, routes approval requests, and records data-flow decisions for extensibility scenarios. This scaffold establishes the required documentation, scripts, config files, and evidence-export pattern for later implementation work.

## Features

- Maps to the following controls: 1.13, 2.13, 2.14, 4.13
- Supports the `baseline`, `recommended`, and `regulated` configuration tiers
- Reuses the shared modules under `../../scripts/common/`
- Publishes evidence with the shared JSON and SHA-256 packaging pattern

## Architecture

The scaffold uses a documentation-first pattern for Power Automate and Power BI assets, a PowerShell entry point for deployment and monitoring, and configuration files that align to the repository-wide contract.

## Quick Start

1. Review [Prerequisites](prerequisites.md).
2. Review [Deployment Guide](deployment-guide.md).
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
| 1.13 | Extensibility Readiness (Graph Connectors, Plugins, Declarative Agents) | [Portal Walkthrough](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/1.13/portal-walkthrough.md) / [PowerShell Setup](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/1.13/powershell-setup.md) / [Verification and Testing](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/1.13/verification-testing.md) / [Troubleshooting](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/1.13/troubleshooting.md) |
| 2.13 | Plugin and Graph Connector Security Governance | [Portal Walkthrough](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/2.13/portal-walkthrough.md) / [PowerShell Setup](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/2.13/powershell-setup.md) / [Verification and Testing](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/2.13/verification-testing.md) / [Troubleshooting](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/2.13/troubleshooting.md) |
| 2.14 | Declarative Agents from SharePoint — Creation and Sharing Governance | [Portal Walkthrough](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/2.14/portal-walkthrough.md) / [PowerShell Setup](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/2.14/powershell-setup.md) / [Verification and Testing](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/2.14/verification-testing.md) / [Troubleshooting](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/2.14/troubleshooting.md) |
| 4.13 | Copilot Extensibility Governance (Plugin Lifecycle, Connector Monitoring) | [Portal Walkthrough](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/4.13/portal-walkthrough.md) / [PowerShell Setup](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/4.13/powershell-setup.md) / [Verification and Testing](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/4.13/verification-testing.md) / [Troubleshooting](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/4.13/troubleshooting.md) |

## Regulatory Alignment

This solution supports compliance with: FINRA 3110, OCC 2011-12, DORA.

## Evidence Export

The solution is expected to publish: connector-inventory, approval-register, data-flow-attestations. Evidence packages must align to `../../data/evidence-schema.json`.

## Known Limitations

- This scaffold does not yet include tenant-specific implementation logic.
- Power Automate and Power BI artifacts remain documentation-led until the implementation track fills in workload details.
