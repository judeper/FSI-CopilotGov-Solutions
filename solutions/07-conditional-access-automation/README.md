# Conditional Access Policy Automation for Copilot

> **Status:** Scaffolded | **Version:** v0.1.0 | **Priority:** P1 | **Track:** B

## Overview

Deploys Conditional Access patterns for Copilot users and watches for policy drift across risk tiers and device states. This scaffold establishes the required documentation, scripts, config files, and evidence-export pattern for later implementation work.

## Features

- Maps to the following controls: 2.3, 2.6, 2.9
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
| 2.3 | Conditional Access Policies for Copilot Workloads | [Portal Walkthrough](docs/playbooks/control-implementations/2.3/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/2.3/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/2.3/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/2.3/troubleshooting.md) |
| 2.6 | Copilot Web Search and Web Grounding Controls | [Portal Walkthrough](docs/playbooks/control-implementations/2.6/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/2.6/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/2.6/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/2.6/troubleshooting.md) |
| 2.9 | Defender for Cloud Apps — Copilot Session Controls | [Portal Walkthrough](docs/playbooks/control-implementations/2.9/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/2.9/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/2.9/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/2.9/troubleshooting.md) |

## Regulatory Alignment

This solution supports compliance with: OCC 2011-12, FINRA 3110, DORA.

## Evidence Export

The solution is expected to publish: ca-policy-state, drift-alert-summary, access-exception-register. Evidence packages must align to `../../data/evidence-schema.json`.

## Known Limitations

- This scaffold does not yet include tenant-specific implementation logic.
- Power Automate and Power BI artifacts remain documentation-led until the implementation track fills in workload details.
