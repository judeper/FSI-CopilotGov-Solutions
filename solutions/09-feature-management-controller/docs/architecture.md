# Architecture

## Purpose

Copilot Feature Management Controller (FMC) provides a centralized operating model for Copilot feature inventory, baseline management, rollout ring control, and drift detection across Microsoft 365, Teams, and Power Platform. The design is intended for financial services teams that need to stage Copilot capability enablement and preserve an evidence trail for supervisory review.

## Reference Architecture

```text
+------------------------------+    +----------------------+    +------------------+    +----------------------+
| Feature Inventory Collector  | -> | Baseline Comparator  | -> | Drift Detector   | -> | Alert / Remediation  |
|------------------------------|    |----------------------|    |------------------|    |----------------------|
| - M365 admin settings   |    | - Approved settings  |    | - Mismatch score |    | - Teams notification |
| - Teams policy exports       |    | - Ring assignments   |    | - Drift type     |    | - Change task        |
| - Power Platform settings    |    | - Dataverse baseline |    | - Severity band  |    | - Rollback planning  |
+------------------------------+    +----------------------+    +------------------+    +----------------------+
```

## Component Detail

### 1. Feature Inventory Collector

The collector normalizes Copilot feature state from the following administrative surfaces:

- **Microsoft 365 admin center:** feature policy and app-specific Copilot enablement settings
- **Cloud Policy service:** the documented `Allow web search in Copilot` policy state and group scope
- **Teams admin center:** documented Teams meeting/event and calling policy settings; Teams chat/channel Copilot inventory remains documentation-first unless a current admin control is cited
- **Power Platform admin center:** Copilot settings and administrative exports for Power Apps, with Power Automate Copilot interpreted through the documented tenant-level limitation

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
| Microsoft 365 admin center | Source for Microsoft 365 Copilot feature and app settings | Used as the primary documented source for tenant Copilot feature inventory. |
| Cloud Policy service | Source for `Allow web search in Copilot` policy state and scope | Used to document whether web search is allowed for approved user groups. |
| Teams admin center | Source for documented Teams meeting/event and calling policy coverage | Teams chat/channel Copilot inventory is documentation-first unless a current admin control is cited. |
| Power Platform admin center | Source for Copilot settings and administrative exports for Power Apps and tenant-level Power Automate settings | Power Automate Copilot environment-level disablement is not represented as available where Microsoft Learn says it is unavailable. |
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

1. Read tier configuration and required admin surfaces.
2. Prepare documentation-first admin context metadata for the tenant and target environment.
3. Collect or document current Copilot feature state from supported admin surfaces.
4. Generate or refresh the approved baseline snapshot.
5. Apply or document rollout ring changes based on tier policy.
6. Deploy or document Power Automate flows.
7. Run ongoing drift detection and evidence export.

## Security and Governance Notes

- FMC supports compliance with SEC Reg FD by showing where Copilot features are exposed to user populations that may handle material non-public information.
- FMC supports compliance with FINRA 3110 by preserving supervisory review data, change intent, and drift findings.
- The design assumes change approval is stricter in the `regulated` tier than in `baseline` or `recommended`.
- Third-party connector and plugin exposure should be reviewed with solution 10 if deeper connector governance controls are required.

## Web Grounding Governance

FMC extends feature management governance to cover the documented `Allow web search in Copilot` policy in Cloud Policy service. The repository models web-search policy state and group scope; live configuration remains a tenant activity performed through Microsoft admin tooling.

### Documented Web Search Policy

The `Allow web search in Copilot` policy controls whether Copilot can use public web content during response generation. FMC governance templates document:

- Group-controlled web-search policy state aligned to rollout ring definitions
- Regulated tier guidance that recommends disabling web search for populations handling sensitive or material non-public information
- Baseline and recommended tier guidance that permits web search only where policy scope and approval are documented

### Customer-Defined Web Grounding Metadata

Domain categories, excluded domains, and authoritative-source review notes are treated as customer-defined planning metadata in FMC. They are useful for local review and change discussion, but they are not represented as Microsoft 365 Copilot admin controls unless a current Microsoft Learn source is added.

The metadata pattern documents:

- Categorization of domains or source sites for internal review
- Review cadence to help meet content accuracy and relevance expectations
- Approval workflow notes for customer-defined web grounding decisions

### Relationship to Feature Management Model

Web grounding governance extends the existing FMC baseline, drift detection, and change tracking model:

- Web-search policy state and scope are tracked as feature baseline settings alongside rollout ring assignments
- Customer-defined web grounding metadata is tracked separately from Microsoft admin control state
- Changes to documented policy state are subject to the same change approval and notification workflows as other feature policy updates
- Evidence export includes web-search policy state and local governance metadata for supervisory review
