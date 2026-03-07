# Evidence Export

Use `scripts\Export-Evidence.ps1` to generate audit-ready evidence artifacts for the FINRA Supervision Workflow for Copilot.

## Run the export

Documentation-first export:

```powershell
.\scripts\Export-Evidence.ps1 `
  -ConfigurationTier regulated `
  -OutputPath .\artifacts\evidence `
  -PeriodStart 2026-01-01 `
  -PeriodEnd 2026-01-31
```

Live Dataverse export:

```powershell
$env:DATAVERSE_ACCESS_TOKEN = '<access-token>'
.\scripts\Export-Evidence.ps1 `
  -ConfigurationTier regulated `
  -OutputPath .\artifacts\evidence `
  -PeriodStart 2026-01-01 `
  -PeriodEnd 2026-01-31 `
  -LiveExport
```

## Evidence package structure

```text
artifacts\evidence\
|-- 04-finra-supervision-workflow-evidence.json
|-- 04-finra-supervision-workflow-evidence.json.sha256
|-- supervision-queue-snapshot.json
|-- supervision-queue-snapshot.json.sha256
|-- review-disposition-log.json
|-- review-disposition-log.json.sha256
|-- sampling-summary.json
|-- sampling-summary.json.sha256
```

## Artifact descriptions

| Artifact | Purpose | Typical source |
| --- | --- | --- |
| supervision-queue-snapshot | Snapshot of queue state, assignments, SLA due times, and current disposition state. | Dataverse queue rows or configuration-based sample output. |
| review-disposition-log | Action log showing ingestion, assignment, review completion, and exception events. | Dataverse log rows or configuration-based sample output. |
| sampling-summary | Summary of zone and tier sampling rates and configured SLA targets. | Tier configuration and Dataverse config rows. |

## Control attestation mapping

| Control | Evidence statement | Primary artifacts |
| --- | --- | --- |
| 3.4 | Supports compliance with supervisory coverage by showing configured zones, sampling, and queue intake. | supervision-queue-snapshot, sampling-summary |
| 3.5 | Supports compliance with review accountability by showing dispositions, reviewers, and timestamps. | review-disposition-log |
| 3.6 | Supports compliance with exception tracking by showing breached items, escalation actions, and exception settings. | supervision-queue-snapshot, review-disposition-log, sampling-summary |

## SHA-256 integrity process

- Each JSON artifact is written with a matching `.sha256` file.
- The shared evidence package writer also generates a hash file for the top-level package.
- Reviewers should recalculate SHA-256 before uploading artifacts to the records repository.
- Hash verification should be documented in the deployment or audit workpaper.

## Retention schedule

| Tier | Suggested evidence retention |
| --- | --- |
| baseline | 365 days |
| recommended | 1095 days |
| regulated | 2555 days (7 years) |

## Notes

- Export output follows `data\evidence-schema.json` for package structure.
- Documentation-first mode is suitable for design reviews and dry runs.
- Live export mode should be used only in approved environments with authenticated Dataverse access.

