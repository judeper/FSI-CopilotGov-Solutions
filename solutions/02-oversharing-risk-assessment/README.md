# Oversharing Risk Assessment and Remediation

> **Status:** Scaffolded | **Version:** v0.1.0 | **Priority:** P0 | **Track:** A

## Overview

Detects overshared SharePoint, Teams, and OneDrive content that could widen Copilot grounding beyond intended audiences. This scaffold establishes the required documentation, scripts, config files, and evidence-export pattern for later implementation work.

## Features

- Maps to the following controls: 1.2, 1.3, 1.4, 1.6, 2.5, 2.12
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
| 1.2 | SharePoint Oversharing Detection and Remediation (DSPM for AI) | [Portal Walkthrough](docs/playbooks/control-implementations/1.2/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/1.2/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/1.2/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/1.2/troubleshooting.md) |
| 1.3 | Restricted SharePoint Search Configuration | [Portal Walkthrough](docs/playbooks/control-implementations/1.3/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/1.3/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/1.3/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/1.3/troubleshooting.md) |
| 1.4 | Semantic Index Governance and Scope Control | [Portal Walkthrough](docs/playbooks/control-implementations/1.4/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/1.4/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/1.4/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/1.4/troubleshooting.md) |
| 1.6 | Permission Model Audit (SharePoint, OneDrive, Exchange, Teams, Graph) | [Portal Walkthrough](docs/playbooks/control-implementations/1.6/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/1.6/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/1.6/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/1.6/troubleshooting.md) |
| 2.5 | Data Minimization and Grounding Scope | [Portal Walkthrough](docs/playbooks/control-implementations/2.5/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/2.5/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/2.5/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/2.5/troubleshooting.md) |
| 2.12 | External Sharing and Guest Access Governance | [Portal Walkthrough](docs/playbooks/control-implementations/2.12/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/2.12/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/2.12/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/2.12/troubleshooting.md) |

## Regulatory Alignment

This solution supports compliance with: GLBA 501(b), SEC Reg S-P, FINRA 4511, FFIEC IT Handbook.

## Evidence Export

The solution is expected to publish: oversharing-findings, remediation-queue, site-owner-attestations. Evidence packages must align to `../../data/evidence-schema.json`.

## Known Limitations

- This scaffold does not yet include tenant-specific implementation logic.
- Power Automate and Power BI artifacts remain documentation-led until the implementation track fills in workload details.
