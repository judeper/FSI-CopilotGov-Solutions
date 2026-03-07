# Sensitivity Label Coverage Auditor

> **Status:** Scaffolded | **Version:** v0.1.0 | **Priority:** P1 | **Track:** A

## Overview

Measures label coverage across in-scope workloads and identifies unlabeled content that weakens Copilot data protection controls. This scaffold establishes the required documentation, scripts, config files, and evidence-export pattern for later implementation work.

## Features

- Maps to the following controls: 1.5, 2.2, 3.11, 3.12
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
| 1.5 | Sensitivity Label Taxonomy Review for Copilot | [Portal Walkthrough](docs/playbooks/control-implementations/1.5/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/1.5/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/1.5/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/1.5/troubleshooting.md) |
| 2.2 | Sensitivity Labels and Copilot Content Classification | [Portal Walkthrough](docs/playbooks/control-implementations/2.2/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/2.2/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/2.2/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/2.2/troubleshooting.md) |
| 3.11 | Record Keeping and Books-and-Records Compliance (SEC 17a-3/4, FINRA 4511) | [Portal Walkthrough](docs/playbooks/control-implementations/3.11/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/3.11/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/3.11/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/3.11/troubleshooting.md) |
| 3.12 | Evidence Collection and Audit Attestation | [Portal Walkthrough](docs/playbooks/control-implementations/3.12/portal-walkthrough.md) / [PowerShell Setup](docs/playbooks/control-implementations/3.12/powershell-setup.md) / [Verification and Testing](docs/playbooks/control-implementations/3.12/verification-testing.md) / [Troubleshooting](docs/playbooks/control-implementations/3.12/troubleshooting.md) |

## Regulatory Alignment

This solution supports compliance with: FINRA 4511, SEC 17a-4, GDPR, GLBA 501(b).

## Evidence Export

The solution is expected to publish: label-coverage-report, label-gap-findings, remediation-manifest. Evidence packages must align to `../../data/evidence-schema.json`.

## Known Limitations

- This scaffold does not yet include tenant-specific implementation logic.
- Power Automate and Power BI artifacts remain documentation-led until the implementation track fills in workload details.
