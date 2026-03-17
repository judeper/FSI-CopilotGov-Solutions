# Evidence Export

## Evidence Package Overview

`Export-Evidence.ps1` writes a JSON package aligned to `..\..\data\evidence-schema.json`. The package includes metadata, summary details, control statuses, and references to the underlying evidence artifacts.

Every JSON evidence file receives a companion `.sha256` file so reviewers can verify integrity during internal review, audit preparation, or regulator response.

## Evidence Types

### item-oversharing-findings

Primary inventory of detected item-level oversharing conditions within SharePoint document libraries.

Expected fields include:

- `siteUrl`
- `libraryName`
- `itemPath`
- `itemType`
- `sharedWith`
- `shareType`
- `sensitivityLabel`
- `lastModified`

This evidence type is the main support artifact for demonstrating item-level detection activity under controls 1.2 and 2.5.

### risk-scored-report

FSI risk-scored report with tier classifications and content-type weighting applied.

Expected fields include:

- `siteUrl`
- `libraryName`
- `itemPath`
- `shareType`
- `sensitivityLabel`
- `riskTier`
- `baseScore`
- `weightedScore`
- `contentCategory`

This artifact shows that items are being classified using FSI-specific risk criteria, not just raw permission data.

### remediation-actions

Operational log of remediation actions taken or pending approval.

Expected fields include:

- `actionId`
- `siteUrl`
- `itemPath`
- `shareType`
- `riskTier`
- `action`
- `status`
- `approvalRequired`
- `approvedBy`
- `executedAt`
- `notes`

This artifact demonstrates that findings are being prioritized and acted upon with appropriate governance controls.

## Control Status Mapping by Evidence Type

| Evidence type | Primary controls supported | Typical status interpretation |
|---------------|----------------------------|-------------------------------|
| `item-oversharing-findings` | 1.2, 2.5 | Detection and monitoring evidence, often `partial` or `monitor-only` until tenant APIs are fully implemented |
| `risk-scored-report` | 1.2, 1.4, 1.6 | Shows FSI risk classification and content-type weighting for governance prioritization |
| `remediation-actions` | 1.2, 1.3, 2.5 | Demonstrates governance response and approval-gated remediation for overshared items |

## Standard Control Statuses Used by the Export Script

| Control | Status | Notes |
|---------|--------|-------|
| 1.2 | partial | Item-level detection extends site-level coverage but requires tenant PnP connectivity for full enumeration |
| 1.3 | monitor-only | Supports Restricted SharePoint Search planning by identifying overshared items but does not enforce tenant state |
| 1.4 | partial | Semantic index governance is supported through item-level findings and risk prioritization |
| 1.6 | monitor-only | Permission model anomalies at the item level are surfaced and scored for follow-up |
| 2.5 | partial | Data minimization is supported through detection and approval-gated remediation of overshared items |

## Retention Note

Regulated tier deployments retain evidence for 2555 days and should preserve examiner-ready exports for SEC Reg S-P review, legal hold support, and supervisory follow-up. Institutions should align final retention with their records schedule and legal guidance.

## Example Export

```powershell
.\scripts\Export-Evidence.ps1 `
  -ConfigurationTier regulated `
  -TenantId 00000000-0000-0000-0000-000000000000 `
  -OutputPath .\artifacts\evidence `
  -PeriodStart (Get-Date).AddDays(-30) `
  -PeriodEnd (Get-Date)
```

Review the package summary before distributing evidence outside the governance team.
