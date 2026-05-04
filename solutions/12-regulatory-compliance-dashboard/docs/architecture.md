# Architecture

## Overview

The Regulatory Compliance Dashboard documents how to aggregate control evidence from upstream solutions and present it as a control-centric operating view for executives, audit teams, and program managers. In the repository state it emits seeded artifacts and fallback monitoring output while Dataverse, Power Automate, and Power BI remain implementation targets for the customer environment.

The design goal is to support compliance with supervisory and records-retention obligations by consolidating evidence status, not by replacing the underlying control systems. Source solutions remain the systems of record for remediation, books and records retention, and detailed audit artifacts.

## Component Diagram

```text
+--------------------------------------------------------------+
| Upstream solutions 01-15                                    |
| Evidence packages, hashes, and control exports              |
+--------------------------------------------------------------+
                               |
                               v
+--------------------------------------------------------------+
| Power Automate                                               |
| - RCD-EvidenceAggregator (daily)                             |
| - RCD-FreshnessMonitor (hourly)                              |
| - RCD-ExaminationPackager (on-demand)                        |
+--------------------------------------------------------------+
        |                               |                               |
        v                               v                               v
+----------------------+     +----------------------+     +----------------------+
| fsi_cg_rcd_baseline  |     | fsi_cg_rcd_finding   |     | fsi_cg_rcd_evidence  |
| control status store |     | coverage gaps        |     | dashboard snapshots  |
+----------------------+     +----------------------+     +----------------------+
               \                      |                      /
                \                     |                     /
                 v                    v                    v
                  +--------------------------------------+
                  | Power BI semantic model and report layer    |
                  | Control Master, Implementation       |
                  | Status, Evidence Log, Regulatory Map |
                  +--------------------------------------+
                                      |
                                      v
                  +--------------------------------------+
                  | Executive dashboards and examination |
                  | readiness packages                   |
                  +--------------------------------------+
```

## Dataverse Tables

The dashboard normalizes source evidence into three Dataverse tables named with the `fsi_cg_rcd_*` prefix.

| Table | Purpose | Example columns |
|-------|---------|-----------------|
| `fsi_cg_rcd_baseline` | Current control status store used by Power BI visuals and monitoring scripts. | `controlId`, `controlTitle`, `status`, `score`, `lastEvidenceDate`, `solutionSlug`, `tier`, `notes` |
| `fsi_cg_rcd_finding` | Coverage gaps, stale evidence observations, and framework-specific reporting gaps. | `findingId`, `frameworkId`, `controlId`, `severity`, `gapDescription`, `ownerSolution`, `targetDate` |
| `fsi_cg_rcd_evidence` | Dashboard snapshots and evidence package metadata. | `evidenceId`, `solutionSlug`, `evidenceType`, `exportedAt`, `hash`, `storagePath`, `isFresh`, `frameworkList` |

The deployment script documents these tables as Dataverse contracts and creates seed JSON artifacts that can be used during implementation. In a customer-implemented environment Dataverse becomes the authoritative aggregation store for the Power BI semantic model.

## Documented Power Automate Flows

The following flows are documented as implementation specifications only. No flow definitions or binaries are deployed by the repository scripts; customers must build and configure these flows manually in their Power Automate environment.

### RCD-EvidenceAggregator

- Schedule: Daily
- Purpose: Describes how an implementation should enumerate solution evidence packages, validate package presence, normalize control statuses, and write the latest rows into `fsi_cg_rcd_baseline` and `fsi_cg_rcd_evidence`.
- Key inputs: Evidence package metadata from solutions 01-15, tier configuration, framework mappings, and dependency status from solutions 06 and 11.

### RCD-FreshnessMonitor

- Schedule: Hourly
- Purpose: Describes how an implementation should calculate freshness age for each evidence export, flag stale controls, and record gap entries in `fsi_cg_rcd_finding`.
- Key inputs: `fsi_cg_rcd_evidence`, freshness thresholds from the selected configuration tier, and notification settings.

### RCD-ExaminationPackager

