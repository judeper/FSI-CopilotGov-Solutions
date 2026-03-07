# DORA Operational Resilience Monitor

> **Status:** Documentation-first scaffold | **Version:** v0.1.0 | **Priority:** P1 | **Track:** D

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../disclaimer.md) and [Documentation vs Runnable Assets Guide](../../documentation-vs-runnable-assets-guide.md).

## Overview

The DORA Operational Resilience Monitor (DRM) provides an operational-resilience monitoring and evidence pattern for Microsoft 365 Copilot in regulated financial-services environments. The repository implementation uses a local stub or operator-supplied sample payload for Copilot-dependent service health, classifies ICT incidents against a DORA-aligned incident taxonomy, records resilience test evidence, and publishes operational-risk dashboard feeds that can be consumed by solution 12-regulatory-compliance-dashboard. DRM supports compliance with DORA, OCC 2011-12, and the FFIEC IT Handbook by improving visibility, escalation readiness, and evidence quality for Copilot dependencies.

## What This Solution Monitors

- Microsoft 365 service health for Exchange Online, SharePoint Online, Microsoft Teams, Microsoft Graph, Microsoft 365 Apps, and Microsoft Copilot
- Incident classification using a DORA ICT incident severity model with major, significant, and minor outcomes
- Resilience test schedules, RTO and RPO targets, and recorded outcomes for annual operational-resilience exercises
- Operational-risk dashboard feeds used by 12-regulatory-compliance-dashboard for control rollup and evidence freshness reporting

## Features

| Capability | Description |
|------------|-------------|
| Service health polling pattern | Provides a monitoring framework for service health assessment; current version uses representative sample data and requires Microsoft Graph integration for live deployment |
| DORA incident classification | Maps outages and degradations to major, significant, or minor ICT incident outcomes for examiner-ready incident triage |
| Resilience test tracking | Records annual exercise dates, recovery objectives, outcomes, and reminders for Copilot dependency testing |
| Evidence packaging | Exports JSON artifacts with SHA-256 companion files for service-health-log, incident-register, and resilience-test-results |
| Tier-aware deployment | Applies baseline, recommended, or regulated operating settings for polling cadence, evidence retention, and escalation rigor |
| Dashboard integration | Produces structured control-state outputs that can feed 12-regulatory-compliance-dashboard for enterprise reporting |
| Documentation-first automation | Describes a Power Automate flow pattern for notifications and routing without forcing deployment-time workflow changes |

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not poll Microsoft 365 service health APIs (scripts use a local stub with representative sample data)
- ❌ Does not connect to Microsoft Sentinel (incident correlation is documented, not integrated)
- ❌ Does not execute DORA Article 17 reporting automatically (reporting templates are provided for manual completion)
- ❌ Does not deploy Power Automate flows (resilience alerting workflows are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)

## Architecture

The solution uses PowerShell scripts for deployment, monitoring, and evidence export; configuration files for tier-specific policy; and documentation-first guidance for optional workflow automation. See [docs/architecture.md](architecture.md) for the component diagram, data flow, integration points, and security considerations.

## Quick Start

1. Review [docs/prerequisites.md](prerequisites.md) and confirm Microsoft 365, Entra ID, PowerShell, and network requirements.
2. Select the governance tier that matches the target operating model and review `config/<tier-name>.json` together with `config/default-config.json`.
3. Run `scripts\Deploy-Solution.ps1` with `-WhatIf` first to validate the manifest and tier-specific settings.
4. Run `scripts\Monitor-Compliance.ps1` to capture an initial service-health baseline from the local stub or an operator-supplied sample payload and confirm resilience-test status.
5. Run `scripts\Export-Evidence.ps1` to generate the evidence package and verify that each JSON file has a matching `.sha256` companion.
6. Connect the exported control-state output to solution 12-regulatory-compliance-dashboard if enterprise rollup reporting is required.

## Solution Components

| Path | Purpose |
|------|---------|
| `README.md` | Solution overview, quick start, controls, and evidence summary |
| `CHANGELOG.md` | Version history for the DRM solution package |
| `DELIVERY-CHECKLIST.md` | Deployment and handover checklist for customer delivery |
| `docs/architecture.md` | Component design, data flow, integrations, and security notes |
| `docs/deployment-guide.md` | Step-by-step deployment guidance for tiered rollout |
| `docs/evidence-export.md` | Evidence artifact definitions, package contract, and examiner notes |
| `docs/prerequisites.md` | Microsoft 365, Entra, PowerShell, and role requirements |
| `docs/troubleshooting.md` | Common issues, resolutions, and escalation guidance |
| `scripts/Deploy-Solution.ps1` | Tier-aware deployment manifest generation and configuration validation |
| `scripts/Monitor-Compliance.ps1` | Service-health monitoring, incident classification, and resilience status collection using a local stub or sample payload until live Graph polling is added |
| `scripts/Export-Evidence.ps1` | Evidence artifact creation and package export using shared modules |
| `config/default-config.json` | Shared DRM defaults including monitored services and dashboard feed settings |
| `config/baseline.json` | Baseline tier settings for summary monitoring and alerting |
| `config/recommended.json` | Recommended tier settings for incident logging and resilience tracking |
| `config/regulated.json` | Regulated tier settings for DORA-oriented reporting, immutability, and Sentinel integration |
| `tests/13-dora-resilience-monitor.Tests.ps1` | Pester tests for file presence, config content, script syntax, and documentation references |

