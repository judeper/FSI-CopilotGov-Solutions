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
│  │  • Site sharing   │    │  • Load baseline  │               │
│  │  • List perms     │    │  • Capture current│               │
│  │  • Sharing links  │    │  • Compare & diff │               │
│  │  • External users │    │  • Risk classify  │               │
│  └──────────────────┘    └────────┬─────────┘               │
│          │                        │                          │
│          ▼                        ▼                          │
│  ┌──────────────────┐    ┌──────────────────┐               │
│  │  baselines/       │    │  Invoke-Drift    │               │
│  │  latest-baseline  │    │  Reversion.ps1   │               │
│  │  .json            │    │                   │               │
│  │                   │    │  • Approval gate  │               │
│  │  baseline-{ts}    │    │  • Auto-revert    │               │
│  │  .json            │    │  • Escalation     │               │
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

1. **Baseline capture** — `New-PermissionsBaseline.ps1` connects to SharePoint sites via PnP PowerShell and snapshots site-level sharing settings, unique permission entries on lists and libraries, sharing links, and external user access. The snapshot is saved as a timestamped JSON file with a `latest-baseline.json` pointer.

2. **Drift detection** — `Invoke-DriftScan.ps1` loads the latest baseline, captures the current permissions state using the same method, and performs a structured comparison. Changes are classified as ADDED (new permission entries), REMOVED (entries no longer present), or CHANGED (permission level modified).

3. **Risk classification** — Each drift item receives a risk score based on the type of change, the sensitivity of the affected site, and the scope of the permission (anonymous, external, organization-wide). Drift is classified as HIGH, MEDIUM, or LOW.

4. **Alert notification** — HIGH-risk drift triggers an alert summary via Microsoft Graph API (`POST /users/{approver}/sendMail`) to the configured alert recipient.

5. **Reversion workflow** — `Invoke-DriftReversion.ps1` processes the drift report against the `auto-revert-policy.json` configuration. Items eligible for auto-reversion are reverted and logged. Items requiring approval are queued to `pending-approvals.json` with email notification to approvers.

6. **Approval timeout** — If approval is not received within the configured `approvalWindowHours`, the item is escalated per the `onTimeout` policy (default: escalate to compliance officer).

7. **Evidence export** — `Export-DriftEvidence.ps1` formats the drift report, baseline snapshot, and reversion log into a compliance evidence package with CSV and summary JSON outputs, suitable for FFIEC and SEC examination response.

8. **Integrity verification** — All evidence artifacts include SHA-256 companion files for tamper detection.

## Drift Types

| Drift Type | Description | Example |
|-----------|-------------|---------|
| `ADDED` | New permission entry not in baseline | Guest user added to document library |
| `REMOVED` | Baseline entry no longer present | Site member group removed from list |
| `CHANGED` | Permission level modified | Contributor elevated to Full Control |

## Risk Classification

| Factor | Weight | Description |
|--------|--------|-------------|
| Anonymous sharing link added | +40 | Highest risk — unrestricted access |
| External user access granted | +30 | Guest or external identity added |
| Organization-wide sharing expanded | +20 | AllEmployees or broad internal scope |
| Permission level elevated | +15 | Read → Contribute, Contribute → Full Control |
| FSI data classifier match | +10–25 | Site contains trading, PII, or legal data |
| Multiple concurrent drifts | +5–15 | Burst of changes on single site |

## Reversion Modes

| Mode | Behavior |
|------|----------|
| `approval-gate` (default) | All drift items require manual approval before reversion |
| `auto-revert` | Drift items matching enabled risk tiers are automatically reverted |
| `detect-only` | Drift is detected and reported but no reversion actions are taken |

## Integration with Solution 02

Solution 02 provides the initial site inventory and oversharing risk classification. Solution 17 uses this as context for risk scoring — sites already flagged as HIGH risk by Solution 02 receive elevated risk scores when drift is detected.
