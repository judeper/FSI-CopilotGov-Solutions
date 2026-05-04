# Copilot Feature Management Controller

> **Status:** Documentation-first scaffold | **Version:** v0.1.1 | **Priority:** P1 | **Track:** C
>
> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../disclaimer.md) and [Documentation vs Runnable Assets Guide](../../documentation-vs-runnable-assets-guide.md).

## Overview

Copilot Feature Management Controller (FMC) centralizes Copilot feature inventory, rollout ring policy, baseline capture, and drift monitoring across Microsoft 365, Teams, and Power Platform workloads. The solution is designed for financial services operating models where feature enablement decisions must be scoped by user cohort, application, and supervisory approval before Copilot capabilities are exposed more broadly.

For regulated firms, Copilot feature activation can change how material non-public information, research notes, customer interactions, and plugin outputs are surfaced. FMC supports compliance with SEC Reg FD by documenting where high-impact Copilot features are enabled and supports compliance with FINRA 3110 by giving supervisors a repeatable baseline, monitoring cadence, and evidence trail for feature policy decisions.

Microsoft now provides the **Copilot Control System** in the Microsoft 365 admin center Adoption Hub as a centralized governance surface for Copilot features, agents, and connectors. This solution complements the Copilot Control System by adding tier-aware configuration management, drift detection, and evidence packaging for regulated environments.

The solution uses PowerShell for baseline capture, ring planning, monitoring, and evidence packaging, while Power Automate assets remain documentation-first until approved for tenant deployment.

## Features

| Capability | What FMC does | Compliance value |
|------------|---------------|------------------|
| Feature registry | Provides structure to normalize Copilot features from documented Microsoft 365 admin center settings, Teams meeting/event policy exports, Cloud Policy service web-search policy state, and Power Platform admin center settings. Current version uses tier-defined feature templates; live data collection requires customer implementation. | Supports compliance with controls 4.1 and 4.2 by giving operations and compliance teams a shared registry of enabled capabilities. |
| Ring management | Applies Preview Ring, Early Adopters, General Availability, and Restricted ring definitions with tier-aware approval rules and target populations. | Supports compliance with control 4.3 by limiting exposure before supervisory review is complete. |
| Drift detection | Compares current feature state against approved baseline settings and highlights unexpected enablement, scope, or ring changes. | Supports compliance with control 4.4 by identifying deviations that require remediation or documented acceptance. |
| Change tracking | Records change intent, ring promotions, and alert history for operational and supervisory review. | Supports compliance with control 4.12 by preserving rollout rationale and approval context. |
| Baseline enforcement | Maintains expected feature state for regulated, recommended, and baseline tiers and flags nonconforming tenant behavior. | Supports compliance with controls 2.6 and 4.13 by restricting feature scope and highlighting unmanaged plugin or connector exposure. |

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not connect to Microsoft 365 admin center, Teams admin center, or Power Platform admin center services (feature inventory uses tier-defined templates)
- ❌ Does not enable or disable Copilot features (rollout ring assignments are documented, not executed)
- ❌ Does not deploy Power Automate flows (change-tracking workflows are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)
- ❌ Does not cover Agent 365 platform governance or Entra Agent ID controls
- ❌ Does not configure tenant-wide Copilot web domain exclusion lists or authoritative source controls as Microsoft admin settings; those remain customer-defined planning metadata until Microsoft documents the control surface
- ❌ Does not manage Baseline Security Mode (BSM) simulation or enforcement
- ❌ Does not govern third-party model providers (Anthropic Claude, xAI)

> **Data classification:** See [Data Classification Matrix](../../reference/data-classification.md) for residency, retention, and data-class metadata.

## Architecture

```text
+-----------------------------------+     +----------------------------------+
| Microsoft 365 admin center        |     | Cloud Policy service             |
| Teams admin center (meetings)     | --> | Allow web search in Copilot      |
| Power Platform admin center       |     | policy state                     |
+----------------------+------------+     +----------------+-----------------+
                       |                                   |
                       v                                   v
                       +----------------+-----------------+
                       | Feature Inventory Collector      |
                       | - Normalize documented settings  |
                       | - Tag source system and owner    |
                       +----------------+-----------------+
                                        |
                                        v
                       +----------------+-----------------+
                       | Baseline and Ring Controller     |
                       | - Capture approved feature state |
                       | - Apply tier-based ring policy   |
                       +-----------+------------+---------+
                                   |            |
                                   v            v
                         +---------+--------+   +-----+------------------+
                         | Drift Detector  |   | Power Automate Flows   |
                         | - Compare       |   | - FMC-DriftMonitor     |
                         |   baseline      |   | - FMC-RingPromotion    |
                         | - Score findings|   | - FMC-ChangeNotifier   |
                         +--------+--------+   +-----+------------------+
                                  |                  |
                                  v                  v
                         +--------+------------------+------+
                         | Evidence Export and Notifications |
                         | - feature-state-baseline          |
                         | - rollout-ring-history            |
                         | - drift-findings                  |
                         +-----------------------------------+
```

See [docs/architecture.md](architecture.md) for component detail.

## Quick Start

1. Review [docs/prerequisites.md](prerequisites.md) and confirm Microsoft 365 admin center, Teams admin center, Power Platform admin center, and Cloud Policy service access are in place.
2. Select the governance tier that matches the rollout objective: `baseline`, `recommended`, or `regulated`.
3. Review the tier settings in `config\default-config.json` and `config\<tier>.json`, especially rollout ring definitions, drift interval, and app coverage.
4. Run the deployment planner:

   ```powershell
   .\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId 'contoso.onmicrosoft.com' -Environment 'Production' -OutputPath .\artifacts\FMC
   ```