## Deployment

Deploy DRM by selecting the target governance tier, generating the deployment manifest with `Deploy-Solution.ps1`, validating the live service-health integration plan, and then scheduling `Monitor-Compliance.ps1` for the required polling cadence. In the repository state the initial monitoring run uses the local stub or an operator-supplied sample payload; use `Export-Evidence.ps1` to publish the first evidence package and connect the resulting outputs to solution 12 if centralized reporting is required.

## Prerequisites

- Microsoft 365 E3 or E5 with Copilot-enabled workloads for Exchange Online, SharePoint Online, Teams, Graph-connected services, and Microsoft 365 Apps
- Entra ID application registration with delegated operational ownership and secure secret or certificate storage
- PowerShell 7.2 or later with the modules documented in [docs/prerequisites.md](prerequisites.md)
- Microsoft Graph permissions and tenant roles needed to read service health and preserve evidence records
- Access to shared repository modules in `scripts/common/` and the shared evidence contract in `data/evidence-schema.json`
- Optional Microsoft Sentinel workspace and dashboard dependency 12-regulatory-compliance-dashboard when centralized risk reporting is required

## Related Controls

| Control | Title | Playbooks |
|---------|-------|-----------|
| 2.7 | Data Residency and Cross-Border Data Flow Governance | [Portal Walkthrough](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/2.7/portal-walkthrough.md) / [PowerShell Setup](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/2.7/powershell-setup.md) / [Verification and Testing](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/2.7/verification-testing.md) / [Troubleshooting](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/2.7/troubleshooting.md) |
| 4.9 | Incident Reporting and Root Cause Analysis | [Portal Walkthrough](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.9/portal-walkthrough.md) / [PowerShell Setup](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.9/powershell-setup.md) / [Verification and Testing](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.9/verification-testing.md) / [Troubleshooting](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.9/troubleshooting.md) |
| 4.10 | Business Continuity and Disaster Recovery for Copilot Dependency | [Portal Walkthrough](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.10/portal-walkthrough.md) / [PowerShell Setup](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.10/powershell-setup.md) / [Verification and Testing](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.10/verification-testing.md) / [Troubleshooting](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.10/troubleshooting.md) |
| 4.11 | Microsoft Sentinel Integration for Copilot Events | [Portal Walkthrough](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.11/portal-walkthrough.md) / [PowerShell Setup](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.11/powershell-setup.md) / [Verification and Testing](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.11/verification-testing.md) / [Troubleshooting](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.11/troubleshooting.md) |

## Regulatory Alignment

DRM supports compliance with DORA Art. 17 and Art. 18 by organizing ICT incident monitoring, classification, escalation timing, and resilience-test evidence for Copilot-dependent services. It also supports compliance with OCC 2011-12 resilience and governance expectations by preserving documented monitoring, escalation, and challenge records for technology dependencies, and it aligns with the FFIEC IT Handbook focus on operations management, business continuity, incident response, and examiner-ready evidence.

## Evidence Export

The solution exports the following evidence outputs:

- `service-health-log`: service-level health snapshots, polling cadence, timestamps, and workload impact notes
- `incident-register`: DORA-classified incidents with severity, affected service, detection and reporting timestamps, and recovery metrics
- `resilience-test-results`: annual exercise schedule, RTO and RPO targets, outcomes, and documented gaps

All evidence packages are written as JSON with SHA-256 companion files and are aligned to the shared schema in `data/evidence-schema.json`.

## Known Limitations

- DRM is primarily a monitoring and evidence solution. It does not perform automated service remediation or tenant failover orchestration.
- Default monitoring output is produced from a local stub or `DRM_SERVICE_HEALTH_SAMPLE_JSON`; live Microsoft Graph polling still requires tenant authentication wiring outside the repository.
- Control 2.7 remains monitor-only until tenant geo settings and approved-region data sources are connected.
- Control 4.11 remains monitor-only until a Microsoft Sentinel workspace, data connector, and alert rules are provisioned outside this solution.
- Control 4.10 is partial because resilience documentation and test tracking are included, but automated failover validation requires additional tenant-specific engineering.
- The documented Power Automate flow is not deployed by script in this version and must be configured manually from the deployment guide.
