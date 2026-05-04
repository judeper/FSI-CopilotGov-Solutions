# Generative AI Model Governance Monitor

> **Status:** Documentation-first scaffold | **Version:** v0.1.1 | **Priority:** P1 | **Track:** D

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../disclaimer.md) and [Documentation vs Runnable Assets Guide](../../documentation-vs-runnable-assets-guide.md).

## Overview

The Generative AI Model Governance Monitor (GMG) provides a documentation-first model risk management (MRM) monitoring framework for Microsoft 365 Copilot, Microsoft 365 Copilot Chat and agents, Microsoft Foundry projects, Azure OpenAI or Foundry model deployments, and approved Foundry partner or community model sources. It applies Federal Reserve SR 11-7 / OCC Bulletin 2011-12 model risk principles to fill the generative AI exclusion in SR 26-2 / OCC Bulletin 2026-13. The solution helps organizations register in-scope generative AI models in the model inventory, document validation scope adapted for vendor-supplied and platform-hosted generative models, record ongoing monitoring observations, record content safety and guardrail posture, and maintain third-party due diligence evidence for Microsoft and other approved model providers. GMG supports compliance with SR 11-7 / OCC Bulletin 2011-12 (interim genAI principles), the NIST AI Risk Management Framework 1.0, and ISO/IEC 42001 expectations for AI management systems.

## What This Solution Monitors

- Generative AI model inventory entries across Microsoft 365 Copilot, Copilot Chat, Copilot agents, Microsoft Foundry projects, Azure OpenAI or Foundry model deployments, and approved Foundry partner or community providers — provider, model family, model name/version, deployment type, region or cloud, lifecycle status, materiality tier, owner, and attestation freshness
- Validation scope adapted for vendor-supplied and platform-hosted generative AI models (conceptual soundness review, output testing, limitations log, and independent challenge where required)
- Ongoing monitoring observations — output sampling, user feedback signals, drift indicators, incident references, and escalation thresholds
- Content safety and guardrail posture — Azure AI Content Safety resource status, Prompt Shields, groundedness detection, protected-material detection, filter thresholds, exceptions, and review cadence where applicable
- Third-party due diligence on Microsoft and other approved model providers — documented controls, attestations, responsible AI or transparency references, and review cadence

## Features

| Capability | Description |
|------------|-------------|
| Generative AI model inventory pattern | Documents how to register Copilot, Foundry, Azure OpenAI, and approved partner/community model sources in the firm's model inventory; the script emits representative sample inventory records |
| Validation scope guidance | Provides an SR 11-7 / OCC 2011-12 validation scope adapted for vendor-supplied and platform-hosted generative models with limited transparency |
| Ongoing monitoring log | Records sampling cadence, escalation thresholds, and drift indicators for output review |
| Content safety and guardrails | Records Azure AI Content Safety, Prompt Shields, groundedness, protected-material, filter-threshold, exception, and review-cadence evidence where applicable |
| Third-party due diligence | Records vendor governance evidence reviewed from Microsoft and other approved providers (SOC reports, Responsible AI documentation, transparency notes, and provider attestations) on a periodic cadence |
| Tier-aware deployment | Applies baseline, recommended, or regulated cadence and rigor for inventory review, validation, guardrail review, and monitoring |
| Documentation-first automation | Describes manual workflow patterns for model risk committee review without requiring tenant-side automation in v0.1.1 |

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not query Microsoft Graph, Microsoft Purview, Microsoft Foundry, Azure OpenAI, Azure AI Content Safety, or any tenant API (scripts use representative sample data)
- ❌ Does not perform automated model output sampling against a live Copilot, Foundry, Azure OpenAI, or partner model deployment
- ❌ Does not deploy Dataverse tables for the model inventory (table contracts are documented for manual deployment)
- ❌ Does not submit validation reports to the model risk committee automatically
- ❌ Does not retrieve Microsoft or partner attestations, SOC reports, Responsible AI documentation, transparency notes, or content safety configuration directly
- ❌ Does not constitute an independent model validation by itself; firms must perform their own validation work

> **Data classification:** See [Data Classification Matrix](../../reference/data-classification.md) for residency, retention, and data-class metadata.

## Prerequisites

Review [docs/prerequisites.md](prerequisites.md) for the required admin roles, Azure and Microsoft 365 prerequisites, model inventory sources, PowerShell modules, and content safety prerequisites before deploying this solution.

## Architecture

