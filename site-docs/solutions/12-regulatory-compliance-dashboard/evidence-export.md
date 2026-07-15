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
- `collectedAt` — when the monitoring or seed run collected the record (distinct from `lastEvidenceDate`).
- `sourceLastModified` — last-modified time reported by the source evidence package, or `null` when none is available.
- `timestampProvenance` — one of `source-provided`, `detected-only`, `synthetic-seed`, or `missing`.
- `freshnessState` — one of `current`, `stale`, `unknown`, or `not-applicable`.
- `hashState` — hash and validation state of the referenced upstream evidence (for example `unresolved`, `not-collected`, or `seed`).

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

> **Seed-mode note:** In the repository state, seed rows emitted by `Export-Evidence.ps1` set `lastEvidenceDate` to `null`, record only `collectedAt` (the seed generation time), set `sourceLastModified` to `null`, and mark `timestampProvenance` as `synthetic-seed` with `freshnessState` of `not-applicable`. They do not appear current, because no upstream evidence timestamp has been resolved. The populated example above illustrates a resolved record produced only after a runtime aggregation environment supplies real upstream export timestamps.

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

## Freshness and Provenance Semantics

Freshness and provenance are tracked as first-class properties so consumers can tell resolved evidence from seeded placeholders and never treat unresolved data as current.

- **Collection time versus source time.** `collectedAt` records when a monitoring or seed run gathered a record; `sourceLastModified` records the last-modified time reported by the upstream evidence package. Freshness is evaluated from the source time, not from when the dashboard or seed run executed.
- **Timestamp provenance.** Each record carries `timestampProvenance`: `source-provided` (from a resolved upstream package), `detected-only` (inferred from an evidence file's last-write time during deployment inventory), `synthetic-seed` (documentation-first seed output), or `missing`.
- **Explicit gaps, never silent currency.** When a source timestamp or package hash is missing or unresolved, the record reports `freshnessState` / `evidenceFreshnessState` of `unknown` with `hasTimestampGap = true` rather than defaulting to `current`. The `dashboard-export` package rolls these up into a `dataQuality` object (`overall = gap`) whenever referenced upstream packages are unresolved.
- **Monitoring warnings.** `Monitor-Compliance.ps1` returns `DataQualityGap` and `TimestampGapControlCount`, and emits a warning when any control lacks a source evidence timestamp, so operators do not treat the output as current.
- **Hash and validation state.** Referenced upstream packages record `hashState` (for example `unresolved` at seed time, `not-collected` during deployment inventory). SHA-256 hashes and source timestamps are resolved by the runtime aggregation flow before freshness can be evaluated.

## Packaging Requirements

- Evidence packages must be written as UTF-8 JSON.
- Every JSON package must have a matching `.sha256` file.
- Export notes should use precise language such as "supports compliance with" and avoid absolute claims.
- Evidence freshness should be calculated from upstream export timestamps, not from the time the dashboard was opened.
