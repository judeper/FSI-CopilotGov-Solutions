# Evidence Export

## Evidence Package Overview

`Export-Evidence.ps1` writes a JSON package aligned to `..\..\data\evidence-schema.json`. The package includes metadata, summary details, control statuses, and references to the underlying evidence artifacts.

Every JSON evidence file receives a companion `.sha256` file so reviewers can verify integrity during internal review, audit preparation, or regulator response.

## Evidence Types

### oversharing-findings

Primary inventory of detected oversharing conditions across SharePoint, OneDrive, and Teams-backed content.

Expected fields include:

- `siteUrl`
- `workloadType`
- `riskTier`
- `exposureType`
- `permissionAnomalyCount`
- `recommendedAction`

This evidence type is the main support artifact for demonstrating repeated detection activity under controls 1.2 and 1.6.

### remediation-queue

Operational list of sites or items queued for follow-up.

Expected fields include:

- `queueId`
- `siteUrl`
- `workloadType`
- `priority`
- `riskTier`
- `assignedTo`
- `targetDate`
- `status`

This artifact shows that findings are being prioritized and routed, not merely observed.

### site-owner-attestations

Owner acknowledgement and sign-off records collected after remediation or risk acceptance.

Expected fields include:

- `siteUrl`
- `owner`
- `attestationStatus`
- `requestedOn`
- `dueBy`
- `remediationTicket`
- `notes`

For regulated deployments, this artifact helps demonstrate that business ownership and remediation closure were documented.

### sensitivity-label-coverage

Microsoft Purview Information Protection label coverage across scanned sites.

Expected fields include:

- `totalSitesScanned`
- `sitesWithLabels`
- `sitesWithoutLabels`
- `labelCoveragePercent`
- `reportingPeriodStart`
- `reportingPeriodEnd`
- `recommendation`

This artifact supports control 1.7 by reporting which sites have sensitivity labels applied. Sites without labels may expose regulated content via Microsoft 365 Copilot.

## Control Status Mapping by Evidence Type

| Evidence type | Primary controls supported | Typical status interpretation |
|---------------|----------------------------|-------------------------------|
| `oversharing-findings` | 1.2, 1.6, 2.5 | Detection and monitoring evidence, often `partial` or `monitor-only` until tenant APIs are fully implemented |
| `remediation-queue` | 1.2, 1.3, 1.4, 2.12 | Shows governance response and prioritization for search scope, permissions, and external sharing |
| `site-owner-attestations` | 1.2, 1.4, 2.12 | Demonstrates owner involvement, exception handling, and post-remediation review |
| `sensitivity-label-coverage` | 1.7 | Reports Microsoft Purview Information Protection label coverage across scanned sites |

## Standard Control Statuses Used by the Export Script

| Control | Status | Notes |
|---------|--------|-------|
| 1.2 | partial | DSPM for AI provides partial native coverage, but full-tenant oversharing detection still requires local workflow tuning |
| 1.3 | monitor-only | The solution records readiness and planned enablement for Restricted SharePoint Search but does not enforce tenant state on its own |
| 1.4 | partial | Semantic index governance is supported through scoped findings and remediation planning |
| 2.5 | monitor-only | Data minimization is monitored through broad-access findings and recommended actions |
| 2.12 | partial | External sharing and guest access governance is captured in findings and remediation workflow stubs |
| 1.6 | monitor-only | Permission model anomalies are surfaced and counted for follow-up |
| 1.7 | monitor-only | Sensitivity label coverage is derived from Microsoft Purview Information Protection data and reported as a standalone artifact. Sites without labels may expose regulated content via Microsoft 365 Copilot |

## Retention Note

Regulated tier deployments retain evidence for 2555 days and should preserve examiner-ready exports for SEC Reg S-P review, legal hold support, and supervisory follow-up. Institutions should align final retention with their records schedule and legal guidance.

## Example Export

```powershell
.\scripts\Export-Evidence.ps1 `
  -ConfigurationTier regulated `
  -TenantId 00000000-0000-0000-0000-000000000000 `
  -OutputPath .\artifacts\evidence `
  -PeriodStart (Get-Date).AddDays(-30) `
  -PeriodEnd (Get-Date) `
  -IncludeAttestations
```

Review the package summary before distributing evidence outside the governance team.
