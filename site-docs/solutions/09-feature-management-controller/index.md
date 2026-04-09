# Copilot Feature Management Controller

> **Status:** Documentation-first scaffold | **Version:** v0.2.0 | **Priority:** P1 | **Track:** C
>
> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../disclaimer.md) and [Documentation vs Runnable Assets Guide](../../documentation-vs-runnable-assets-guide.md).

## Overview

Copilot Feature Management Controller (FMC) centralizes Copilot feature inventory, rollout ring policy, baseline capture, and drift monitoring across Microsoft 365, Teams, and Power Platform workloads. The solution is designed for financial services operating models where feature enablement decisions must be scoped by user cohort, application, and supervisory approval before Copilot capabilities are exposed more broadly.

For regulated firms, Copilot feature activation can change how material non-public information, research notes, customer interactions, and plugin outputs are surfaced. FMC supports compliance with SEC Reg FD by documenting where high-impact Copilot features are enabled and supports compliance with FINRA 3110 by giving supervisors a repeatable baseline, monitoring cadence, and evidence trail for feature policy decisions.

The solution uses PowerShell for baseline capture, ring planning, monitoring, and evidence packaging, while Power Automate assets remain documentation-first until approved for tenant deployment.

## Features

| Capability | What FMC does | Compliance value |
|------------|---------------|------------------|
| Feature registry | Provides structure to normalize Copilot features from Microsoft 365 Admin Center, Microsoft Graph beta rollout policies, Teams Admin Center, and Power Platform Admin settings. Current version uses tier-defined feature templates; live data collection requires customer implementation. | Supports compliance with controls 4.1 and 4.2 by giving operations and compliance teams a shared registry of enabled capabilities. |
| Ring management | Applies Preview Ring, Early Adopters, General Availability, and Restricted ring definitions with tier-aware approval rules and target populations. | Supports compliance with control 4.3 by limiting exposure before supervisory review is complete. |
| Drift detection | Compares current feature state against approved baseline settings and highlights unexpected enablement, scope, or ring changes. | Supports compliance with control 4.4 by identifying deviations that require remediation or documented acceptance. |
| Change tracking | Records change intent, ring promotions, and alert history for operational and supervisory review. | Supports compliance with control 4.12 by preserving rollout rationale and approval context. |
| Baseline enforcement | Maintains expected feature state for regulated, recommended, and baseline tiers and flags nonconforming tenant behavior. | Supports compliance with controls 2.6 and 4.13 by restricting feature scope and highlighting unmanaged plugin or connector exposure. |
| Web grounding governance | Documents the configuration pattern for Copilot web grounding domain exclusion lists, authoritative source designation, and web search policy enforcement. Current version provides governance templates; live policy deployment requires customer implementation in the Microsoft 365 admin center. | Supports compliance with controls 2.5 and 4.1 by governing which external web sources Copilot can reference and prioritizing authoritative internal content. |

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not connect to Microsoft 365 Admin Center, Teams Admin, or Power Platform Admin APIs (feature inventory uses tier-defined templates)
- ❌ Does not enable or disable Copilot features (rollout ring assignments are documented, not executed)
- ❌ Does not deploy Power Automate flows (change-tracking workflows are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)
- ❌ Does not configure web grounding domain exclusion or authoritative sources in the Microsoft 365 admin center (governance templates and audit patterns are documented for manual configuration)

## Architecture

```text
+-----------------------------------+     +----------------------------------+
| Microsoft 365 Admin Center        |     | Microsoft Graph beta             |
| Teams Admin Center                | --> | /policies/featureRolloutPolicies |
| Power Platform Admin Center       |     +----------------+-----------------+
+----------------------+------------+                      |
                       |                                   v
                       |                  +----------------+-----------------+
                       +----------------> | Feature Inventory Collector      |
                                          | - Normalize feature settings     |
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
                                    +-----------------+--+   +-----+------------------+
                                    | Drift Detector     |   | Power Automate Flows   |
                                    | - Compare baseline |   | - FMC-DriftMonitor     |
                                    | - Score findings   |   | - FMC-RingPromotion    |
                                    +---------+----------+   | - FMC-ChangeNotifier   |
                                              |              +-----+------------------+
                                              v                    |
                                    +---------+--------------------+------+
                                    | Evidence Export and Notifications   |
                                    | - feature-state-baseline            |
                                    | - rollout-ring-history              |
                                    | - drift-findings                    |
                                    +-------------------------------------+
```

See [docs/architecture.md](architecture.md) for component detail.

## Quick Start

1. Review [docs/prerequisites.md](prerequisites.md) and confirm the Microsoft 365, Teams, Power Platform, and Graph permissions are in place.
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
| `scripts\Deploy-Solution.ps1` | Connects to the stub Graph context, captures current feature inventory, generates baseline output, plans ring assignments, and documents Power Automate deployment intent. |
| `scripts\Monitor-Compliance.ps1` | Reads approved baseline content, compares observed feature state, scores drift, and prepares structured alert payloads. |
| `scripts\Export-Evidence.ps1` | Packages control status, evidence artifact metadata, and a SHA-256 companion hash using the shared evidence export module. |
| `config\default-config.json` | Defines enterprise defaults such as feature categories, rollout ring percentages, Graph scopes, Dataverse table names, and Power Automate flow metadata. |
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

- Microsoft 365 Global Administrator or delegated access that includes `Policy.ReadWrite.FeatureRollout`
- Teams Administrator role for Teams feature policies
- Power Platform Administrator for Copilot settings in Power Apps and Power Automate
- Microsoft Graph scopes for rollout policy and directory inspection
- Dataverse capacity for baseline, finding, and evidence records

Detailed requirements are listed in [docs/prerequisites.md](prerequisites.md).

## Related Controls

| Control | Requirement | FMC implementation support |
|---------|-------------|----------------------------|
| 2.6 | Scoped Feature Enablement and Copilot App Access Control | Uses approved feature scope, app coverage lists, and Restricted ring definitions to keep unapproved Copilot experiences blocked or isolated. |
| 4.1 | Copilot Feature Inventory and Capability Registry | Maintains an inventory of Copilot features, source systems, and expected state across supported admin surfaces. |
| 4.2 | Feature Toggle and Policy-Based Enablement | Documents expected enablement by tier and highlights policy exceptions that require formal approval. |
| 4.3 | Rollout Ring Management for Copilot Features | Defines four rollout rings with target population percentages and approval expectations. |
| 4.4 | Feature Drift Detection and Baseline Enforcement | Compares observed feature state to approved baseline and records drift findings for follow-up. |
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

- Microsoft Graph rollout policy coverage is based on the beta endpoint and may require additional validation before production automation.
- Some Teams and Power Platform feature settings may require export or administrative documentation instead of direct API writes.
- Drift scoring is most meaningful after a tenant-specific baseline has been captured and approved.
- Power Automate flow deployment remains documentation-first; the scripts record deployment intent and flow metadata rather than importing live flow packages.
