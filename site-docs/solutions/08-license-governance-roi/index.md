# License Governance and ROI Tracker

> **Status:** Documentation-first scaffold | **Version:** v0.1.0 | **Priority:** P1 | **Track:** C
>
> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../disclaimer.md) and [Documentation vs Runnable Assets Guide](../../documentation-vs-runnable-assets-guide.md).

## Overview

License Governance and ROI Tracker helps financial-services teams monitor Copilot license assignment quality, identify inactive seats, document business-value indicators, and prepare reallocation recommendations for management review. The solution is designed for institutions that need disciplined seat planning, cost allocation support, and repeatable evidence packages that support compliance with OCC 2011-12 and SOX 404 expectations.

The implementation is intentionally documentation-first for Power BI assets. The PowerShell scripts define the deployment, monitoring, and evidence packaging flow, while the architecture and deployment guides document how a customer-owned Power BI dataset should be configured.

## Detailed Features

| Capability | What the solution does | Primary source | Controls |
|------------|------------------------|----------------|----------|
| License utilization querying | Inventories Copilot for Microsoft 365 SKU assignments and seat consumption through Microsoft Graph inventory planning calls. | Microsoft Graph `/v1.0/subscribedSkus` | 1.9, 4.8 |
| Inactivity detection | Flags seats whose last reported activity is older than the configured threshold and prepares reallocation candidates. | Microsoft Graph Copilot usage reports | 1.9, 4.5, 4.8 |
| ROI signal collection | Documents how Viva Insights and Microsoft 365 usage signals feed a management scorecard for adoption and value conversations. | Viva Insights export plus M365 usage reports | 4.5, 4.6 |
| Reallocation workflow | Produces manager-review recommendations that can exclude protected users from solution `11-risk-tiered-rollout` before a seat is reclaimed. | Dataverse findings plus governance review process | 1.9, 4.8 |
| Evidence packaging | Exports JSON evidence, companion SHA-256 hashes, and artifact references for periodic control reviews. | `Export-Evidence.ps1` and `EvidenceExport.psm1` | 4.5, 4.8 |

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not connect to Microsoft Graph license APIs (scripts use representative sample usage data)
- ❌ Does not reallocate or modify license assignments
- ❌ Does not deploy Power BI reports (dashboard specifications are documented, not deployed)
- ❌ Does not deploy Power Automate flows (reallocation workflows are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)

## Architecture

```text
+-------------------------+      +-----------------------------------+
| Microsoft Graph         |----->| PowerShell orchestration          |
| - users                 |      | - Deploy-Solution.ps1             |
| - subscribedSkus        |      | - Monitor-Compliance.ps1          |
| - Copilot usage reports |      | - Export-Evidence.ps1             |
+------------+------------+      +----------------+------------------+
             |                                    |
             |                                    v
             |                     +-------------------------------+
             |                     | Dataverse and evidence layer  |
             |                     | - fsi_cg_lgr_baseline         |
             |                     | - fsi_cg_lgr_finding          |
             |                     | - fsi_cg_lgr_evidence         |
             |                     +----------------+--------------+
             |                                      |
             v                                      v
+-------------------------+      +-----------------------------------+
| Viva Insights signals   |----->| Power BI dataset specification    |
| and management inputs   |      | and governance scorecards         |
+-------------------------+      +-----------------------------------+

Dependency input: solution 11-risk-tiered-rollout supplies risk-tier context for exception handling.
```

See [docs/architecture.md](architecture.md) for the full data flow, endpoint inventory, and Power BI dataset design.

## Quick Start

1. Review [prerequisites](prerequisites.md) and confirm Copilot, Viva Insights, Power BI, and Graph permission readiness.
2. Select a governance tier in `config\baseline.json`, `config\recommended.json`, or `config\regulated.json`.
3. Generate a deployment manifest:
   ```powershell
   .\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId '<tenant-guid>' -OutputPath '.\artifacts\deploy'
   ```
4. Configure the documented Power BI dataset and schedule monitoring:
   ```powershell
   .\scripts\Monitor-Compliance.ps1 -ConfigurationTier recommended -OutputPath '.\artifacts\monitor'
   ```
5. Export an evidence package and validate the SHA-256 file:
   ```powershell
   .\scripts\Export-Evidence.ps1 -ConfigurationTier recommended -OutputPath '.\artifacts\evidence'
   ```

## Solution Components

