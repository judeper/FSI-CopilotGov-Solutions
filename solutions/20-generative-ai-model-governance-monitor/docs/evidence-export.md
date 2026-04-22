# Evidence Export Guide

## Evidence Types

### copilot-model-inventory

Records each Copilot model entry as carried in the firm's model inventory.

**Schema fields**

- `modelId` — internal inventory identifier
- `modelName` — Microsoft product name (for example, Microsoft 365 Copilot)
- `modelVersion` — version or release wave reference
- `modelProvider` — vendor (Microsoft)
- `intendedUse` — approved use cases
- `materialityTier` — firm-assigned model materiality (high, medium, low)
- `owner` — accountable business owner
- `validationStatus` — attestation, validated, validated-with-limitations, pending
- `lastReviewedAt` — last inventory review timestamp

### validation-summary

Records the validation scope and findings adapted for a vendor-supplied generative AI model.

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

### third-party-due-diligence

Records vendor governance evidence collected from Microsoft.

**Schema fields**

- `vendor` — Microsoft
- `reviewCycle` — annual, semi-annual, quarterly
- `lastReviewedAt`
- `nextReviewDue`
- `evidenceReferences` — list of reviewed artifacts (SOC report, Responsible AI documentation, Copilot transparency notes)
- `openItems`
- `reviewer`

## Package Contract

Each artifact is written as a JSON file with a SHA-256 companion file (`.sha256`). The file contents include:

- `solution`
- `tier`
- `generatedAt`
- `runtimeMode` — always `local-stub` in v0.1.0
- `warning` — note that the artifact contains representative sample data
- `records` — list of artifact-specific records

## Control Mappings

| Control | Primary Evidence | How GMG Supports Compliance |
|---------|------------------|-----------------------------|
| 3.8a | `copilot-model-inventory`, `validation-summary` | Documents Copilot model registration and validation scope adapted for generative AI under the SR 11-7 / OCC 2011-12 interim approach |
| 3.8 | `copilot-model-inventory`, `validation-summary` | Helps meet AI model governance and risk assessment expectations for vendor-supplied models |
| 3.1 | `copilot-model-inventory` | Provides material to support AI acceptable use review by referencing intended use and materiality |
| 3.11 | `third-party-due-diligence` | Aids in third-party AI provider review cadence for Microsoft as the model provider |
| 3.12 | `ongoing-monitoring-log` | Captures monitoring observations and escalation references for AI incident response workflows |

## Examiner Notes

The evidence package is recommended to be reviewed alongside the firm's broader model risk management policy, the Copilot acceptable use policy, and the third-party risk management framework. GMG does not on its own satisfy SR 11-7 / OCC Bulletin 2011-12, NIST AI RMF 1.0, or ISO/IEC 42001 obligations; firms should validate that the artifacts complete the evidence set required by their internal program.
