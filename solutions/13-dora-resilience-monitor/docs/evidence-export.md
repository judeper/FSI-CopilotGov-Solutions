# Evidence Export Guide

## Evidence Types

### service-health-log

The `service-health-log` artifact captures the operational state of Copilot-dependent Microsoft 365 workloads for the selected period.

**Schema fields**

- `service`: workload name
- `status`: current service-health state
- `checkedAt`: timestamp of the monitoring observation
- `pollingIntervalMinutes`: cadence defined by the selected tier
- `retentionDays`: retention requirement applied to the evidence set
- `sourceEndpoint`: monitoring source, such as `local-graph-stub`, `sample-json-env`, or the live Microsoft Graph service communications endpoint when implemented
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
- `notes`

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

## Control Mappings

| Control | Primary Evidence | How DRM Supports Compliance |
|---------|------------------|-----------------------------|
| 2.7 | `service-health-log` | Monitors service scope and tenant-region review points for cross-border data flow oversight; additional tenant geo data is still required |
| 4.9 | `incident-register` | Preserves DORA-style incident records, reporting timestamps, severity, and root-cause follow-up status |
| 4.10 | `resilience-test-results` | Documents annual resilience exercises, RTO and RPO targets, and evidence gaps that still require remediation |
| 4.11 | `service-health-log`, `incident-register` | Provides monitoring context that can be enriched by Microsoft Sentinel once workspace provisioning and alert rules are complete |

## Examiner Notes for DORA Art. 19 Reporting Package

DRM packages the technical evidence needed to prepare a DORA Art. 19 reporting package, including incident chronology, affected services, severity assessment, and recovery metrics. The export does not submit notices to regulators automatically and does not replace jurisdiction-specific reporting templates. Operations and compliance teams should add narrative impact assessments, customer communications, root-cause analysis, and legal review before external submission.