| Path | Purpose |
|------|---------|
| `scripts\Deploy-Solution.ps1` | Loads tier settings, validates Graph connectivity planning, and writes the deployment manifest JSON. |
| `scripts\Monitor-Compliance.ps1` | Produces a structured license-utilization snapshot with inactive-seat analysis and reallocation flags. |
| `scripts\Export-Evidence.ps1` | Builds evidence artifacts, calculates finding counts, and packages JSON plus SHA-256 outputs. |
| `config\default-config.json` | Defines solution metadata, default reporting settings, and shared operational assumptions. |
| `config\baseline.json` | Baseline tier settings for 30-day inactivity review and summary notifications. |
| `config\recommended.json` | Recommended tier settings for 21-day inactivity review, detailed notifications, and Viva Insights usage. |
| `config\regulated.json` | Regulated tier settings for 14-day inactivity review, strict notifications, and full audit trail expectations. |
| `docs\architecture.md` | Documents the component model, Graph endpoints, Power BI dataset, and dependency with solution 11. |
| `docs\deployment-guide.md` | Step-by-step deployment and rollback guidance for customer-owned environments. |
| `docs\evidence-export.md` | Defines artifact schemas, export commands, and SHA-256 verification steps. |
| `tests\08-license-governance-roi.Tests.ps1` | Pester checks for required content, script help, and tier configuration expectations. |

## Deployment

Use `scripts\Deploy-Solution.ps1` to assemble the tier-specific deployment manifest, planned Graph scopes, Dataverse table map, and Power BI dataset requirements. After deployment planning is complete, schedule `scripts\Monitor-Compliance.ps1` to generate recurring utilization snapshots and use `scripts\Export-Evidence.ps1` to produce auditor-ready evidence packages.

The deployment flow assumes a customer-managed Power BI workspace and dataset. No `.pbix` binary is included in the repository; the dataset design is documented in `docs\architecture.md` and `docs\deployment-guide.md`.

## Prerequisites Summary

- Copilot for Microsoft 365 licenses available for the scoped user population.
- Viva Insights data available if ROI scorecards are required for the selected tier.
- Microsoft Graph application permissions: `Reports.Read.All`, `Directory.Read.All`, `User.Read.All`.
- Power BI Pro or Power BI Premium Per User for report publishing and scheduled refresh.
- PowerShell 7 and the documented Microsoft Graph modules on the automation host.

## Related Controls

| Control | Title | Playbooks |
|---------|-------|-----------|
| 1.9 | License Planning and Copilot Assignment Strategy | [Portal Walkthrough](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/1.9/portal-walkthrough.md) / [PowerShell Setup](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/1.9/powershell-setup.md) / [Verification and Testing](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/1.9/verification-testing.md) / [Troubleshooting](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/1.9/troubleshooting.md) |
| 4.5 | Copilot Usage Analytics and Adoption Reporting | [Portal Walkthrough](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.5/portal-walkthrough.md) / [PowerShell Setup](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.5/powershell-setup.md) / [Verification and Testing](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.5/verification-testing.md) / [Troubleshooting](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.5/troubleshooting.md) |
| 4.6 | Microsoft Viva Insights -- Copilot Impact Measurement | [Portal Walkthrough](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.6/portal-walkthrough.md) / [PowerShell Setup](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.6/powershell-setup.md) / [Verification and Testing](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.6/verification-testing.md) / [Troubleshooting](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.6/troubleshooting.md) |
| 4.8 | Cost Allocation and License Optimization | [Portal Walkthrough](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.8/portal-walkthrough.md) / [PowerShell Setup](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.8/powershell-setup.md) / [Verification and Testing](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.8/verification-testing.md) / [Troubleshooting](https://github.com/judeper/FSI-CopilotGov/blob/e0fb7b769529dcc008cc2066402cdabae4f369cf/docs/playbooks/control-implementations/4.8/troubleshooting.md) |

## Regulatory Alignment

- OCC 2011-12: Supports compliance with governance expectations for management reporting, assumption review, and challenge over ongoing seat-assignment decisions.
- SOX 404: Supports compliance with control evidence and review-traceability expectations for license allocation, monitoring, exception handling, and cost reallocation decisions.

## Evidence Export

The solution publishes the following evidence-oriented artifacts:

- `license-utilization-report`
- `roi-scorecard`
- `reallocation-recommendations`

Evidence packages are created by `scripts\Export-Evidence.ps1`, aligned to `..\..\data\evidence-schema.json`, and written with a companion `.sha256` file for integrity verification.

## Known Limitations

- Microsoft Graph and Viva Insights calls are implemented as structured stubs until tenant-specific authentication and reporting pipelines are connected.
- The Power BI asset remains documentation-led by design; no `.pbix` file is created in the repository.
- Reallocation actions still require business-owner or manager approval before a Copilot license is removed.
- Dependency data from `11-risk-tiered-rollout` must be supplied by the customer if high-risk cohorts should be excluded from automatic reallocation.
