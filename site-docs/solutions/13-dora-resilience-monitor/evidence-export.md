# Evidence Export Guide

## Evidence Types

### service-health-log

The `service-health-log` artifact captures the operational state of Copilot-dependent Microsoft 365 workloads for the selected period.

**Schema fields**

- `service`: workload name
- `status`: current service-health state
- `collectedAt`: UTC (ISO 8601) time the monitoring run collected this record
- `checkedAt`: retained alias for `collectedAt` (collection time of the observation)
- `sourceLastModified`: UTC (ISO 8601) last-modified time reported by the source, or `null` when the source did not supply one
- `timestampProvenance`: `source-provided`, `detected-only`, `missing`, or `synthetic-stub`
- `freshness`: freshness evaluation object (see "Freshness and Timestamp Semantics")
- `pollingIntervalMinutes`: cadence defined by the selected tier
- `retentionDays`: retention requirement applied to the evidence set
- `sourceEndpoint`: monitoring source, such as `local-graph-stub`, `sample-json-env`, or the live Microsoft Graph service communications endpoint when implemented
- `runtimeMode`: `local-stub`, `sample-json`, or the live mode when implemented
- `incidentId`: related service-health incident identifier when present
- `impactDescription`: analyst-readable description of the workload condition

**Polling frequency**

- Baseline: 60 minutes
- Recommended: 15 minutes
- Regulated: 5 minutes

**Retention**

- Baseline: 90 days
- Recommended: 365 days
- Regulated: 1825 days

### incident-register

The `incident-register` artifact records DORA-oriented ICT incident details for Copilot-dependent services.

**Required DORA classification fields**

- `incidentId`
- `severity`
- `affectedService`
- `detectedAt`
- `reportedAt`
- `status`
- `rtoActual`
- `rpoActual`

**Additional operational fields**

- `affectedUserPct`
- `impactDescription`
- `rootCauseAnalysisStatus`
- `regulatoryNotificationRequired`
- `reportingTimelineGap`
- `notes`

**DORA reporting-timeline fields (indicative reference only)**

- `notificationWindowHours`, `initialNotificationDueAt`
- `initialNotificationLatestFromAwarenessHours`, `initialNotificationLatestFromAwarenessAt`
- `intermediateReportWindowHours`, `intermediateReportDueAt`
- `finalReportWindowDays`, `finalReportDueAt`
- `rcaWindowDays`, `rootCauseAnalysisDueAt`

The artifact's `reportingTimeline` block records the regulatory source and anchor semantics. Under Commission Delegated Regulation (EU) 2025/301, Article 5, the official clocks anchor the **initial notification** to classification as a major incident (no later than 24 hours from awareness), the **intermediate report** to submission of the initial notification, and the **final report** (one month) to submission of the intermediate report. This scaffold derives indicative due dates from the detection timestamp and chains each later stage from the prior stage's due date; when a source omits the detection time, the due dates are `null` and `reportingTimelineGap` is `true` rather than being fabricated. These values are indicative reference metadata only — not legal advice and not proof of DORA compliance.

**Retention**

Incident register retention follows the selected tier evidence-retention setting and should be aligned with local incident-management policy.

### resilience-test-results

The `resilience-test-results` artifact records operational-resilience exercises and recovery validation for Copilot dependencies.

**Core fields**

- `testType`
- `scheduledDate`
- `completedDate`
- `outcome`
- `rtoTargetHours`
- `rtoActual`
- `rpoTargetHours`
- `rpoActual`
- `notes`

**Expected use**

This artifact documents annual exercise scheduling, target recovery values, observed recovery results, and any exceptions that still require remediation or management approval.

## Package Contract

DRM exports evidence as JSON plus SHA-256 companion files. The three workload artifacts are created first, and then `scripts/Export-Evidence.ps1` calls the shared `Export-SolutionEvidencePackage` function to create the final package aligned to `data/evidence-schema.json`.

The package contract contains:

- `metadata`: solution, solution code, export version, exported timestamp, and governance tier
- `summary`: overall status, record count, finding count, and exception count
- `controls`: control-level status entries for 2.7, 4.9, 4.10, and 4.11
- `artifacts`: named references to the exported JSON files and hash values

Each artifact and the package `metadata` also carry `collectionTime` and a `freshness` object so downstream consumers (for example, 12-regulatory-compliance-dashboard) can distinguish collection time from source last-modified time.

## Freshness and Timestamp Semantics

Freshness is a first-class property of every evidence export. All timestamps are recorded in UTC using ISO 8601 (a trailing `Z`). Each service-health record and the overall export distinguish the following:

- **Collection time** (`collectedAt` / `collectionTime`): when the monitoring run gathered the record.
- **Source last-modified time** (`sourceLastModified`): the last-updated time reported by the source, or `null` when none was supplied.
- **Age and staleness evaluation** (`freshness.ageMinutes`, `freshness.status`, `freshness.isStale`): a record is `stale` when its age exceeds the staleness threshold (default: three polling cycles, minimum 60 minutes; override with `DRM_FRESHNESS_THRESHOLD_MINUTES`).
- **Source/runtime mode** (`runtimeMode`, `freshness.provenance`): `local-stub`, `sample-json`, or the live mode, plus provenance of the timestamps.
- **Reporting period** (`reportingPeriod.periodStart` / `reportingPeriod.periodEnd`): the evidence window.

Missing or invalid source timestamps are surfaced as an **explicit gap** (`freshness.status = unknown`, `freshness.hasTimestampGap = true`) and roll up to an overall `freshness.OverallStatus` of `gap`; they are never silently defaulted to the collection time. Synthetic local-stub records report `freshness.status = not-applicable` rather than appearing current. When freshness is `gap` or `stale`, the monitoring run emits a warning so operators do not treat the output as current.

## Control Mappings

| Control | Primary Evidence | How DRM Supports Compliance |
|---------|------------------|-----------------------------|
| 2.7 | `service-health-log` | Monitors service scope and tenant-region review points for cross-border data flow oversight; additional tenant geo data is still required |
| 4.9 | `incident-register` | Preserves DORA-style incident records, reporting timestamps, severity, and root-cause follow-up status |
| 4.10 | `resilience-test-results` | Documents annual resilience exercises, RTO and RPO targets, and evidence gaps that still require remediation |
| 4.11 | `service-health-log`, `incident-register` | Provides monitoring context that can be enriched by Microsoft Sentinel (managed in the Microsoft Defender portal) once a workspace, a customer-built ingestion path, and analytics rules are complete; no native Microsoft 365 service-health or Copilot connector exists |

## Examiner Notes for DORA Art. 19 Reporting Package

DRM packages the technical evidence needed to prepare a DORA Art. 19 reporting package, including incident chronology, affected services, selected DORA Art. 18 severity-assessment fields, and recovery metrics. The export keeps DORA Art. 17 incident-management chronology separate from Art. 19 reporting-package preparation, does not submit notices to regulators automatically, and does not replace jurisdiction-specific reporting templates. Operations and compliance teams should add narrative impact assessments, customer communications, root-cause analysis, and legal review before external submission.
