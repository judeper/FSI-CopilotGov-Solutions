# Communication Compliance Configurator

> **Status:** Active (v0.1.0) | **Priority:** P1 | **Track:** D | **Solution Code:** CCC

## Overview

Communication Compliance Configurator configures and monitors Microsoft Purview Communication Compliance policies for Copilot-assisted communications in financial services. It publishes policy templates targeting AI-generated content, configures reviewer workflows, manages supervised communication lexicons, and tracks escalation queues to support FINRA 3110 supervision requirements.

This solution depends on `04-finra-supervision-workflow` for downstream review routing and escalation operating procedures. The solution is documentation-first for portal deployment because Microsoft Purview Communication Compliance policy publication still requires manual portal actions.

## Features

- Deploys tier-aware policy templates for Copilot-assisted retail and institutional communications.
- Manages supervised lexicon terms for AI disclosure, promotional language, best-interest phrasing, and conflict indicators.
- Documents reviewer assignment, SLA, escalation, and dual-review workflows.
- Captures reviewer queue metrics for pending items, review age, and escalations.
- Supports insider risk correlation planning for Copilot usage patterns and supervisory escalation.
- Packages evidence outputs aligned to the shared evidence schema and repository contracts.

## Architecture

The solution combines JSON configuration, PowerShell deployment and monitoring scripts, and documentation-first operating procedures:

- `config\*.json` defines governance-tier settings, monitored policies, reviewer workflow defaults, and lexicon words.
- `scripts\Deploy-Solution.ps1` generates policy templates and a deployment manifest for manual Purview configuration.
- `scripts\Monitor-Compliance.ps1` evaluates expected policy coverage, queue collection readiness, and lexicon status.
- `scripts\Export-Evidence.ps1` publishes evidence artifacts through `Export-SolutionEvidencePackage`.
- `docs\*.md` documents architecture, prerequisites, deployment steps, evidence expectations, and troubleshooting.
- `04-finra-supervision-workflow` provides the linked supervision process for escalations and reviewer actions.

See [docs/architecture.md](./docs/architecture.md) for the detailed data flow and integration model.

## Quick Start

1. Review [Prerequisites](./docs/prerequisites.md) and confirm Microsoft Purview Communication Compliance licensing and reviewer roles.
2. Review and customize tier settings under `config\default-config.json` and the selected tier file.
3. Generate a deployment manifest with `scripts\Deploy-Solution.ps1 -ConfigurationTier regulated -TenantId <tenant-guid> -WhatIf`.
4. Publish the generated policy templates manually in the Microsoft Purview compliance portal.
5. Run `scripts\Monitor-Compliance.ps1` to capture baseline reviewer queue readiness.
6. Run `scripts\Export-Evidence.ps1` to produce `policy-template-export`, `reviewer-queue-metrics`, and `lexicon-update-log`.

## Solution Components

| Path | Purpose |
|------|---------|
| `README.md` | Solution summary, controls, deployment overview, and evidence expectations |
| `CHANGELOG.md` | Version history for the solution package |
| `DELIVERY-CHECKLIST.md` | Deployment readiness, validation, and handover checklist |
| `config\default-config.json` | Shared solution metadata, reviewer defaults, integration settings, and evidence outputs |
| `config\baseline.json` | Baseline Communication Compliance monitoring settings |
| `config\recommended.json` | Recommended tier with escalations and insider risk correlation planning |
| `config\regulated.json` | Regulated tier with FINRA 3110 supervision, SEC Reg BI, and FCA SYSC 10 flags |
| `scripts\Deploy-Solution.ps1` | Tier-aware deployment manifest and policy template generator |
| `scripts\Monitor-Compliance.ps1` | Queue metrics stub, policy coverage checks, and lexicon status summary |
| `scripts\Export-Evidence.ps1` | Evidence artifact generator using the shared evidence export module |
| `docs\architecture.md` | Component model, data flow, security, and integration points |
| `docs\deployment-guide.md` | Step-by-step deployment instructions including manual Purview steps |
| `docs\evidence-export.md` | Evidence schemas, package contract, and control mapping guidance |
| `docs\prerequisites.md` | Licensing, role, dependency, and sign-off requirements |
| `docs\troubleshooting.md` | Common operational issues and examination-readiness troubleshooting |
| `tests\14-communication-compliance-config.Tests.ps1` | Pester validation for files, configuration, documentation, and script syntax |

## Prerequisites

- Microsoft Purview Communication Compliance licensing such as Microsoft 365 E5 Compliance or an equivalent add-on.
- Reviewer and administrator roles for Communication Compliance, Compliance Administrator, and read-only auditors.
- Legal and compliance review of supervised lexicon words before publication.
- `04-finra-supervision-workflow` deployed first so escalation procedures are documented.
- Access to repository shared modules under `scripts\common\`.

## Related Controls

| Control | Title | Solution Contribution |
|---------|-------|-----------------------|
| 2.10 | Insider Risk Detection for Copilot Usage Patterns | Defines insider risk correlation templates and reviewer escalation guidance for suspicious Copilot-assisted messaging patterns |
| 3.4 | Communication Compliance Monitoring | Publishes Purview policy templates and queue metrics collection procedures for monitored communications |
| 3.5 | FINRA Rule 2210 Compliance for Copilot-Drafted Communications | Targets promotional language, financial advice phrasing, and disclosure review in customer-facing drafts |
| 3.6 | Supervision and Oversight (FINRA Rule 3110 / SEC Reg BI) | Supports reviewer assignment, SLA tracking, escalation paths, and oversight evidence export |
| 3.9 | AI Disclosure, Transparency, and SEC Marketing Rule | Configures AI disclosure lexicons and policy templates for Copilot-attributed content |

## Regulatory Alignment

This solution supports compliance with the following regulatory expectations when combined with customer-specific operating procedures and Microsoft Purview capabilities:

- FINRA 2210 for communications standards and promotional material review.
- FINRA 3110 for supervisory review and escalation workflows.
- SEC Reg BI for best-interest and disclosure monitoring.
- FCA SYSC 10 for conflict-of-interest indicators and supervisory follow-up.

## Evidence Export

The solution publishes the following evidence outputs:

- `policy-template-export`
- `reviewer-queue-metrics`
- `lexicon-update-log`

Evidence packages include shared schema metadata, summary, controls, and artifact entries by using `scripts\common\EvidenceExport.psm1`.

## Known Limitations

- Communication Compliance policy deployment to Microsoft Purview requires manual portal steps; automation is partial.
- Queue metrics collection is implemented as a stub until a supported Purview or Graph endpoint is available for tenant automation.
- Lexicon changes require compliance-team review before production publication.
- Insider risk correlation depends on additional Insider Risk Management integration that is outside this solution package.