5. Run compliance monitoring against the approved baseline:

   ```powershell
   .\scripts\Monitor-Compliance.ps1 -ConfigurationTier recommended -BaselinePath .\artifacts\FMC\feature-state-baseline.json
   ```

6. Export evidence for review and retention:

   ```powershell
   .\scripts\Export-Evidence.ps1 -ConfigurationTier recommended -OutputPath .\artifacts\FMC
   ```

## Solution Components

| Path | Purpose |
|------|---------|
| `scripts\Deploy-Solution.ps1` | Prepares documentation-first admin context metadata, captures tier-defined feature inventory, generates baseline output, plans ring assignments, and documents Power Automate deployment intent. |
| `scripts\Monitor-Compliance.ps1` | Reads approved baseline content, compares observed feature state, scores drift, and prepares structured alert payloads. |
| `scripts\Export-Evidence.ps1` | Packages control status, evidence artifact metadata, and a SHA-256 companion hash using the shared evidence export module. |
| `config\default-config.json` | Defines enterprise defaults such as feature categories, rollout ring percentages, documented admin source metadata, Dataverse table names, and Power Automate flow metadata. |
| `config\baseline.json` | Baseline tier focused on standard features, daily drift checks, and summary notifications. |
| `config\recommended.json` | Recommended tier with active ring management, 4-hour drift checks, and Microsoft 365 plus Teams coverage. |
| `config\regulated.json` | Regulated tier with all tracked features, hourly drift checks, strict approval requirements, and 365-day evidence retention. |
| `docs\*.md` | Deployment, architecture, evidence, prerequisite, and troubleshooting guidance for operational teams. |
| `tests\09-feature-management-controller.Tests.ps1` | Pester checks for documentation, configuration, parameter surface, solution codes, and PowerShell syntax. |

## Deployment

Deployment is intentionally staged:

1. Capture the approved baseline for the target environment.
2. Validate the ring plan for Preview Ring, Early Adopters, General Availability, and Restricted cohorts.
3. Document Power Automate flows before enabling them in tenant environments.
4. Run drift monitoring and review findings with operations, compliance, and service ownership teams.
5. Export evidence after each approved change window or recurring monitoring cycle.

Use `-BaselineOnly` during first deployment if the tenant has not yet approved automated ring promotion.

## Prerequisites

- Microsoft 365 Global Administrator, Copilot Administrator, or equivalent delegated access for Microsoft 365 admin center Copilot settings
- Teams Administrator role for documented Teams meeting, event, and calling policy review
- Power Platform Administrator for Power Apps Copilot settings and Power Automate tenant-level Copilot settings
- Cloud Policy service permissions for the `Allow web search in Copilot` policy
- Dataverse capacity for baseline, finding, and evidence records

Detailed requirements are listed in [docs/prerequisites.md](prerequisites.md).

## Related Controls

> **Coverage state** (per [Control Coverage Honesty](../../reference/control-coverage-honesty.md)):
> 7 control(s) are **evidence-export-ready** in scaffold form: 2.6, 4.1, 4.12, 4.13, 4.2, 4.3, 4.4.

| Control | Requirement | FMC implementation support |
|---------|-------------|----------------------------|
| 2.6 | Copilot Web Search and Web Grounding Controls | Uses approved feature scope, app coverage lists, and Restricted ring definitions to keep unapproved Copilot experiences — including web search and grounding — blocked or isolated. |
| 4.1 | Copilot Admin Settings and Feature Management | Maintains an inventory of Copilot features, source systems, and expected state across supported admin surfaces. |
| 4.2 | Copilot in Teams Meetings Governance | Documents expected enablement by tier and highlights policy exceptions that require formal approval for Teams Meetings Copilot features. |
| 4.3 | Copilot in Teams Phone and Queues Governance | Defines four rollout rings with target population percentages and approval expectations for Teams Phone and Queues Copilot features. |
| 4.4 | Copilot in Viva Suite Governance | Compares observed feature state to approved baseline and records drift findings for follow-up across Viva Suite Copilot capabilities. |
| 4.12 | Change Management and Rollout Risk Tracking | Preserves rollout promotion history, change references, and notification events for supervisory review. |
| 4.13 | Third-Party Connector and Plugin Risk Assessment | Flags connector and plugin exposure in the feature registry so separate risk review can be triggered before enablement. |

## Regulatory Alignment

- **SEC Reg FD:** supports compliance with controlled enablement of Copilot features that could widen access to material non-public information or research-related outputs.
- **FINRA 3110:** supports compliance with supervisory review by preserving baseline state, monitoring cadence, and change history for feature rollout decisions.

## Evidence Export

FMC publishes the following evidence outputs:

| Evidence artifact | Purpose |
|-------------------|---------|
| `feature-state-baseline` | Snapshot of approved feature state, source system, ring assignment, and monitoring cadence. |
| `rollout-ring-history` | History of promotion, restriction, or rollback actions by feature and cohort. |
| `drift-findings` | Findings that identify deviations between approved baseline and observed tenant configuration. |

All evidence packages use the shared JSON contract and SHA-256 companion hash from `scripts\common\EvidenceExport.psm1`.

## Known Limitations

- Microsoft Graph `featureRolloutPolicies` are not a Copilot feature-control source; they are out of scope for FMC's Copilot feature inventory.
- Teams chat/channel Copilot inventory is documentation-first unless a current Microsoft Learn admin control is identified.
- Power Automate Copilot settings should be interpreted with the documented tenant-level limitation where environment-level support is unavailable.
- Drift scoring is most meaningful after a tenant-specific baseline has been captured and approved.
- Power Automate flow deployment remains documentation-first; the scripts record deployment intent and flow metadata rather than importing live flow packages.
- The feature registry does not yet include Copilot agents, Copilot Studio governance, or Copilot Pages and Notebooks controls. These are recommended additions for the next version.
