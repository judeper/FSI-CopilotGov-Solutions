# Architecture

Copilot Connector and Plugin Governance uses a documentation-first architecture built around discovery, approval, monitoring, and evidence generation for Copilot extensibility scenarios. The design assumes that Power Automate flows and Dataverse tables are documented and approved before workflow automation is enabled in production.

## End-to-End Flow

```text
+--------------------+    +--------------------+    +--------------------+    +--------------------+
| Connector Discovery| -> | Risk Classifier    | -> | Approval Router    | -> | Dataverse Registry |
| Admin API + Graph  |    | low/med/high/block |    | security/CISO/DLP  |    | baseline/finding   |
+--------------------+    +--------------------+    +--------------------+    +--------------------+
                                                                                         |
                                                                                         v
                                                                               +--------------------+
                                                                               | Monitoring         |
                                                                               | daily/weekly check |
                                                                               +--------------------+
                                                                                         |
                                                                                         v
                                                                               +--------------------+
                                                                               | Evidence Export    |
                                                                               | JSON + SHA-256     |
                                                                               +--------------------+
```

## Core Components

| Component | Technology | Responsibility |
|-----------|------------|----------------|
| Connector Discovery | Power Platform Admin API | Enumerates environment connectors, connector metadata, and policy-relevant identifiers used by Copilot or agent workflows. |
| Plugin and app inventory | Microsoft Graph | Captures app registration and plugin context for Graph Connectors, AppSource plugins, and custom deployment references. |
| Risk Classifier | `Deploy-Solution.ps1` and config JSON | Applies low, medium, high, or blocked treatment based on publisher trust, certification, data-flow boundaries, and access to financial systems. |
| Approval Router | Power Automate flow `CPG-ApprovalRouter` | Routes requests through security review, then CISO or DLP review, before recording approval or denial. |
| Dataverse Registry | Dataverse tables | Stores approved baseline records, findings for unapproved or risky integrations, and evidence-ready data-flow attestations. |
| Monitoring | `Monitor-Compliance.ps1` and `CPG-DataFlowAudit` | Detects new connectors, pending approval SLA breaches, and attestation drift. |
| Evidence Export | `Export-Evidence.ps1` | Packages evidence outputs for audit, supervisory review, and DORA third-party documentation support. |

## Power Automate Flow Design

The solution documents three primary flows:

| Flow | Trigger | Purpose |
|------|---------|---------|
| `CPG-ConnectorInventory` | Daily recurrence | Calls the Power Platform Admin API, inventories connectors in scope, and refreshes Dataverse baseline or finding records. |
| `CPG-ApprovalRouter` | Triggered by new request or new connector finding | Assigns approval tasks, captures security review outcomes, and records CISO or DLP sign-off for sensitive use cases. |
| `CPG-DataFlowAudit` | Weekly recurrence | Revalidates cross-boundary attestations, identifies overdue approvals, and prepares monitoring summaries. |

These flows should remain documentation-first until connection references, reviewer mailboxes, and environment IDs are approved for the target tenant.

## Dataverse Design

The solution uses the required naming convention `fsi_cg_{solution}_{purpose}` and defines the following tables:

| Table | Purpose | Example columns |
|-------|---------|-----------------|
| `fsi_cg_cpg_baseline` | Approved connector and plugin baseline for the environment. | `connectorId`, `displayName`, `publisher`, `riskLevel`, `approvalStatus`, `dataFlowBoundaries`, `lastReviewedOn` |
| `fsi_cg_cpg_finding` | Unapproved, risky, or blocked connectors requiring operational follow-up. | `connectorId`, `findingType`, `riskLevel`, `owner`, `openedOn`, `dueOn`, `remediationStatus` |
| `fsi_cg_cpg_evidence` | Data-flow attestations, approval checkpoints, and export metadata. | `artifactType`, `connectorId`, `attestedBy`, `attestedOn`, `retentionDays`, `exportPath` |

## Discovery and Classification Logic

1. `CPG-ConnectorInventory` or `Deploy-Solution.ps1` models the Power Platform Admin API inventory path for connector enumeration.
2. Microsoft Graph inventory supplements discovery for app registrations and plugin dependencies that are not obvious from connector metadata alone.
3. The risk classifier uses the configured risk categories:
   - `low` for Microsoft-built connectors with no external data egress
   - `medium` for certified third-party connectors with limited external reach
   - `high` for custom or uncertified connectors and cross-boundary data flows
   - `blocked` for prohibited connectors such as personal storage or public social services in regulated scenarios
4. Approval requirements are derived from the selected governance tier and written into the approval register.

## Integration with Solution 09

Solution `09-feature-management-controller` is a dependency because approval alone is not sufficient for production enablement. After CPG records an approval decision, feature management should determine whether the connector or plugin is enabled in pilot, business, or regulated rollout rings. This dependency provides a controlled handoff from approval into production release governance.

Recommended integration points:

- Use solution 09 rollout flags to prevent newly approved connectors from appearing outside approved user cohorts.
- Feed CPG findings into the feature controller so high-risk or blocked connectors remain disabled even if manually added elsewhere.
- Align exception handling so rollback decisions in solution 09 can reference CPG approval records and data-flow attestations.

## Monitoring and Evidence

`Monitor-Compliance.ps1` compares current inventory to the approved baseline and flags:

- new connectors that are not in the approved baseline
- unapproved or blocked connectors still visible in the environment
- overdue approvals that exceeded the configured SLA
- stale or missing data-flow attestations for external boundary use cases

`Export-Evidence.ps1` packages the resulting `connector-inventory`, `approval-register`, and `data-flow-attestations` records for audit support, supervisory review, and DORA third-party risk documentation.
