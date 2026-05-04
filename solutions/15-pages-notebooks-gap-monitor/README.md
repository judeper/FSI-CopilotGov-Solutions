# Copilot Pages and Notebooks Compliance Gap Monitor

> **Status:** Documentation-first scaffold | **Version:** v0.1.1 | **Priority:** P2 | **Track:** D

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](../../docs/documentation-vs-runnable-assets-guide.md).

## Overview

Copilot Pages and Notebooks Compliance Gap Monitor tracks documented compliance limitations and tenant validation items for Copilot Pages, Copilot Notebooks, SharePoint Embedded containers, and related Loop storage patterns. It maps each item to the relevant regulatory requirement, records compensating controls where a documented limitation remains, and tracks revalidation as Microsoft 365 platform guidance evolves.

This solution is intentionally a gap monitor. It supports compliance with SEC 17a-4, FINRA 4511, and SOX 404 by documenting supported capabilities, remaining limitations, and the manual controls used to reduce residual risk for regulated records.

## Why this exists

Copilot Pages create `.page` files and Copilot Notebooks create `.pod` files in user-owned SharePoint Embedded containers. Microsoft Learn documents that these experiences are independent of Loop but can use the same user-owned container as Loop My workspace.

Microsoft Purview retention policies and eDiscovery are supported for Copilot Pages and Notebooks, with specific documented limitations: full-text search in Purview review sets is not available for `.page` files, legal hold requires adding the SharePoint Embedded container per user, retention labels have limited manual support, and Information Barriers are not supported for SharePoint Embedded content.

For financial services firms, the remaining limitations create control evidence needs in three areas:
- books-and-records preservation for SEC 17a-4 and FINRA 4511
- Microsoft Purview eDiscovery completeness for investigations and litigation holds
- internal control evidence for SOX 404 reviews

This solution gives compliance, legal, and operations teams a repeatable way to inventory validation items, register documented limitations, and document what the organization is doing about them.

## Features

- Limitation and validation tracking for Copilot Pages, Copilot Notebooks, SharePoint Embedded containers, and Loop storage patterns
- Compensating control registration for manual exports, access restrictions, enhanced audit logging, and review workflows
- Preservation exception tracking for documented limitations such as manual legal-hold container inclusion, retention-label handling, and review-set search constraints
- Platform update monitoring so supported capabilities and remaining limitations can be re-evaluated when Microsoft releases relevant changes
- Tier-aware configuration for baseline, recommended, and regulated deployments
- Evidence packaging for gap-findings, compensating-control-log, and preservation-exception-register

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not connect to Microsoft 365 APIs for Pages or Notebooks monitoring (scripts use representative sample data)
- ❌ Does not enforce preservation policies or Microsoft Purview eDiscovery holds automatically
- ❌ Does not register compensating controls automatically (registration framework is documented for manual use)
- ❌ Does not deploy Power Automate flows (gap notification workflows are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)
- ❌ Does not enforce Information Barriers for SharePoint Embedded content (the documented limitation is tracked for manual governance review)
- ❌ Does not cover departed-user / leaver workflow for Copilot Pages and Notebooks
- ❌ Does not track notebook sensitivity labeling limitations as a distinct gap category

## Architecture

The solution uses a documentation-first monitoring pattern:

1. Gap discovery identifies documented limitations and tenant validation items for Pages, Loop, and notebook content.
2. Gap classification maps each item to regulatory requirements and solution controls.
3. Compensating control registration documents the manual or administrative control used to reduce risk.
4. Preservation exception tracking records legal or compliance approval where a documented limitation requires manual governance.
5. Evidence export packages the current state into examiner-ready JSON artifacts.

The solution also depends on `06-audit-trail-manager` for supporting audit evidence and retention baseline context.

## Prerequisites

- Confirm that `06-audit-trail-manager` is deployed and that the current retention baseline has been reviewed.
- Review [docs/prerequisites.md](./docs/prerequisites.md) for the required Microsoft 365 licenses, compliance roles, and stakeholder approvals.
- Ensure compliance and legal owners are available to review preservation exceptions and compensating controls before the first regulated export.

## Quick Start

1. Review [prerequisites](./docs/prerequisites.md) and confirm dependency `06-audit-trail-manager` is deployed.
2. Run a baseline monitoring pass to record current validation items and documented limitations:
   `pwsh -File .\scripts\Monitor-Compliance.ps1 -ConfigurationTier baseline -OutputPath .\artifacts\baseline -PassThru`
