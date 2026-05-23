# Evidence Export — SharePoint Permissions Drift Detection

## Evidence Package Overview

Solution 17 produces three categories of evidence artifacts suitable for regulatory examination response, internal audit, and compliance attestation.

All evidence artifacts include SHA-256 companion files (`.sha256`) for integrity verification.

## Evidence Types

### 1. Drift Report (`drift-report`)

Detailed record of representative permissions changes relative to the approved baseline pattern.

| Field | Description |
|-------|-------------|
| `siteUrl` | SharePoint site associated with the representative drift item |
| `itemPath` | Specific list, library, or item path |
| `driftType` | ADDED, REMOVED, or CHANGED |
| `before` | Permission state in baseline |
| `after` | Representative post-drift permission state |
| `riskScore` | Numeric risk score (0–100) |
| `riskTier` | HIGH, MEDIUM, or LOW |
| `detectedAt` | ISO 8601 timestamp of detection |
| `reversionStatus` | Intended workflow status such as approval-pending or reversion-intent logged |

### 2. Baseline Snapshot (`baseline-snapshot`)

Point-in-time record of the approved permissions state used as the comparison reference.

| Field | Description |
|-------|-------------|
| `capturedAt` | ISO 8601 timestamp of baseline capture |
| `siteUrl` | SharePoint site URL |
| `sharingSettings` | Representative site-level sharing configuration; live comparison requires tenant binding |
| `uniquePermissions` | List and library entries with unique (broken inheritance) permissions in scaffold samples |
| `sharingLinks` | Representative sharing-link examples until live link enumeration is added |
| `externalUsers` | Representative external-user examples until live external-user enumeration is added |

### 3. Reversion Log (`reversion-log`)

Record of scaffold reversion intent and approval-gated items; live actions require tenant binding or an external workflow.

| Field | Description |
|-------|-------------|
| `siteUrl` | SharePoint site affected |
| `itemPath` | Specific item path |
| `reversionType` | auto-reverted or manual-approved |
| `driftType` | Original drift classification |
| `beforeReversion` | Permission state before reversion |
| `afterReversion` | Permission state after reversion |
| `actionedBy` | User or system account associated with the reversion-intent record |
| `actionedAt` | ISO 8601 timestamp of reversion-intent logging |
| `approvalId` | Reference to approval record (if approval-gated) |

## Control Status Mapping

| Control ID | Evidence Type | Status |
|------------|--------------|--------|
| 1.2 | drift-report | `partial` — documents drift detection pattern for site sharing |
| 1.4 | drift-report | `partial` — documents external user access drift detection |
| 1.6 | drift-report | `partial` — documents unique permission entry tracking |
| 2.5 | reversion-log | `monitor-only` — documents reversion workflow pattern |

## Standard Control Statuses Used

| Status | Meaning |
|--------|---------|
| `partial` | Control is addressed by documentation and sample data; tenant binding required for full coverage |
| `monitor-only` | Solution detects and reports but does not enforce; remediation requires manual or approved action |

## Retention

| Tier | Retention (days) |
|------|-----------------|
| baseline | 365 |
| recommended | 730 |
| regulated | 2555 (7 years) |

Retention values align with FINRA Rule 4511 record-keeping requirements and SEC Rule 17a-4 retention schedules.

## Example Export

```powershell
.\scripts\Export-DriftEvidence.ps1 `
    -DriftReportPath "./reports/drift-report-20250101T120000.json" `
    -BaselinePath "./baselines/latest-baseline.json" `
    -OutputPath "./evidence"
```

This produces:

```
evidence/
├── drift-findings.csv
├── drift-findings.csv.sha256
├── drift-findings.json
├── drift-findings.json.sha256
├── evidence-summary.json
├── evidence-summary.json.sha256
├── baseline-snapshot.json
├── baseline-snapshot.json.sha256
├── reversion-log.json
└── reversion-log.json.sha256
```