The solution uses PowerShell scripts for deployment, monitoring, and evidence export; configuration files for tier-specific policy; and documentation-first guidance for manual model-risk workflows. See [docs/architecture.md](architecture.md) for the component diagram, data flow, and integration points.

## Deployment

1. Review [docs/prerequisites.md](prerequisites.md) and confirm the model risk operating model is in place.
2. Select the governance tier and review `config/<tier-name>.json` together with `config/default-config.json`.
3. Run `scripts\Deploy-Solution.ps1 -ConfigurationTier <tier> -WhatIf` to preview the deployment manifest.
4. Run `scripts\Monitor-Compliance.ps1 -ConfigurationTier <tier>` to record the initial inventory, monitoring, guardrail, and vendor-review snapshot from representative sample data.
5. Run `scripts\Export-Evidence.ps1 -ConfigurationTier <tier>` to package the five evidence artifacts with SHA-256 sidecars.

## Configuration Tiers

| Tier | Inventory Review | Validation Required | Monitoring Cadence | Third-Party Review |
|------|------------------|---------------------|--------------------|--------------------|
| baseline | Annual | Documented attestation | Quarterly | Annual |
| recommended | Semi-annual | Adapted SR 11-7 validation | Monthly | Semi-annual |
| regulated | Quarterly | Adapted SR 11-7 validation + independent challenge | Continuous (sampled) | Quarterly |

## Evidence Export

The solution exports five evidence artifacts (JSON + SHA-256 companion files):

- `copilot-model-inventory` — in-scope generative AI model entries, provider, model family/name/version, deployment type, region or cloud, lifecycle status, materiality, owners, intended use, attestation freshness, and validation status
- `validation-summary` — validation scope, methods, findings, and limitations for vendor-supplied or platform-hosted models
- `ongoing-monitoring-log` — monitoring observations, sampling cadence, drift indicators, and escalations
- `content-safety-and-guardrails` — Azure AI Content Safety, Prompt Shields, groundedness, protected-material, threshold, exception, and review-cadence evidence where applicable
- `third-party-due-diligence` — Microsoft and approved provider governance evidence and review cadence

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

- **SR 26-2 / OCC Bulletin 2026-13** — supersedes SR 11-7 and OCC Bulletin 2011-12 for traditional models; explicitly excludes generative AI from its scope. GMG documents Copilot and other tenant-approved generative AI model governance separately so firms can show how they continue to apply model-risk discipline to generative AI during the exclusion period.
- **Federal Reserve SR 11-7 / OCC Bulletin 2011-12 (interim genAI principles)** — continues to be applied to generative AI per supervisory guidance until a successor framework is issued. GMG aids in meeting the inventory, validation, and ongoing monitoring elements of SR 11-7 / OCC 2011-12 for Copilot, Foundry, Azure OpenAI, and approved provider model deployments.
- **NIST AI RMF 1.0** — GMG records align with the Govern, Map, Measure, and Manage functions for vendor-supplied and platform-hosted generative AI systems.
- **ISO/IEC 42001** — GMG evidence supports the AI management system control set for inventory, risk assessment, guardrail review, and supplier management.

GMG does not on its own satisfy any regulatory obligation. Use of this solution is recommended to support a broader model risk management program coordinated with the firm's model risk officer and compliance teams.

## Microsoft Learn References

- [What is Microsoft Foundry?](https://learn.microsoft.com/azure/ai-foundry/what-is-azure-ai-foundry) — Microsoft Learn, last updated 2026-04-29; notes that Foundry provides access to Microsoft, OpenAI, Anthropic, Mistral, xAI, Meta, DeepSeek, Hugging Face, and other models.
- [What is Azure AI Content Safety?](https://learn.microsoft.com/azure/ai-services/content-safety/overview) — Microsoft Learn, last updated 2025-09-16; describes Azure AI Content Safety and its prompt protection capabilities.

## Roadmap

Future versions may add:

- Live Microsoft Foundry, Azure OpenAI, Microsoft Purview, Azure AI Content Safety, or Microsoft Graph integration for inventory metadata, AI interaction audit events, guardrail configuration, usage, and incident telemetry
- Automated retrieval of Microsoft and approved provider attestations, Responsible AI documentation, transparency notes, and content safety configuration references
- Direct emission of validation findings to the model risk committee workflow
- Alignment updates if a successor framework supersedes the SR 11-7 / OCC 2011-12 interim approach for generative AI

## License and Contributing

See the repository root `LICENSE` and `CONTRIBUTING.md` for licensing and contribution guidance.
