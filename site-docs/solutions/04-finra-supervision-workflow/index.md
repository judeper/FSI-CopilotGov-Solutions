# FINRA Supervision Workflow for Copilot

> **Status:** Scaffolded | **Version:** v0.1.0 | **Priority:** P0 | **Track:** B

## Overview

Routes flagged Copilot-assisted communications into a reviewer queue with sampling, escalation, and exception tracking. This scaffold establishes the required documentation, scripts, config files, and evidence-export pattern for later implementation work.

## Features

- Maps to the following controls: 3.4, 3.5, 3.6
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
| 3.4 | Communication Compliance Monitoring | [Portal Walkthrough](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/3.4/portal-walkthrough.md) / [PowerShell Setup](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/3.4/powershell-setup.md) / [Verification and Testing](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/3.4/verification-testing.md) / [Troubleshooting](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/3.4/troubleshooting.md) |
| 3.5 | FINRA Rule 2210 Compliance for Copilot-Drafted Communications | [Portal Walkthrough](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/3.5/portal-walkthrough.md) / [PowerShell Setup](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/3.5/powershell-setup.md) / [Verification and Testing](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/3.5/verification-testing.md) / [Troubleshooting](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/3.5/troubleshooting.md) |
| 3.6 | Supervision and Oversight (FINRA Rule 3110 / SEC Reg BI) | [Portal Walkthrough](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/3.6/portal-walkthrough.md) / [PowerShell Setup](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/3.6/powershell-setup.md) / [Verification and Testing](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/3.6/verification-testing.md) / [Troubleshooting](https://github.com/judeper/FSI-CopilotGov/blob/main/docs/playbooks/control-implementations/3.6/troubleshooting.md) |

## Regulatory Alignment

This solution supports compliance with: FINRA 3110, FINRA 2210, SEC Reg BI.

## Evidence Export

The solution is expected to publish: supervision-queue-snapshot, review-disposition-log, sampling-summary. Evidence packages must align to `../../data/evidence-schema.json`.

## Known Limitations

- This scaffold does not yet include tenant-specific implementation logic.
- Power Automate and Power BI artifacts remain documentation-led until the implementation track fills in workload details.