- Trigger: On-demand
- Purpose: Describes how an implementation should bundle evidence references, coverage matrices, and dashboard exports by framework or examination request.
- Key inputs: Dataverse evidence metadata, selected regulation, date range, and source solution package references.

> **Note:** The Power Automate flows described in this section are documented designs. They are not deployed or exported by repository scripts. Customer must create these flows in their tenant using the specifications provided.

## Power BI Semantic Model Structure

The report layer is documentation-led and no binary `.pbix` or `.pbit` files are included in this repository. Instead of storing a binary report file, this solution documents the expected semantic model tables, relationships, pages, and measures that customers should implement in their Power BI workspace.

| Semantic model table | Grain | Source |
|----------------------|-------|--------|
| `ControlMaster` | One row per control | Solution metadata, control mappings, and weights from configuration |
| `ImplementationStatus` | One row per control per snapshot date | `fsi_cg_rcd_baseline` |
| `EvidenceLog` | One row per evidence export | `fsi_cg_rcd_evidence` |
| `RegulatoryMapping` | One row per control-to-framework relationship | Configuration and coverage matrix mappings |

Recommended report pages:

- Executive summary
- Control RAG and maturity trend
- Evidence freshness and stale export drillthrough
- Regulatory coverage matrix
- Examination readiness package status

## DAX Measures

The following DAX measures should be implemented in the Power BI template:

```text
GovernanceMaturityScore :=
VAR _LatestDate = MAX(ImplementationStatus[SnapshotDate])
RETURN
DIVIDE(
    SUMX(
        FILTER(ImplementationStatus, ImplementationStatus[SnapshotDate] = _LatestDate),
        ImplementationStatus[Score] * RELATED(ControlMaster[Weight])
    ),
    SUMX(
        FILTER(ImplementationStatus, ImplementationStatus[SnapshotDate] = _LatestDate),
        RELATED(ControlMaster[Weight])
    )
)

ControlsImplementedPct :=
VAR _LatestDate = MAX(ImplementationStatus[SnapshotDate])
RETURN
DIVIDE(
    CALCULATE(
        COUNTROWS(ImplementationStatus),
        ImplementationStatus[Status] = "implemented",
        ImplementationStatus[SnapshotDate] = _LatestDate
    ),
    DISTINCTCOUNT(ControlMaster[ControlId])
)

EvidenceFreshnessPct :=
VAR _LatestDate = MAX(EvidenceLog[ExportedAt])
RETURN
DIVIDE(
    CALCULATE(
        COUNTROWS(EvidenceLog),
        EvidenceLog[IsFresh] = TRUE(),
        EvidenceLog[ExportedAt] = _LatestDate
    ),
    CALCULATE(
        COUNTROWS(EvidenceLog),
        EvidenceLog[ExportedAt] = _LatestDate
    )
)
```

Suggested dashboard thresholds:

- Green: maturity score greater than or equal to 80
- Amber: maturity score from 50 through 79.99
- Red: maturity score below 50

## Integration with Dependency Solutions

### 06-audit-trail-manager

- Supplies evidence lineage, attestation metadata, and export hash references.
- Strengthens controls 3.8, 3.12, and 3.13 by improving examination package traceability.
- Provides the audit evidence timestamps used by freshness monitoring.

### 11-risk-tiered-rollout

- Supplies cohort, rollout, and adoption context used for maturity scoring and benchmarking.
- Strengthens controls 4.5 and 4.7 by segmenting posture by business unit, cohort, or governance tier.
- Provides risk tier context so reporting can distinguish implemented controls from monitor-only rollups.

## Power BI Template Specification

Because Power BI assets are documentation-led in this repository, the template should be implemented with these elements:

- Report name: `RCD-GovernanceDashboard`
- Semantic model tables: `ControlMaster`, `ImplementationStatus`, `EvidenceLog`, `RegulatoryMapping`
- Default filters: `Tier`, `Framework`, `Evidence freshness state`, `Business unit`
- Security model: row-level security by business unit, legal entity, or operating segment
- Export modes: Power BI service export to PDF for executive review and JSON metadata export for audit packaging
