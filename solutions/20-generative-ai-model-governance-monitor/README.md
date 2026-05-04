# Generative AI Model Governance Monitor

> **Status:** Documentation-first scaffold | **Version:** v0.1.0 | **Priority:** P1 | **Track:** D

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](../../docs/documentation-vs-runnable-assets-guide.md).

## Overview

The Generative AI Model Governance Monitor (GMG) provides a documentation-first model risk management (MRM) monitoring framework for Microsoft 365 Copilot. It applies Federal Reserve SR 11-7 / OCC Bulletin 2011-12 model risk principles to fill the generative AI exclusion in SR 26-2 / OCC Bulletin 2026-13. The solution helps organizations register Copilot in the model inventory, document validation scope adapted for vendor-supplied generative models, record ongoing monitoring observations, and capture third-party due diligence evidence for Microsoft as the model provider. GMG supports compliance with SR 11-7 / OCC Bulletin 2011-12 (interim genAI principles), the NIST AI Risk Management Framework 1.0, and ISO/IEC 42001 expectations for AI management systems.

## What This Solution Monitors

- Copilot model inventory entries — model identifier, version, intended use, materiality tier, and owner
- Validation scope adapted for vendor-supplied generative AI models (conceptual soundness review, output testing, limitations log)
- Ongoing monitoring observations — output sampling, user feedback signals, drift indicators, incident references
- Third-party due diligence on Microsoft as the model provider — documented controls, attestations, and review cadence

## Features

| Capability | Description |
|------------|-------------|
| Copilot model inventory pattern | Documents how to register Copilot, its underlying foundation models, and connected agents in the firm's model inventory; the script emits a representative sample inventory record |
| Validation scope guidance | Provides an SR 11-7 / OCC 2011-12 validation scope adapted for vendor-supplied generative models with limited transparency |
| Ongoing monitoring log | Captures sampling cadence, escalation thresholds, and drift indicators for Copilot output review |
| Third-party due diligence | Records vendor governance evidence collected from Microsoft (SOC reports, Responsible AI documentation, Copilot transparency notes) on a periodic cadence |
| Tier-aware deployment | Applies baseline, recommended, or regulated cadence and rigor for inventory review, validation, and monitoring |
| Documentation-first automation | Describes manual workflow patterns for model risk committee review without requiring tenant-side automation in v0.1.0 |

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not query Microsoft Graph, Purview, or any tenant API (scripts use representative sample data)
- ❌ Does not perform automated model output sampling against a live Copilot deployment
- ❌ Does not deploy Dataverse tables for the model inventory (table contracts are documented for manual deployment)
- ❌ Does not submit validation reports to the model risk committee automatically
- ❌ Does not retrieve Microsoft attestations, SOC reports, or Responsible AI documentation directly
- ❌ Does not constitute an independent model validation by itself; firms must perform their own validation work

> **Data classification:** See [Data Classification Matrix](../../docs/reference/data-classification.md) for residency, retention, and data-class metadata.

## Prerequisites

Review [docs/prerequisites.md](docs/prerequisites.md) for the required admin roles, PowerShell modules, and Microsoft 365 prerequisites before deploying this solution.

## Architecture

The solution uses PowerShell scripts for deployment, monitoring, and evidence export; configuration files for tier-specific policy; and documentation-first guidance for manual model-risk workflows. See [docs/architecture.md](docs/architecture.md) for the component diagram, data flow, and integration points.

## Deployment

1. Review [docs/prerequisites.md](docs/prerequisites.md) and confirm the model risk operating model is in place.
2. Select the governance tier and review `config/<tier-name>.json` together with `config/default-config.json`.
3. Run `scripts\Deploy-Solution.ps1 -ConfigurationTier <tier> -WhatIf` to preview the deployment manifest.
4. Run `scripts\Monitor-Compliance.ps1 -ConfigurationTier <tier>` to capture the initial inventory and monitoring snapshot from representative sample data.
5. Run `scripts\Export-Evidence.ps1 -ConfigurationTier <tier>` to package the four evidence artifacts with SHA-256 sidecars.

## Configuration Tiers

| Tier | Inventory Review | Validation Required | Monitoring Cadence | Third-Party Review |
|------|------------------|---------------------|--------------------|--------------------|
| baseline | Annual | Documented attestation | Quarterly | Annual |
| recommended | Semi-annual | Adapted SR 11-7 validation | Monthly | Semi-annual |
| regulated | Quarterly | Adapted SR 11-7 validation + independent challenge | Continuous (sampled) | Quarterly |

## Evidence Export

The solution exports four evidence artifacts (JSON + SHA-256 companion files):

- `copilot-model-inventory` — model entries, materiality, owners, intended use, and validation status
- `validation-summary` — validation scope, methods, findings, and limitations for vendor models
- `ongoing-monitoring-log` — monitoring observations, sampling cadence, drift indicators, and escalations
- `third-party-due-diligence` — Microsoft vendor governance evidence and review cadence

## Related Controls

| Control | Title | Coverage |
|---------|-------|----------|
| 3.8a | Generative AI Model Risk Management (planned control) | Primary |
| 3.8 | AI Model Governance and Risk Assessment | Primary |
| 3.1 | AI Acceptable Use Policy | Supporting |
| 3.11 | Third-Party AI Provider Risk Assessment | Supporting |
| 3.12 | AI Incident Response and Reporting | Supporting |

> **Playbooks:** Control implementation playbooks are maintained in the FSI-CopilotGov framework repository under `docs/playbooks/control-implementations/`.

## Regulatory Alignment

GMG supports compliance with the following regulatory and standards frameworks:

- **SR 26-2 / OCC Bulletin 2026-13** — supersedes SR 11-7 and OCC Bulletin 2011-12 for traditional models; explicitly excludes generative AI from its scope. GMG documents Copilot governance separately so firms can show how they continue to apply model-risk discipline to generative AI during the exclusion period.
- **Federal Reserve SR 11-7 / OCC Bulletin 2011-12 (interim genAI principles)** — continues to be applied to generative AI per supervisory guidance until a successor framework is issued. GMG aids in meeting the inventory, validation, and ongoing monitoring elements of SR 11-7 / OCC 2011-12 for Copilot.
- **NIST AI RMF 1.0** — GMG records align with the Govern, Map, Measure, and Manage functions for a vendor-supplied generative AI system.
- **ISO/IEC 42001** — GMG evidence supports the AI management system control set for inventory, risk assessment, and supplier management.

GMG does not on its own satisfy any regulatory obligation. Use of this solution is recommended to support a broader model risk management program coordinated with the firm's model risk officer and compliance teams.

## Roadmap

Future versions may add:

- Live Microsoft Graph or Purview integration for Copilot usage and incident telemetry
- Automated retrieval of Microsoft attestations and Responsible AI documentation references
- Direct emission of validation findings to the model risk committee workflow
- Alignment updates if a successor framework supersedes the SR 11-7 / OCC 2011-12 interim approach for generative AI

## License and Contributing

See the repository root `LICENSE` and `CONTRIBUTING.md` for licensing and contribution guidance.
