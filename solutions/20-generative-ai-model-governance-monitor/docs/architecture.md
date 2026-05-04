# Generative AI Model Governance Monitor Architecture

## Solution Overview

The Generative AI Model Governance Monitor (GMG) provides a documentation-first model risk management (MRM) monitoring pattern for Microsoft 365 Copilot, Copilot Chat and agents, Microsoft Foundry projects, Azure OpenAI or Foundry model deployments, and approved Foundry partner or community model sources. It applies Federal Reserve SR 11-7 / OCC Bulletin 2011-12 principles to generative AI systems during the period in which SR 26-2 / OCC Bulletin 2026-13 explicitly excludes generative AI from its scope.

## Component Diagram

```text
+-----------------------------------------------------------------------+
| Manual operator input (sample inventory, monitoring, and guardrail data) |
+----------------------------------+------------------------------------+
                                   |
                                   v
+----------------------------------+------------------------------------+
| Monitor-Compliance.ps1                                                |
| - Inventory snapshot builder (representative sample)                  |
| - Foundry/Azure OpenAI/provider source fields                         |
| - Validation status check                                             |
| - Ongoing monitoring observations                                     |
| - Content safety and guardrail posture                                |
| - Third-party due diligence cadence check                             |
+----------------------------------+------------------------------------+
                                   |
                                   v
+----------------------------------+------------------------------------+
| Export-Evidence.ps1                                                   |
| - copilot-model-inventory                                             |
| - validation-summary                                                  |
| - ongoing-monitoring-log                                              |
| - content-safety-and-guardrails                                       |
| - third-party-due-diligence                                           |
| - JSON + SHA-256 sidecars                                             |
+-----------------------------------------------------------------------+
                                   |
                                   v
+-----------------------------------------------------------------------+
| Manual handoff to model risk committee and compliance review          |
+-----------------------------------------------------------------------+
```

## Data Flow

1. The operator selects a governance tier and runs `Deploy-Solution.ps1` to produce a deployment manifest reflecting the inventory review cadence, validation requirement, monitoring cadence, guardrail review expectation, and third-party review cadence.
2. `Monitor-Compliance.ps1` builds representative sample inventory records for Microsoft 365 Copilot, Copilot agents, Microsoft Foundry projects, Azure OpenAI or Foundry model deployments, and approved Foundry partner or community provider sources, then records validation, monitoring, content safety, guardrail, and vendor-review status.
3. `Export-Evidence.ps1` writes five JSON evidence artifacts and a SHA-256 sidecar for each.
4. The artifacts are reviewed by the model risk officer and the model risk committee through manual workflow steps documented in `docs/deployment-guide.md`.

## Components

### Inventory Snapshot Builder

Documents how in-scope generative AI models are registered in the firm's model inventory. The current repository version emits representative sample inventory records with source, provider, model family/name/version, deployment type, region or cloud, lifecycle status, owner, materiality, and attestation freshness fields so the structure can be reviewed before live data is available.

### Validation Status Check

Records the validation scope adapted for vendor-supplied and platform-hosted generative AI models. Because provider-hosted foundation model parameters may not be exposed, validation activity is limited to conceptual soundness review, output testing on representative use cases, content safety and guardrail review, and a documented limitations log.

### Ongoing Monitoring

Records sampling cadence, output review observations, user feedback signals, drift indicators, and escalation thresholds. The repository version uses sample data; live integration with Microsoft Purview, Microsoft Graph, Microsoft Foundry, Azure OpenAI, or Azure AI Content Safety is deferred.

### Content Safety and Guardrails

Records the expected Azure AI Content Safety and guardrail evidence for in-scope Foundry and Azure OpenAI deployments, including Prompt Shields, groundedness detection, protected-material detection, filter thresholds, exception status, review cadence, and last validation timestamp where applicable.

### Third-Party Due Diligence

Records the cadence and content of vendor governance review for Microsoft and other approved model providers. Reviewers should reference Microsoft's published Responsible AI documentation, SOC reports, Copilot transparency notes, and provider-specific transparency or attestation artifacts where applicable.

## Integration Points (Future)

These integrations are documented but not implemented in v0.1.1:

- **Microsoft Foundry / Azure Resource Manager inventory metadata** — project, deployment, model family, deployment type, region or cloud, lifecycle, and owner attributes for Foundry and Azure OpenAI resources
- **Azure AI Content Safety** — resource status, Prompt Shields, groundedness, protected-material, and filter-threshold configuration evidence for model deployments where applicable
- **Microsoft Purview Audit / unified audit log** — Copilot and AI interaction audit events to support sampling and investigation; future implementations may use Microsoft Purview Audit search and the Audit Search Graph API where available
- **Microsoft Purview** — AI interaction auditing, data classification for prompts/responses, sensitivity-label context for source or cited content, eDiscovery, and DLP review
- **Microsoft Sentinel** — alert correlation for AI incident response (control 3.12)
- **Dataverse model inventory tables** — structured persistence for inventory and validation records

## Dataverse Tables (Reserved Names)

- `fsi_cg_genai_model_governance_inventory`
- `fsi_cg_genai_model_governance_validation`
- `fsi_cg_genai_model_governance_monitoring`
- `fsi_cg_genai_model_governance_vendor_review`

## Security Considerations

- Treat the model inventory, prompt/response review references, guardrail configuration, and validation findings as sensitive material; restrict access to model risk and compliance roles.
- Preserve evidence immutability for regulated deployments using the storage account environment variable `GMG_IMMUTABLE_STORAGE_ACCOUNT`.
- Avoid embedding any user-prompt content in evidence artifacts unless the firm's data classification policy allows it.

## Regulatory Alignment Notes

GMG is designed to support compliance with SR 11-7 / OCC Bulletin 2011-12 model-risk principles for generative AI, which continue to be applied as interim guidance after SR 26-2 / OCC Bulletin 2026-13 excluded generative AI from its scope. The solution does not on its own constitute model validation; it organizes the artifacts the model risk officer and validation team need to perform that work.

## Microsoft Learn References

- [What is Microsoft Foundry?](https://learn.microsoft.com/azure/ai-foundry/what-is-azure-ai-foundry) — Microsoft Learn, last updated 2026-04-29; describes Foundry as unifying agents, models, tools, tracing, monitoring, evaluations, RBAC, networking, and policies.
- [Use Microsoft Purview to manage data security and compliance for Microsoft 365 Copilot and Microsoft 365 Copilot Chat](https://learn.microsoft.com/purview/ai-m365-copilot) — Microsoft Learn, last updated 2026-05-01; documents unified audit log capture and Purview data classification for prompts and responses.
- [What is Azure AI Content Safety?](https://learn.microsoft.com/azure/ai-services/content-safety/overview) — Microsoft Learn, last updated 2025-09-16; describes content safety, Prompt Shields, groundedness detection, and protected-material detection capabilities.
