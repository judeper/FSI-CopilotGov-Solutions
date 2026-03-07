# Evidence Export

## Overview

The Regulatory Compliance Dashboard publishes evidence that summarizes control posture, coverage mapping, and export status across all connected solutions. These packages support compliance with supervisory reporting and examination readiness obligations by referencing upstream evidence rather than replacing it.

All exported files must align to `../../data/evidence-schema.json` and include a companion `.sha256` file. In the repository state, these exports are documentation-first seeded artifacts until live Dataverse ingestion and Power BI bindings are implemented.

## Evidence Outputs

| Evidence output | Purpose | Typical trigger | Primary consumer |
|-----------------|---------|-----------------|------------------|
| `control-status-snapshot` | Current control status, score, evidence freshness, and source solution mapping. | After deployment or scheduled aggregation | Compliance operations, control owners |
| `framework-coverage-matrix` | Control-to-regulation coverage map for FINRA, SEC, OCC, DORA, GLBA, and optional SOX 404 reporting. | After a metadata refresh or framework mapping update | Audit, regulatory readiness, PMO |
| `dashboard-export` | Power BI report export metadata, filter context, and package references for stakeholder review. | On-demand before committee or examination review | Executives, internal audit, regulators |

## Control Status Snapshot Schema

Each control-status-snapshot record should include the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `controlId` | string | Control identifier such as `3.7` or `4.7`. |
| `status` | string | One of `implemented`, `partial`, `monitor-only`, `playbook-only`, or `not-applicable`. |
| `score` | integer | Contract score mapped from the status: 100, 50, 25, 10, or 0. |
| `lastEvidenceDate` | string | ISO 8601 timestamp of the most recent upstream evidence export used by the dashboard. |
| `solutionSlug` | string | Solution code or slug associated with the dashboard record, such as `RCD`. |

Recommended optional fields:

- `controlTitle`
- `tier`
- `sourceSolutions`
- `notes`

## Example control-status-snapshot Payload

```json
{
  "controlId": "3.7",
  "status": "partial",
  "score": 50,
  "lastEvidenceDate": "2024-01-15T08:30:00Z",
  "solutionSlug": "RCD",
  "controlTitle": "Compliance Posture Reporting and Executive Dashboards",
  "sourceSolutions": [
    "06-audit-trail-manager",
    "11-risk-tiered-rollout"
  ],
  "notes": "Documentation-first seed record showing the expected dashboard posture contract before a live aggregation environment is connected."
}
```

## Framework Coverage Matrix Content

Each matrix row should identify:

- `framework_id`, such as `finra-3110` or `dora`
- `framework_display_name`, such as `FINRA 3110` or `DORA`
- Control identifier
- Coverage state
- Source solution references
- Evidence freshness state

Use this matrix to drive the regulatory heatmap in Power BI and to filter examination packages by framework. `framework_id` is the stable machine-readable join key back to `data/frameworks-master.json`; keep the display name separately for reviewer-facing exports.

## Dashboard Export Content

Dashboard export packages should capture:

- Report name and workspace
- Export timestamp
- Filters applied at export time
- Referenced evidence package paths and hashes
- Selected regulatory framework
- Package owner and reviewer metadata

## Packaging Requirements

- Evidence packages must be written as UTF-8 JSON.
- Every JSON package must have a matching `.sha256` file.
- Export notes should use precise language such as "supports compliance with" and avoid absolute claims.
- Evidence freshness should be calculated from upstream export timestamps, not from the time the dashboard was opened.
