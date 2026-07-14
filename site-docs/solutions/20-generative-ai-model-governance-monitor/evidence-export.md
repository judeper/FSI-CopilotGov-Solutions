# Evidence Export Guide

## Evidence Types

### copilot-model-inventory

Records each in-scope generative AI model entry as carried in the firm's model inventory, including Microsoft 365 Copilot, Copilot agents, Microsoft Foundry projects, Azure OpenAI or Foundry model deployments, and approved Foundry partner or community provider models.

**Schema fields**

- `modelId` — internal inventory identifier
- `modelSource` — source category such as `microsoft365copilot`, `foundry`, `azureopenai`, or `partner`
- `modelName` — product, deployment, or catalog model name
- `modelFamily` — model family or service family
- `modelVersion` — version, model ID, or release wave reference
- `modelProvider` — Microsoft, Microsoft / OpenAI, or approved provider name
- `deploymentType` — Microsoft 365 service, Foundry direct model, Azure OpenAI deployment, partner/community model, or agent deployment type
- `regionOrCloud` — tenant region, Azure region, or provider cloud scope
- `lifecycleStatus` — generally available, preview, approved-for-evaluation, approved-for-production, deprecated, or retired
- `contentSafetyProfile` — applicable content safety or guardrail profile reference
- `responsibleAiReference` — Responsible AI, transparency, or provider attestation reference
- `intendedUse` — approved use cases
- `materialityTier` — firm-assigned model materiality (high, medium, low)
- `owner` — accountable business owner
- `validationStatus` — attestation, validated, validated-with-limitations, pending
- `attestationLastReviewedAt` — last provider or model attestation review timestamp
- `attestationNextReviewDue` — next attestation review due timestamp
- `lastReviewedAt` — last inventory review timestamp

### validation-summary

Records the validation scope and findings adapted for vendor-supplied or platform-hosted generative AI models.

**Schema fields**

- `modelId`
- `validationApproach` — adapted SR 11-7 / OCC 2011-12 scope description
- `conceptualSoundnessNotes`
- `outputTestingScope`
- `limitationsLog`
- `findings` — list of validation findings
- `independentChallengeStatus`
- `nextValidationDue`

### ongoing-monitoring-log

Records ongoing monitoring observations.

**Schema fields**

- `observationId`
- `observedAt`
- `samplingCadence`
- `outputSampleSize`
- `highRiskOutputCount`
- `userFeedbackSignal`
- `driftIndicator`
- `escalation` — referenced incident or escalation identifier when present
- `notes`

### content-safety-and-guardrails

Records content safety and guardrail evidence for in-scope model deployments. Azure OpenAI deployments in Microsoft Foundry use default configurable Guardrail policies (hate/fairness, sexual, violence, self-harm, and other supported controls where enabled). For non-Azure-OpenAI Foundry/provider deployments, record provider/deployment-native guardrails only where Microsoft/provider documentation and read-only portal surfaces confirm them. Azure AI Content Safety is a separate optional standalone service; the `contentSafetyResourceStatus` field is recorded only where that standalone service is used.

**Schema fields**

- `guardrailProfileId` — internal profile or policy identifier
- `contentSafetyResourceStatus` — Azure AI Content Safety resource status or applicability note
- `promptShields` — Prompt Shields policy/configuration status
- `groundednessDetection` — groundedness detection status where supported
- `protectedMaterialDetection` — protected-material detection status where supported
- `filterThresholds` — configured moderation thresholds by category
- `reviewCadenceDays` — expected guardrail review cadence
- `exceptions` — approved exceptions or references to exception records
- `lastValidatedAt` — most recent guardrail validation timestamp

### third-party-due-diligence

Records vendor governance evidence reviewed for Microsoft and applicable Foundry partner or community providers.

**Schema fields**

- `vendor` — Microsoft or approved provider name
- `reviewCycle` — annual, semi-annual, quarterly
- `lastReviewedAt`
- `nextReviewDue`
- `evidenceReferences` — list of reviewed artifacts (SOC report, Responsible AI documentation, Copilot transparency notes, provider transparency notes, model cards, or attestations)
- `openItems`
- `reviewer`

## Package Contract

Each artifact is written as a JSON file with a SHA-256 companion file (`.sha256`). The file contents include:

- `solution`
- `tier`
- `generatedAt`
- `runtimeMode` — always `local-stub` in v0.1.3
- `warning` — note that the artifact contains representative sample data
- `records` — list of artifact-specific records

## Control Mappings

| Control | Primary Evidence | How GMG Supports Compliance |
|---------|------------------|-----------------------------|
| 3.8a | `copilot-model-inventory`, `validation-summary`, `content-safety-and-guardrails` | Documents model registration, validation scope, and guardrail posture adapted for generative AI under the SR 11-7 / OCC 2011-12 interim approach |
| 3.8 | `copilot-model-inventory`, `validation-summary`, `content-safety-and-guardrails` | Helps meet AI model governance and risk assessment expectations for vendor-supplied and platform-hosted models |
| 3.1 | `copilot-model-inventory`, `content-safety-and-guardrails` | Provides material to support AI acceptable use review by referencing intended use, materiality, and guardrail expectations |
| 3.11 | `third-party-due-diligence` | Aids in third-party AI provider review cadence for Microsoft and approved model providers |
| 3.12 | `ongoing-monitoring-log`, `content-safety-and-guardrails` | Records monitoring observations, guardrail exceptions, and escalation references for AI incident response workflows |

## Microsoft Learn References

- [Foundry Models sold by Azure](https://learn.microsoft.com/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure) — Microsoft Learn (verified 2026-07-14); states that Foundry Models sold by Azure include all Azure OpenAI models and selected models from top providers, alongside the separate Foundry Models from partners and community category.
- [Default Guardrail policies for Azure OpenAI - Microsoft Foundry](https://learn.microsoft.com/en-us/azure/foundry/openai/concepts/default-safety-policies) — Microsoft Learn (verified 2026-07-14); documents default configurable Guardrail policies for Azure OpenAI in Microsoft Foundry, including hate/fairness, sexual, violence, self-harm, and other supported controls.
- [What is Azure AI Content Safety?](https://learn.microsoft.com/azure/ai-services/content-safety/overview) — Microsoft Learn, last updated 2025-09-16; documents the separate standalone Azure AI Content Safety service and moderation APIs.

## Examiner Notes

The evidence package is recommended to be reviewed alongside the firm's broader model risk management policy, the Copilot acceptable use policy, the content safety and guardrail standard, and the third-party risk management framework. GMG does not on its own satisfy SR 11-7 / OCC Bulletin 2011-12, NIST AI RMF 1.0, or ISO/IEC 42001 obligations; firms should validate that the artifacts complete the evidence set required by their internal program.