3. Initialize the gap register for the selected governance tier:
   `pwsh -File .\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended -OutputPath .\artifacts\deployment`
4. Review the generated gap register with compliance and legal stakeholders.
5. Export the initial evidence package:
   `pwsh -File .\scripts\Export-Evidence.ps1 -ConfigurationTier regulated -OutputPath .\artifacts\evidence -PassThru`
6. Schedule a quarterly review cycle and a release-note review for Microsoft 365 updates that affect Pages, Loop, notebook retention, Microsoft Purview eDiscovery, legal hold, retention labels, or Information Barriers guidance.

## Solution Components

| Path | Purpose |
|------|---------|
| `scripts/Deploy-Solution.ps1` | Initializes the gap register, tier manifest, and documented limitation baseline |
| `scripts/Monitor-Compliance.ps1` | Assesses documented Pages, Loop, and notebook limitations and validates compensating controls |
| `scripts/Export-Evidence.ps1` | Exports gap-findings, compensating-control-log, and preservation-exception-register artifacts |
| `config/default-config.json` | Shared solution metadata, regulations, evidence outputs, and default review settings |
| `config/baseline.json` | Baseline monitoring configuration focused on discovery and documentation |
| `config/recommended.json` | Recommended monitoring configuration with compensating control expectations |
| `config/regulated.json` | Regulated monitoring configuration with preservation exception tracking and legal review controls |
| `docs/architecture.md` | Gap-monitor architecture, data flow, components, and platform limitations |
| `docs/deployment-guide.md` | Step-by-step deployment and review guidance |
| `docs/evidence-export.md` | Evidence schemas, packaging contract, and examiner notes |
| `docs/prerequisites.md` | Required licenses, roles, permissions, and dependency expectations |
| `docs/troubleshooting.md` | Known issues, workarounds, and review guidance |
| `tests/15-pages-notebooks-gap-monitor.Tests.ps1` | Pester validation for configuration, documentation, and script contract coverage |

## Deployment

Deploy the solution by initializing the selected tier with `Deploy-Solution.ps1`, running `Monitor-Compliance.ps1` to populate the initial gap register, reviewing the documented limitations and validation items with compliance and legal stakeholders, and then exporting the approved state with `Export-Evidence.ps1`. Because this solution is monitor-only, deployment focuses on documentation, review cadence, and preservation exception governance rather than tenant-side enforcement.

## Related Controls

| Control | Title | How this solution addresses it |
|---------|-------|--------------------------------|
| 2.11 | Copilot Pages Security and Sharing Controls | Monitors sharing-control limitations and documents compensating access restrictions |
| 3.2 | Data Retention Policies for Copilot Interactions | Records retention-policy validation items and manual preservation procedures for documented limitations |
| 3.3 | Microsoft Purview eDiscovery for Copilot-Generated Content | Tracks Pages, Notebooks, and Loop eDiscovery support limitations and review status |
| 3.11 | Record Keeping and Books-and-Records Compliance (SEC 17a-3/4, FINRA 4511) | Maintains the preservation exception register and books-and-records limitation log |

## Regulatory Alignment

This solution supports compliance with the following regulatory obligations by documenting limitations, validation items, and the controls used to manage residual risk:

- SEC 17a-4 for books-and-records preservation and electronic record retention
- FINRA 4511 for retention and supervisory recordkeeping expectations
- SOX 404 for internal control documentation, review, and evidence management

## Evidence Export

The evidence package contains three primary outputs:

- `gap-findings`
- `compensating-control-log`
- `preservation-exception-register`

Evidence is exported through the shared `Export-SolutionEvidencePackage` function and follows the repository evidence schema fields for `metadata`, `summary`, `controls`, and `artifacts`. Each export also includes a SHA-256 hash file for integrity verification.

## Known Limitations

- This solution is primarily monitor-only and documentation-led.
- It does not automate retention policy changes, legal hold actions, or Microsoft Purview eDiscovery configuration changes.
- Human review is required for all gap registrations, compensating control approvals, and preservation exception entries.
- Platform behavior for Copilot Pages, Copilot Notebooks, Loop, SharePoint Embedded retention, and Microsoft Purview eDiscovery can change over time and must be revalidated against current Microsoft guidance.
- Current Microsoft Learn guidance states that Purview retention policies configured for all SharePoint sites and Purview eDiscovery are supported for Copilot Pages and Notebooks. The remaining documented limitations include no full-text search in Purview review sets for `.page` files, manual legal-hold container addition per user, limited manual retention-label support, no Information Barriers for SharePoint Embedded content, and departed-user handling differences.
