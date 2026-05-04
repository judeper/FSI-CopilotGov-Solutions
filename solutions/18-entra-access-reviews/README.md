# Entra Access Reviews Automation

> **Status:** Documentation-first scaffold | **Version:** v0.1.1 | **Priority:** P1 | **Track:** A

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](../../docs/documentation-vs-runnable-assets-guide.md).

## Overview

This solution provides a framework for coordinating Microsoft Entra ID Access Reviews for Microsoft 365 groups, security groups, or access packages that grant access to SharePoint sites whose content Microsoft 365 Copilot can surface during grounded responses. Direct SharePoint site permissions require a separate inventory and remediation pattern. The framework addresses the operational challenge that manual review scheduling does not scale when an institution has hundreds or thousands of site-associated resources with varying sensitivity levels.

Microsoft Entra ID Access Reviews allow organizations to periodically verify that users still require access to specific resources. By automating the creation and management of these reviews, institutions can help meet regulatory expectations for periodic access recertification at a cadence proportional to each site's risk profile.

The solution reads risk scores from solution 02-oversharing-risk-assessment to prioritize which site-associated Microsoft Entra resources receive access reviews first, setting review cadence based on the mapped site risk tier: HIGH-risk resources are reviewed every 30 days, MEDIUM-risk every 90 days, and LOW-risk every 180 days. This risk-triage approach helps compliance teams focus attention on sites that pose the greatest exposure to regulated data.

Integration with solution 02 provides the upstream oversharing findings that drive prioritization. Integration with solution 16 (if available) supports broader access governance workflows. The review lifecycle covers creation, monitoring, decision collection, and evidence export for audit preparation.

## Features

- Risk-triaged access review definition patterns for Microsoft Entra resources associated with SharePoint access
- Cadence scheduling by risk tier: HIGH (30-day), MEDIUM (90-day), LOW (180-day) review cycles
- Resource or site owner assignment as primary reviewer, with compliance officer fallback
- Review results collection and expiry monitoring with 48-hour escalation alerts
- Decision application workflow for deny outcomes on the reviewed Microsoft Entra resource with evidence logging
- Orchestrator script for end-to-end review lifecycle management
- Evidence export packages for access-review-definitions, review-decisions, and applied-actions

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not connect to Microsoft Graph or Microsoft Entra ID APIs by default (scripts use representative sample data; an optional live Graph path exists with fallback to sample data when authentication is not provided)
- ❌ Does not create or modify access reviews in any tenant by default (review definitions are documented; optional live execution requires explicit authentication and Graph permissions)
- ❌ Does not directly remove SharePoint site permissions or apply deny decisions automatically (decision application is documented, not enforced)
- ❌ Does not deploy Power Automate flows (escalation and notification designs are documented, not exported)
- ❌ Does not replace Microsoft Entra ID Governance licensing or Privileged Identity Management workflows
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)

## Architecture

See [docs/architecture.md](docs/architecture.md) for the component diagram, data flow, review lifecycle, and integration points with upstream solutions.

## Prerequisites

- Review [docs/prerequisites.md](docs/prerequisites.md) and confirm the required admin roles, PowerShell modules, and Microsoft Entra ID Governance licensing are in place.
- Verify that solution [02-oversharing-risk-assessment](../02-oversharing-risk-assessment/) has produced risk-scored site output that can be used to prioritize review creation for mapped Microsoft Entra resources.
- Confirm Microsoft Entra ID Governance or Microsoft Entra Suite subscriptions are available for the target tenant; use Microsoft Entra ID P2 only for access review scenarios where Microsoft Learn documents P2 support.

## Quick Start

1. Review [docs/prerequisites.md](docs/prerequisites.md) and confirm the required admin roles, PowerShell modules, and API access are in place.
2. Verify that solution [02-oversharing-risk-assessment](../02-oversharing-risk-assessment/) has produced risk-scored output.
3. Select the appropriate governance tier from `config\baseline.json`, `config\recommended.json`, or `config\regulated.json`.
4. Run `scripts\Deploy-Solution.ps1 -ConfigurationTier <tier> -TenantId <tenant-guid>` to validate configuration and create the deployment manifest.
5. Run `scripts\New-AccessReview.ps1` to generate access review definitions based on risk-scored site-to-resource mappings.
6. Run `scripts\Get-ReviewResults.ps1` to collect pending and completed review decisions.
7. Run `scripts\Export-Evidence.ps1` to package evidence artifacts and SHA-256 companion files.

