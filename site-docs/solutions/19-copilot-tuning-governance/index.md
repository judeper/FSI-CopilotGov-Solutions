# Copilot Tuning Governance

> **Status:** Documentation-first scaffold | **Version:** v0.1.0 | **Priority:** P1 | **Track:** A

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../disclaimer.md) and [Documentation vs Runnable Assets Guide](../../documentation-vs-runnable-assets-guide.md).

## Overview

This solution provides a framework for governing Microsoft 365 Copilot Tuning, a feature available to organizations with 5,000 or more Copilot licenses that allows creation of fine-tuned AI agents from proprietary organizational data. Copilot Tuning introduces model risk management challenges that are especially significant in regulated financial services because custom-tuned models may produce outputs that diverge from baseline Copilot behavior.

The solution documents governance patterns for tuning approval workflows, model inventory tracking, risk assessment gates, and evidence export so institutions can demonstrate oversight of tuned model lifecycles. It addresses the operational challenge that tuning requests may originate from multiple business units without centralized visibility into what data is being used, who approved the tuning job, and whether the resulting agent meets regulatory expectations.

Configuration tiers allow institutions to start with tuning disabled (baseline), progress to tuning with approval gates (recommended), and adopt full model risk management controls for examination readiness (regulated).

## Features

- Tuning request approval workflow documentation with multi-level sign-off patterns
- Model inventory tracking for all tuned Copilot agents with lifecycle status
- Risk assessment gate patterns for pre-tuning data review and post-tuning validation
- Tiered governance configuration: disabled, approval-gated, and full model risk management
- Evidence export packages for tuning-requests, model-inventory, and risk-assessments
- Alignment with model risk management frameworks referenced by OCC Bulletin 2011-12 (SR 11-7)

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not connect to M365 Admin Center or Copilot Tuning APIs (scripts use representative sample data)
- ❌ Does not perform live tuning, create tuned models, or submit tuning jobs to any tenant
- ❌ Does not validate tuning outputs, evaluate model accuracy, or measure drift from baseline behavior
- ❌ Does not deploy Power Automate flows (approval workflow designs are documented, not exported)
- ❌ Does not enforce data classification or sensitivity labeling on tuning source data
- ❌ Does not replace organizational model risk management programs or third-party model validation tools
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)

> **Data classification:** See [Data Classification Matrix](../../reference/data-classification.md) for residency, retention, and data-class metadata.

## Architecture

See [docs/architecture.md](architecture.md) for the component diagram, data flow, tuning lifecycle, and governance gate details.

## Prerequisites

- Review [docs/prerequisites.md](prerequisites.md) and confirm the required admin roles, PowerShell modules, and Copilot licensing are in place.
- Confirm the organization has 5,000 or more Microsoft 365 Copilot licenses, which is the minimum threshold for Copilot Tuning eligibility.
- Confirm model risk management stakeholders have been identified for tuning approval workflows.

## Quick Start

1. Review [docs/prerequisites.md](prerequisites.md) and confirm the required admin roles, licensing, and model risk management stakeholders.
2. Select the appropriate governance tier from `config\baseline.json`, `config\recommended.json`, or `config\regulated.json`.
3. Run `scripts\Deploy-Solution.ps1 -ConfigurationTier <tier> -TenantId <tenant-guid>` to validate configuration and create the deployment manifest.
4. Run `scripts\Monitor-Compliance.ps1` to check tuning governance compliance status using sample data.
5. Run `scripts\Export-Evidence.ps1` to package evidence artifacts and SHA-256 companion files.

## Deployment

Deploy this solution before enabling Copilot Tuning in any tenant. Start with the baseline tier (tuning disabled) to establish governance controls, then progress to the recommended tier after approval workflows and model inventory processes are validated with stakeholders. See [docs/deployment-guide.md](deployment-guide.md) for the full deployment sequence.

## Solution Components

| Path | Purpose |
|------|---------|
| `scripts\Deploy-Solution.ps1` | Loads configuration, validates prerequisites, and writes a deployment manifest |
| `scripts\Monitor-Compliance.ps1` | Monitors tuning governance compliance status and reports coverage gaps |
| `scripts\Export-Evidence.ps1` | Packages tuning requests, model inventory, and risk assessments with checksums |
| `config\default-config.json` | Shared defaults for controls, tuning governance settings, and evidence output |
| `config\baseline.json` | Minimum viable rollout with tuning disabled |
| `config\recommended.json` | Production posture with tuning approval gates and model inventory |
| `config\regulated.json` | Examination-ready posture with full model risk management controls |
| `docs\*.md` | Architecture, deployment, prerequisites, evidence, and troubleshooting guidance |
| `tests\19-CopilotTuningGovernance.Tests.ps1` | Pester validation for structure, content, and script syntax |

## Related Controls

> **Coverage state** (per [Control Coverage Honesty](../../reference/control-coverage-honesty.md)):
> 1 control(s) is **evidence-export-ready** in scaffold form: 1.16.

| Control | Status Focus | How this solution supports the control |
|---------|--------------|----------------------------------------|
| 1.16 | Primary | Provides a framework for governing Copilot Tuning request approval, model inventory, and lifecycle management |
| 3.8 | Supporting | Helps meet model risk management expectations by documenting tuning oversight, risk assessment gates, and evidence export patterns |

## Regulatory Alignment

This solution supports compliance with GLBA 501(b), OCC Bulletin 2011-12 (SR 11-7), Interagency AI Guidance (2023), and the EU AI Act by documenting repeatable governance patterns for Copilot Tuning request approval, model inventory tracking, risk assessment gates, and evidence export. It is designed to help regulated institutions demonstrate governance intent, model risk oversight, and examiner-ready recordkeeping without making absolute compliance claims.

## Evidence Export

Evidence packages align to `..\..\data\evidence-schema.json` and include:

- `tuning-requests`
- `model-inventory`
- `risk-assessments`

Each JSON artifact is written with a companion `.sha256` file so control evidence can be verified during audit preparation, internal assurance reviews, and regulator response exercises.

## Known Limitations

- The scripts use implementation stubs and sample data until tenant-specific Copilot Tuning API calls are connected.
- Copilot Tuning availability depends on organizational license count and Microsoft feature rollout timelines.
- Model risk assessment patterns are documented but do not replace institutional model validation programs required by SR 11-7.
- Tuning approval workflow patterns are documented but require Power Automate or equivalent implementation for production use.
