# Evidence Export

## Evidence Package Overview

`Export-Evidence.ps1` writes a JSON package aligned to `..\..\data\evidence-schema.json`. The package includes metadata, summary details, control statuses, and references to the underlying evidence artifacts.

Every JSON evidence file receives a companion `.sha256` file so reviewers can verify integrity during internal review, audit preparation, or regulator response.

## Evidence Types

### access-review-definitions

Inventory of Microsoft Entra ID Access Review definitions for groups or access packages associated with SharePoint access, including risk tier, review cadence, reviewer assignment, and scope configuration.

Expected fields include:

- `reviewDefinitionId`
- `siteUrl`
- `riskTier`
- `reviewFrequencyDays`
- `reviewDurationDays`
- `reviewer`
- `scope`
- `createdAt`

This evidence type is the main support artifact for demonstrating periodic access review scheduling under controls 1.2 and 1.6.

### review-decisions

Pending and completed access review decisions collected from active review instances.

Expected fields include:

- `reviewDefinitionId`
- `instanceId`
- `decisionId`
- `userId`
- `userDisplayName`
- `decision`
- `reviewedBy`
- `reviewedAt`
- `justification`

This artifact shows that access reviews are being conducted and decisions are being recorded for the reviewed Microsoft Entra resource.

### applied-actions

Records of deny decisions applied to reviewed Microsoft Entra resources, such as group memberships or access package assignments, that may affect SharePoint access when those resources grant site access.

Expected fields include:

- `reviewDefinitionId`
- `instanceId`
- `userId`
- `action`
- `appliedAt`
- `appliedBy`
- `siteUrl`
- `notes`

For regulated deployments, this artifact helps demonstrate that access review outcomes are being applied to the reviewed Microsoft Entra resource and documented.

## Control Status Mapping by Evidence Type

| Evidence type | Primary controls supported | Typical status interpretation |
|---------------|----------------------------|-------------------------------|
| `access-review-definitions` | 1.2, 1.6 | Demonstrates periodic review scheduling, often `partial` until tenant API integration is fully implemented |
| `review-decisions` | 1.2, 2.5, 2.12 | Shows active recertification and decision tracking for mapped Microsoft Entra resource membership |
| `applied-actions` | 1.2, 2.5, 2.12 | Documents applied deny decisions and membership changes on reviewed Microsoft Entra resources |

## Standard Control Statuses Used by the Export Script

| Control | Status | Notes |
|---------|--------|-------|
| 1.2 | partial | Access review definitions are created but tenant-specific API integration requires further implementation |
| 1.6 | monitor-only | Permission model audits are supported through scheduled reviews but not enforced directly by this script |
| 2.5 | monitor-only | Data minimization is supported by documenting deny decisions and applied membership changes |
| 2.12 | partial | Guest and external user access can be included through Microsoft Graph group-scope filters for periodic recertification |

## Retention Note

Regulated tier deployments retain evidence for 2555 days and should preserve examiner-ready exports for SEC Reg S-P review, legal hold support, and supervisory follow-up. Institutions should align final retention with their records schedule and legal guidance.

## Example Export

```powershell
.\scripts\Export-Evidence.ps1 `
  -ConfigurationTier regulated `
  -TenantId 00000000-0000-0000-0000-000000000000 `
  -OutputPath .\artifacts\evidence
```

Review the package summary before distributing evidence outside the governance team.
