# Risk-Tiered Rollout Automation

> **Status:** Documentation-first scaffold | **Version:** v0.1.0 | **Priority:** P0 | **Track:** C

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](../../docs/documentation-vs-runnable-assets-guide.md).

## Overview

Risk-Tiered Rollout Automation documents Copilot rollout preparation, prerequisite validation, pilot waves, and staged assignment intent by user risk tier. The design supports financial-services operating models where OCC 2011-12 encourages phased technology change, FINRA 3110 requires supervisors to evidence readiness before broader rollout, and DORA raises the importance of resilient change control and documented approvals for higher-risk populations.

The solution depends on `01-copilot-readiness-scanner` to provide current readiness evidence before each wave is prepared. PowerShell prepares license-assignment wave manifests for review and manual execution, Power Automate is documented as the approval and orchestration layer, and Power BI is documented as the rollout-health reporting layer. The solution supports compliance with phased rollout, supervision, and change-tracking expectations; it does not make absolute compliance determinations.

## Features

| Capability | Description | Primary Outputs |
|------------|-------------|-----------------|
| Risk-tier classification | Categorizes candidate users into Tier 1 standard users, Tier 2 regulated-role users, and Tier 3 privileged or executive users based on readiness and role signals. | `wave-readiness-log` |
| Wave sequencing preparation | Prepares Wave 0 through Wave 3 cohorts, honors tier-specific rollout boundaries, and limits higher-risk users until earlier waves are stable. | Wave manifests, assignment-intent manifests |
| Gate criteria checking | Evaluates readiness scanner freshness, prerequisite completion, approval evidence, and wave-specific expansion thresholds before the next cohort is released. | Gate review results |
| Expansion approval workflow | Documents business-owner, control-owner, and CAB approvals through Power Automate flow definitions before customer-run license assignment is executed. | `approval-history` |
| Rollout health dashboard model | Summarizes readiness coverage, blocked users, staged assignments, and wave health scoring in a Power BI dashboard model. | `rollout-health-dashboard` |

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not assign or modify Copilot licenses (wave manifests are generated for manual execution)
- ❌ Does not connect to Microsoft Graph APIs (scripts use representative sample data)
- ❌ Does not orchestrate rollout waves automatically (gate criteria are evaluated but deployment requires manual approval)
- ❌ Does not deploy Power Automate flows (approval workflows are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)
- ❌ Does not distinguish Copilot Chat Basic vs Premium tiers in wave planning (v1.3+ framework feature pending solution update)
- ❌ Does not include organizational branded footer configuration as a trust mechanism

## Architecture

```text
01-copilot-readiness-scanner
            |
            v
+-----------------------+
| Risk Tier Classifier  |
+-----------------------+
            |
            v
+-----------------------+      +----------------------+
| Wave Sequencer        |----->| Gate Criteria Check  |
+-----------------------+      +----------------------+
            |                              |
            v                              v
+-----------------------+      +----------------------+
| Manifest Generator    |----->| Dataverse Evidence   |
+-----------------------+      +----------------------+
            |                              |
            +--------------+---------------+
                           |
                           v
                 +----------------------+
                 | Power BI Health Dash |
                 +----------------------+
```

See [docs/architecture.md](docs/architecture.md) for the detailed component model, flow descriptions, and wave definitions.

## Quick Start

