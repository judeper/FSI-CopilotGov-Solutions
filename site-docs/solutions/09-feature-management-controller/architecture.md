# Architecture

## Purpose

Copilot Feature Management Controller (FMC) provides a centralized operating model for Copilot feature inventory, baseline management, rollout ring control, and drift detection across Microsoft 365, Teams, and Power Platform. The design is intended for financial services teams that need to stage Copilot capability enablement and preserve an evidence trail for supervisory review.

## Reference Architecture

```text
+------------------------------+    +----------------------+    +------------------+    +----------------------+
| Feature Inventory Collector  | -> | Baseline Comparator  | -> | Drift Detector   | -> | Alert / Remediation  |
|------------------------------|    |----------------------|    |------------------|    |----------------------|
| - Graph beta rollout policy  |    | - Approved settings  |    | - Mismatch score |    | - Teams notification |
| - Teams policy exports       |    | - Ring assignments   |    | - Drift type     |    | - Change task        |
| - Power Platform settings    |    | - Dataverse baseline |    | - Severity band  |    | - Rollback planning  |
+------------------------------+    +----------------------+    +------------------+    +----------------------+
```

## Component Detail

### 1. Feature Inventory Collector

The collector normalizes Copilot feature state from the following administrative surfaces:

- **Microsoft Graph beta:** `https://graph.microsoft.com/beta/policies/featureRolloutPolicies`
- **Microsoft 365 Admin Center:** feature policy and app-specific Copilot enablement settings
- **Teams Admin Center:** Teams meeting, chat, or app policy settings that control Copilot exposure
- **Power Platform Admin API:** environment and maker-facing Copilot settings for Power Apps and Power Automate

Each collected feature record is tagged with:

- feature ID and display name
- source system
- expected application coverage
- current ring assignment
- enabled or restricted state
- approval reference or supervisory owner

### 2. Baseline Comparator

The baseline comparator reads the approved tier definition and compares it to the collected feature inventory. The comparator is responsible for:

- identifying the approved enablement state for each tracked feature
- mapping each feature to Preview Ring, Early Adopters, General Availability, or Restricted
- storing approved baseline records in Dataverse
- preparing rollout plans for change-approved promotions or restrictions

### 3. Drift Detector

The drift detector evaluates differences between approved baseline state and observed tenant configuration. Drift logic covers:

- enablement mismatch
- ring mismatch
- unexpected application coverage
- missing feature records
- unmanaged third-party connector or plugin exposure

Drift findings are scored so operations teams can focus on the highest-risk deviations first.

### 4. Alert and Remediation Layer

The alerting layer converts drift findings into actionable outputs:

- Teams notification cards for threshold breaches
- Power Automate flows for change notification and escalation
- Dataverse findings records for remediation tracking
- evidence packages for auditors, risk teams, and supervisory review

## Platform Integrations

| Integration | Role in FMC | Notes |
|-------------|-------------|-------|
| Microsoft Graph beta `/policies/featureRolloutPolicies` | Source of rollout policy state and ring definition references | Used for inventory collection and planned ring updates. |
| Teams Admin Center | Source for Teams-specific Copilot policy coverage | Often requires export, documentation, or scripted collection depending on tenant tooling. |
| Power Platform Admin API | Source for Copilot in Power Apps and Power Automate settings | Used to confirm whether maker and runtime Copilot experiences align to approved tiers. |
| Dataverse | Persistent store for baseline, findings, and evidence metadata | Table names follow the FMC naming convention. |
| Power Automate | Notification and operational orchestration | Documentation-first until production import is approved. |

## Power Automate Flows

| Flow name | Trigger | Purpose |
|-----------|---------|---------|
| `FMC-DriftMonitor` | Hourly recurrence | Runs the drift comparison schedule, evaluates alert threshold, and records findings. |
| `FMC-RingPromotion` | On-demand | Documents a requested ring change, captures approval metadata, and triggers downstream rollout tasks. |
| `FMC-ChangeNotifier` | Change event or manual invocation | Sends operations, compliance, and service owner notifications when feature state changes. |

## Dataverse Tables

| Table | Purpose | Example fields |
|-------|---------|----------------|
| `fsi_cg_fmc_baseline` | Stores approved feature state and expected ring assignment | `featureid`, `displayname`, `sourcesystem`, `expectedring`, `expectedenabled`, `approvalreference`, `capturedat` |
| `fsi_cg_fmc_finding` | Stores drift findings and remediation status | `findingid`, `featureid`, `drifttype`, `severity`, `baselinevalue`, `observedvalue`, `status`, `detectedat` |
| `fsi_cg_fmc_evidence` | Stores export metadata and package references | `packageid`, `artifacttype`, `tier`, `generatedat`, `hash`, `storagepath` |

## Deployment Flow

1. Read tier configuration and required scopes.
2. Create a Graph context for the tenant and target environment.
3. Collect current Copilot feature state from supported admin surfaces.
4. Generate or refresh the approved baseline snapshot.
5. Apply or document rollout ring changes based on tier policy.
6. Deploy or document Power Automate flows.
7. Run ongoing drift detection and evidence export.

## Security and Governance Notes

- FMC supports compliance with SEC Reg FD by showing where Copilot features are exposed to user populations that may handle material non-public information.
- FMC supports compliance with FINRA 3110 by preserving supervisory review data, change intent, and drift findings.
- The design assumes change approval is stricter in the `regulated` tier than in `baseline` or `recommended`.
- Third-party connector and plugin exposure should be reviewed with solution 10 if deeper connector governance controls are required.
