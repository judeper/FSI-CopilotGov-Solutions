# Prerequisites

## Microsoft 365 Requirements

- Microsoft 365 E3 or E5 tenant with Copilot licensing for the population in scope
- Documented Copilot deployment scope (Copilot Chat, Copilot in apps, Copilot Agents) for inventory registration
- Microsoft Purview audit, data classification, eDiscovery, DLP, and related compliance review processes identified for future AI interaction evidence

## Azure, Foundry, and Content Safety Requirements

- Azure account and subscription identified for Microsoft Foundry, Azure OpenAI, or Azure AI Content Safety resources in scope
- Microsoft Foundry access for the projects, agents, model deployments, and model catalog entries that must be represented in the model inventory
- Read-only inventory source for Azure OpenAI or Foundry model deployments, including provider, model family, deployment type, region or cloud, lifecycle or preview status, owner, and attestation review dates
- Azure AI Content Safety resource in a supported region when Foundry or Azure OpenAI deployments require content safety evidence
- Documented guardrail configuration source for Prompt Shields, groundedness detection, protected-material detection, filter thresholds, exceptions, and review cadence where applicable

## PowerShell Requirements

- PowerShell 7.2 or later
- Pester 5.x for running the included smoke tests

The repository scripts are documentation-first and do not require Microsoft Graph SDK, Azure PowerShell, or Azure CLI modules in v0.1.1.

## Operating Model Requirements

- Model risk officer or equivalent role assigned and accountable for AI model risk
- Model risk committee review cadence defined and documented
- Third-party risk management process able to receive vendor governance evidence on the configured cadence
- Content safety and guardrail review owner assigned for Foundry, Azure OpenAI, and approved provider model deployments
- AI incident response procedure documented for control 3.12 escalation handling

## Roles

Use least-privilege role assignments appropriate to the live integration scope when the documentation-first scaffold is adapted for a tenant:

- Model Risk Officer — owner of inventory and validation review
- Compliance Administrator or workload-specific Microsoft Purview roles — review of audit, data classification, eDiscovery, DLP, monitoring evidence, and regulatory mapping
- AI Reader — read-only review of Microsoft 365 Copilot and AI-related enterprise service configuration where available
- AI Administrator — Microsoft 365 Copilot and AI-related enterprise service administration when configuration changes are explicitly approved
- Azure Reader or resource-specific read roles — read-only inventory evidence for Microsoft Foundry, Azure OpenAI, and Azure AI Content Safety resources
- Cognitive Services Users or resource-specific Azure AI Content Safety roles — content safety evidence review where the implementation requires resource access
- Third-Party Risk Manager — owner of Microsoft and approved provider governance review
- Global Administrator — reserved for tenant-wide consent or configuration tasks that explicitly require it; not recommended for routine evidence review

## Reference Documents

Operators are recommended to gather the following before completing tier-specific reviews:

- Federal Reserve SR 11-7 and OCC Bulletin 2011-12 supervisory guidance
- SR 26-2 / OCC Bulletin 2026-13 — note the explicit generative AI exclusion
- NIST AI RMF 1.0
- ISO/IEC 42001
- Microsoft Responsible AI documentation and Copilot transparency notes
- Microsoft Foundry project, model deployment, and model catalog references for in-scope Azure resources
- Azure AI Content Safety configuration, Prompt Shields, groundedness, protected-material, threshold, and exception references where applicable
- Microsoft and approved provider SOC reports, transparency notes, model cards, or attestations applicable to in-scope services

## Microsoft Learn References

- [What is Microsoft Foundry?](https://learn.microsoft.com/azure/ai-foundry/what-is-azure-ai-foundry) — Microsoft Learn, last updated 2026-04-29; states that operators need an Azure account and then sign in to Microsoft Foundry.
- [What is Azure AI Content Safety?](https://learn.microsoft.com/azure/ai-services/content-safety/overview) — Microsoft Learn, last updated 2025-09-16; lists Azure subscription and Content Safety resource prerequisites.
- [Microsoft Entra built-in roles](https://learn.microsoft.com/entra/identity/role-based-access-control/permissions-reference) — Microsoft Learn, last updated 2026-04-29; documents AI Administrator and AI Reader roles for Microsoft 365 Copilot and AI-related enterprise services.