1. Confirm that [01-copilot-readiness-scanner](../01-copilot-readiness-scanner/) is deployed and has produced a current evidence package.
2. Review [docs/prerequisites.md](docs/prerequisites.md) and confirm Microsoft 365 licensing, Graph permissions, Dataverse capacity, and the CAB process are in place.
3. Select the governance tier that matches the target operating model: `baseline`, `recommended`, or `regulated`.
4. Update the relevant JSON files under `config\` with tenant-specific wave sizes, approver groups, and environment values.
5. Run `pwsh -File .\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId "contoso.onmicrosoft.com" -WaveNumber 0 -Environment "Pilot" -WhatIf` to preview Wave 0 preparation.
6. Use `pwsh -File .\scripts\Monitor-Compliance.ps1 -ConfigurationTier recommended -WaveNumber 0` to review gate status and wave health metrics.
7. Export evidence with `pwsh -File .\scripts\Export-Evidence.ps1 -ConfigurationTier recommended` after each approved expansion.

## Solution Components

| Path | Purpose |
|------|---------|
| `scripts/Deploy-Solution.ps1` | Loads tiered configuration, validates the readiness-scanner dependency, classifies users by risk tier, and builds a wave manifest with staged assignment intent for rollout operations. |
| `scripts/Monitor-Compliance.ps1` | Evaluates current wave status, gate completion, blocked users, pending assignments, and a documentation-first wave health score used by operations teams. |
| `scripts/Export-Evidence.ps1` | Produces a solution evidence package plus detailed artifact files for wave readiness, approvals, and dashboard state. |
| `config/default-config.json` | Canonical four-wave design, risk tier criteria, Dataverse naming, gate thresholds, and reporting settings. |
| `config/baseline.json` | Two-wave entry model for Tier 1 users with summary notifications and manual handling of higher-risk cohorts. |
| `config/recommended.json` | Three-wave model with Tier 1 and Tier 2 automation, approval gates, and Viva Insights reporting hooks. |
| `config/regulated.json` | Four-wave regulated rollout with CAB approvals, audit trail requirements, DORA resilience checks, and 365-day retention. |
| `docs/architecture.md` | Documentation-first design for Power Automate orchestration, Dataverse tracking, and Power BI reporting. |
| `docs/deployment-guide.md` | Step-by-step deployment and rollback instructions for Wave 0 through Wave 3 operations. |
| `docs/evidence-export.md` | Field-level evidence guidance for `wave-readiness-log`, `approval-history`, and `rollout-health-dashboard`. |
| `tests/11-risk-tiered-rollout.Tests.ps1` | Pester coverage for documentation, configuration, and PowerShell script integrity. |

## Deployment

Deployment begins with the `01-copilot-readiness-scanner` dependency, followed by Dataverse and flow configuration, then wave preparation through `scripts/Deploy-Solution.ps1`. Baseline deployments stage Tier 1 pilot activity, recommended deployments extend documented workflow preparation to Tier 2 with approval gates, and regulated deployments add Tier 3 controls, CAB approval, and DORA-specific resilience review before customer-run release steps.

Detailed deployment steps, sample commands, and rollback actions are documented in [docs/deployment-guide.md](docs/deployment-guide.md).

## Prerequisites

- `01-copilot-readiness-scanner` is deployed and has produced a recent readiness evidence package.
- Microsoft 365 E3 or E5 licensing plus Microsoft 365 Copilot licenses are available for the intended wave size.
- Required Microsoft Graph permissions are approved: `User.ReadWrite.All` and `Directory.Read.All`.
- Power Automate Premium is licensed for approval and orchestration flows.
- Dataverse capacity is available for `fsi_cg_rtr_baseline`, `fsi_cg_rtr_finding`, and `fsi_cg_rtr_evidence`.
- A Change Advisory Board or equivalent change-governance body is defined for regulated wave approvals.

See [docs/prerequisites.md](docs/prerequisites.md) for full prerequisites and operational dependencies.

## Related Controls

| Control | Title | Playbooks |
|---------|-------|-----------|
| 1.9 | License Planning and Copilot Assignment Strategy | [deployment guide](docs/deployment-guide.md), [architecture](docs/architecture.md), [evidence export](docs/evidence-export.md) |
| 1.11 | Organizational Change Management and Adoption Planning | [architecture](docs/architecture.md), [deployment guide](docs/deployment-guide.md), [troubleshooting](docs/troubleshooting.md) |
| 1.12 | Training and Awareness Program | [architecture](docs/architecture.md), [deployment guide](docs/deployment-guide.md), [evidence export](docs/evidence-export.md) |
| 4.12 | Change Management for Copilot Feature Rollouts | [deployment guide](docs/deployment-guide.md), [troubleshooting](docs/troubleshooting.md), [evidence export](docs/evidence-export.md) |

## Regulatory Alignment

This solution supports compliance with the following regulatory references when implemented with tenant-specific controls and operating procedures:

- OCC 2011-12 for phased deployment discipline, change approvals, and issue escalation
- FINRA 3110 for supervisor readiness, controlled rollout of regulated-role users, and retained approval records
- DORA for resilient change management, operational traceability, and evidence retention for higher-risk waves

## Evidence Export

`scripts/Export-Evidence.ps1` produces a packaged evidence file plus supporting artifacts:

- `wave-readiness-log`
- `approval-history`
- `rollout-health-dashboard`

Each export aligns to the shared repository evidence schema and includes a companion SHA-256 hash file for the packaged evidence payload.

## Known Limitations

- The deployment and monitoring scripts are structured stubs and do not directly invoke Microsoft Graph or Power Automate APIs in this repository state.
- Risk-tier classification uses representative sample logic until live HR, Entra, and readiness-scanner data feeds are connected.
- Power Automate and Power BI assets remain documentation-first; implementation teams must bind the documented flows and datasets to the target environment.
- The wave planning model assumes a single paid Copilot SKU assignment per user. Organizations using the free Copilot Chat tier should note that Tier 1 users may already have basic Copilot access before any wave begins.
- The Copilot Control System in the Microsoft 365 admin center now provides built-in rollout controls. This solution complements those controls by adding risk-tiered wave planning, gate criteria enforcement, and evidence packaging.