## Deployment

Deploy this solution after upstream oversharing risk assessment has completed and risk scores are available. Start with resources mapped to HIGH-risk sites using the baseline tier, then expand to MEDIUM and LOW tiers after validating the review workflow with stakeholders. See [docs/deployment-guide.md](docs/deployment-guide.md) for the full deployment sequence.

## Solution Components

| Path | Purpose |
|------|---------|
| `scripts\New-AccessReview.ps1` | Prepares Microsoft Entra ID Access Review definitions for group memberships associated with SharePoint access using Microsoft Graph access review patterns |
| `scripts\Get-ReviewResults.ps1` | Queries active access review decisions and flags reviews approaching expiry |
| `scripts\Apply-ReviewDecisions.ps1` | Applies completed review decisions to the reviewed Microsoft Entra resource and logs deny actions to evidence |
| `scripts\Invoke-RiskTriagedReviews.ps1` | Orchestrates the full review lifecycle: risk read, create, collect, apply, export |
| `scripts\Deploy-Solution.ps1` | Loads configuration, checks upstream readiness, and writes a deployment manifest |
| `scripts\Monitor-Compliance.ps1` | Monitors access review compliance status and reports coverage gaps |
| `scripts\Export-Evidence.ps1` | Packages review definitions, decisions, and applied actions with checksums |
| `config\default-config.json` | Shared defaults for controls, review cadence, and evidence output |
| `config\review-schedule.json` | Risk-tier review frequency and duration settings |
| `config\reviewer-mapping.json` | Reviewer assignment rules by site sensitivity |
| `config\baseline.json` | Minimum viable rollout focused on resources mapped to HIGH-risk sites |
| `config\recommended.json` | Production posture with multi-tier reviews and escalation |
| `config\regulated.json` | Examination-ready posture with extended retention and attestation |
| `docs\*.md` | Architecture, deployment, prerequisites, evidence, and troubleshooting guidance |
| `tests\18-entra-access-reviews.Tests.ps1` | Pester validation for structure, content, and script syntax |

## Dependency on 02-oversharing-risk-assessment

Solution 18 depends on risk-scored site output from solution 02-oversharing-risk-assessment. The risk scores drive prioritization so that Microsoft Entra resources mapped to HIGH-risk sites receive access reviews first and at the highest cadence. The deployment workflow checks for upstream evidence so reviews are anchored to documented oversharing findings.

## Related Controls

| Control | Status Focus | How this solution supports the control |
|---------|--------------|----------------------------------------|
| 1.2 | Primary | Supports periodic access recertification for Microsoft Entra resource memberships that grant SharePoint access exposed to Copilot grounding |
| 1.6 | Supporting | Helps meet permission model audit requirements through scheduled access reviews |
| 2.5 | Primary | Supports data minimization by documenting deny decisions and applied membership changes on reviewed Microsoft Entra resources |
| 2.12 | Primary | Surfaces guest and external user access for periodic recertification and cleanup |

## Regulatory Alignment

This solution supports compliance with GLBA 501(b), SEC Reg S-P, FINRA Rule 4511, SOX 302/404, and the FFIEC IT Handbook by documenting repeatable access review creation, decision tracking, and evidence export patterns for Microsoft Entra resource memberships that grant SharePoint access. It is designed to help regulated institutions demonstrate governance intent, periodic access recertification, and examiner-ready recordkeeping without making absolute compliance claims.

## Evidence Export

Evidence packages align to `..\..\data\evidence-schema.json` and include:

- `access-review-definitions`
- `review-decisions`
- `applied-actions`

Each JSON artifact is written with a companion `.sha256` file so control evidence can be verified during audit preparation, internal assurance reviews, and regulator response exercises.

## Known Limitations

- The scripts use implementation stubs and sample data until tenant-specific Microsoft Entra ID Governance API calls are connected.
- Access review scope is limited to Microsoft Entra group or access-package memberships mapped to SharePoint access; direct SharePoint site permissions require separate inventory and remediation patterns.
- Reviewer resolution depends on site owner information being available and accurate in SharePoint site properties.
- Auto-apply of deny decisions is intentionally gated behind configuration approval because FSI institutions typically require business-owner review before removing access to regulated content.
