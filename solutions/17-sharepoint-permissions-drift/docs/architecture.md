# Architecture — SharePoint Permissions Drift Detection

## Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   Solution 17 — SPD                         │
│            SharePoint Permissions Drift Detection           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────┐    ┌──────────────────┐               │
│  │  New-Permissions  │    │  Invoke-Drift    │               │
│  │  Baseline.ps1     │───▶│  Scan.ps1        │               │
│  │                   │    │                   │               │
│  │  • Sample sharing │    │  • Load baseline  │               │
│  │  • Perm samples   │    │  • Sample drift   │               │
│  │  • Link examples  │    │  • Scope to sites │               │
│  │  • External ex.   │    │  • Risk classify  │               │
│  └──────────────────┘    └────────┬─────────┘               │
│          │                        │                          │
│          ▼                        ▼                          │
│  ┌──────────────────┐    ┌──────────────────┐               │
│  │  baselines/       │    │  Invoke-Drift    │               │
│  │  latest-baseline  │    │  Reversion.ps1   │               │
│  │  .json            │    │                   │               │
│  │                   │    │  • Approval queue │               │
│  │  baseline-{ts}    │    │  • Intent logging │               │
│  │  .json            │    │  • Timeout meta   │               │
│  └──────────────────┘    └────────┬─────────┘               │
│                                   │                          │
│                                   ▼                          │
│                          ┌──────────────────┐               │
│                          │  Export-Drift     │               │
│                          │  Evidence.ps1     │               │
│                          │                   │               │
│                          │  • CSV + JSON     │               │
│                          │  • SHA-256 hash   │               │
│                          │  • Regulatory pkg │               │
│                          └──────────────────┘               │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  Config Tiers: baseline │ recommended │ regulated           │
│  Upstream Dep: Solution 02 (Oversharing Risk Assessment)    │
└─────────────────────────────────────────────────────────────┘
```

## Core Data Flow

1. **Baseline capture** — `New-PermissionsBaseline.ps1` writes representative baseline snapshots for site-level sharing settings, unique permission entries, sharing links, and external user scenarios. The PnP block is illustrative; production tenant binding must add complete role-assignment, sharing-link, and external-user enumeration. Future tenant binding should leverage **SharePoint Advanced Management (SAM) Data Access Governance** reports — specifically the Permission state reports, Sharing links report, and EEEU (Everyone Except External Users) insights — as the authoritative backing capability for drift-state detection. The snapshot is saved as a timestamped JSON file with a `latest-baseline.json` pointer.

2. **Drift detection** — `Invoke-DriftScan.ps1` loads the latest baseline and returns representative sample drift scoped to baseline sites until tenant-bound current-state capture is added. `Compare-PermissionSet` documents a permission-entry comparison helper, but the scaffold main path does not perform live tenant comparison.

3. **Risk classification** — Each drift item receives a scaffold risk score based on drift type, permission level, and principal type. Classifier matches, multiple concurrent drift, and Solution 02 risk elevation are design factors for future tenant-bound scoring.

4. **Alert notification** — HIGH-risk drift can trigger an alert summary via Microsoft Graph API using `/me/sendMail` or `POST /users/{sender}/sendMail` to send to the configured alert recipient.

5. **Reversion workflow** — `Invoke-DriftReversion.ps1` processes the drift report against the `auto-revert-policy.json` configuration. Items eligible for auto-reversion are logged as reversion intent. Items requiring approval are queued to `pending-approvals.json` with optional email notification to approvers.

6. **Approval timeout** — Approval records include `approvalDeadline` and `onTimeout` metadata. Approval responses and timeout escalation require an external workflow to process `pending-approvals.json`.

7. **Evidence export** — `Export-DriftEvidence.ps1` formats the drift report, baseline snapshot, and reversion log into a compliance evidence package with CSV and summary JSON outputs for FFIEC and SEC examination response.

8. **Integrity verification** — Evidence artifacts, including CSV convenience exports, include SHA-256 companion files for tamper detection.

## Drift Types

| Drift Type | Description | Example |
|-----------|-------------|---------|
| `ADDED` | New permission entry not in baseline | Guest user added to document library |
| `REMOVED` | Baseline entry no longer present | Site member group removed from list |
| `CHANGED` | Permission level modified | Contributor elevated to Full Control |

## Risk Classification

| Factor | Scaffold status | Description |
|--------|-----------------|-------------|
| Permission level and principal type | Implemented in sample scoring | `Invoke-DriftScan.ps1` scores ADDED/REMOVED/CHANGED permission-entry samples using fixed factors. |
| Anonymous sharing link added | Future tenant-bound factor | Listed in `default-config.json` as an illustrative design weight until sharing-link comparison is added. |
| External user access granted | Implemented for sample principal type | External principals add risk in the scaffold scorer; live external-user comparison is pending. |
| Organization-wide sharing expanded | Future tenant-bound factor | Listed as an illustrative design weight until site-sharing comparison is added. |
| FSI data classifier match | Future tenant-bound factor | Requires integration with classification output before it affects scores. |
| Multiple concurrent drifts | Future tenant-bound factor | Requires aggregation across live drift results before it affects scores. |

## Reversion Modes

| Mode | Behavior |
|------|----------|
| `approval-gate` (default) | Drift items are queued for external approval workflow processing before reversion |
| `auto-revert` | Drift items matching enabled risk tiers are logged as scaffold reversion intent; live changes require tenant binding |
| `detect-only` | Drift is reported with no reversion-intent records |

## Integration with Solution 02

Solution 02 provides the reference pattern for site inventory and oversharing risk classification. In this scaffold, `Deploy-Solution.ps1` only checks whether the Solution 02 folder is present; elevating Solution 17 risk scores from Solution 02 output is a future tenant-bound integration step.
