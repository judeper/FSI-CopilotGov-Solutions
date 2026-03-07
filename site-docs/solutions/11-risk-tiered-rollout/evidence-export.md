# Evidence Export

## Purpose

Risk-Tiered Rollout Automation exports evidence so rollout operations, compliance, and audit teams can review the state of wave readiness, approvals, and rollout health. The packaged evidence file is produced by `scripts\Export-Evidence.ps1` and includes control statuses plus references to the detailed artifacts listed below.

## Evidence Package Contract

- Packaged evidence file aligned to `..\..\data\evidence-schema.json`
- Companion `.sha256` file for the packaged evidence payload
- Control entries for `1.9`, `1.11`, `1.12`, and `4.12`
- Artifact references for `wave-readiness-log`, `approval-history`, and `rollout-health-dashboard`

## Artifact: wave-readiness-log

The wave readiness log records per-wave readiness outcomes that were used to prepare or block expansion.

| Field | Description |
|-------|-------------|
| `waveNumber` | Wave being evaluated |
| `waveName` | Friendly wave name from configuration |
| `includedRiskTiers` | Risk tiers allowed in the wave |
| `targetUsers` | Configured maximum users for the wave |
| `readinessPercent` | Percentage of eligible users meeting the prerequisite checks |
| `blockedUsers` | Count of users blocked from rollout |
| `dependencyArtifact` | Path to the readiness evidence file from solution 01 |
| `gateReady` | Indicates whether the wave is ready to proceed to approval |

Primary evidence use:

- Demonstrates that rollout sequencing was based on documented readiness evidence
- Supports phased rollout review for OCC 2011-12 and FINRA 3110 supervision oversight

## Artifact: approval-history

The approval history captures the approver chain for each wave and records who allowed or denied expansion.

| Field | Description |
|-------|-------------|
| `waveNumber` | Wave submitted for review |
| `approvalStage` | Business owner, control owner, or CAB review stage |
| `approverRole` | Role expected to approve the wave |
| `decision` | Approved, rejected, or needs-review |
| `decisionTimestamp` | Date and time of the decision |
| `ticketId` | Change ticket, CAB ticket, or workflow identifier |
| `notes` | Comments explaining conditional approvals or blockers |

Primary evidence use:

- Demonstrates that no higher-risk expansion occurred without review
- Supports change-management traceability and retained decision history

## Artifact: rollout-health-dashboard

The rollout health dashboard artifact captures the current operational view exposed to Power BI.

| Field | Description |
|-------|-------------|
| `overallHealthScore` | Aggregate score derived from gate completion, assignment progress, and blockers |
| `status` | Summary status used for reporting |
| `pendingAssignments` | Users waiting for assignment execution |
| `blockedUsers` | Users blocked by missing prerequisites |
| `openFindings` | Active rollout findings requiring action |
| `waves` | Per-wave health summary shown in the dashboard |
| `refreshedAt` | Timestamp of the dashboard snapshot |

Primary evidence use:

- Supports ongoing rollout-risk tracking
- Provides a retained view of rollout health at the time evidence was exported

## Export Process

1. Generate or refresh rollout manifests and monitoring outputs.
2. Run `scripts\Export-Evidence.ps1` for the selected governance tier.
3. Review the packaged evidence JSON and the `.sha256` file.
4. Store the package according to the evidence-retention policy for the selected tier.

## Review Considerations

- Verify the readiness log references the current scanner artifact, not stale data.
- Confirm approval history includes every expanded wave, including rejected or paused requests.
- Confirm dashboard metrics align with the latest `Monitor-Compliance.ps1` output.
- Use solution status values only: `implemented`, `partial`, `monitor-only`, `playbook-only`, `not-applicable`.
