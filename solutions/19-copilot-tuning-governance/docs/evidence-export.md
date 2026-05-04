# Evidence Export

## Evidence Package Overview

`Export-Evidence.ps1` writes a JSON package aligned to `..\..\data\evidence-schema.json`. The package includes metadata, summary details, control statuses, and references to the underlying evidence artifacts.

Every JSON evidence file receives a companion `.sha256` file so reviewers can verify integrity during internal review, audit preparation, or regulator response.

## Evidence Types

### tuning-requests

Inventory of Copilot Tuning requests submitted by business units, including approval status, data classification, and business justification.

Expected fields include:

- `requestId`
- `requestedBy`
- `businessUnit`
- `sourceDataDescription`
- `dataClassification`
- `intendedUse`
- `approvalStatus`
- `approvedBy`
- `submittedAt`

This evidence type is the main support artifact for demonstrating tuning oversight under control 1.16.

### model-inventory

Catalog of all tuned Copilot models with lifecycle status, owner assignment, and creation metadata.

Expected fields include:

- `modelId`
- `modelName`
- `status`
- `owner`
- `businessUnit`
- `createdAt`
- `lastReassessmentDate`
- `nextReassessmentDate`

This artifact shows that tuned models are being tracked and managed throughout their lifecycle.

### risk-assessments

Risk assessment records for tuning requests and active tuned models, documenting the evaluation criteria and outcomes.

Expected fields include:

- `assessmentId`
- `modelId`
- `assessedBy`
- `assessmentDate`
- `riskLevel`
- `dataRiskFactors`
- `modelRiskFactors`
- `outcome`
- `notes`

For regulated deployments, this artifact helps demonstrate that model risk management expectations are being addressed.

## Control Status Mapping by Evidence Type

| Evidence type | Primary controls supported | Typical status interpretation |
|---------------|----------------------------|-------------------------------|
| `tuning-requests` | 1.16 | Demonstrates tuning request governance, often `partial` until tenant-specific integration with supported Microsoft 365 admin center or Agent 365 experiences is implemented |
| `model-inventory` | 1.16, 3.8 | Shows active model lifecycle tracking and ownership assignment |
| `risk-assessments` | 3.8 | Demonstrates model risk assessment practices for tuned models |

## Standard Control Statuses Used by the Export Script

| Control | Status | Notes |
|---------|--------|-------|
| 1.16 | partial | Tuning governance patterns are documented but tenant-specific integration with supported Microsoft 365 admin center or Agent 365 experiences requires further implementation |
| 3.8 | monitor-only | Model risk management is supported through risk assessment patterns but not enforced directly by this script |

## Retention Note

Regulated tier deployments retain evidence for 2555 days and should preserve examiner-ready exports for OCC Bulletin 2011-12 (SR 11-7) review, legal hold support, and supervisory follow-up. Institutions should align final retention with their records schedule and legal guidance.

## Example Export

```powershell
.\scripts\Export-Evidence.ps1 `
  -ConfigurationTier regulated `
  -TenantId 00000000-0000-0000-0000-000000000000 `
  -OutputPath .\artifacts\evidence
```

Review the package summary before distributing evidence outside the governance team.
