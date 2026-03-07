# Architecture

## Overview

The FINRA Supervision Workflow for Copilot uses three layers:

1. Dataverse layer for queue, log, and configuration data.
2. Power Automate layer for ingestion, assignment, escalation, and review completion.
3. Evidence export layer for packaging evidence artifacts and integrity hashes.

This architecture supports compliance with supervisory review requirements by separating operational workflow data from exported evidence artifacts.

## Layer 1: Dataverse

### Tables

| Display name | Logical name | Purpose |
| --- | --- | --- |
| SupervisionQueue | fsi_cg_fsw_queue | Review queue for flagged Copilot-assisted communications. |
| SupervisionLog | fsi_cg_fsw_log | Append-only reviewer and system action log. |
| SupervisionConfig | fsi_cg_fsw_config | Tier and zone configuration for SLA and sampling. |

### Core fields

- SupervisionQueue
  - fsi_queuenumber
  - fsi_sourcetype
  - fsi_sourceid
  - fsi_agentid
  - fsi_zone
  - fsi_tier
  - fsi_state
  - fsi_assignedprincipal
  - fsi_sladue
  - fsi_reviewoutcome
  - fsi_reviewnotes
- SupervisionLog
  - fsi_lognumber
  - fsi_queueitem
  - fsi_action
  - fsi_actor
  - fsi_timestamp
- SupervisionConfig
  - fsi_zone
  - fsi_tier
  - fsi_slahours
  - fsi_reviewpercent

## Layer 2: Power Automate

### Flows

- Ingest Flagged Items
  - Reads flagged Purview Communication Compliance items for Copilot prompts and responses.
  - Normalizes metadata and creates queue and log entries.
- Assignment Flow
  - Routes queue items to supervisory principals by zone and tier.
  - Calculates SLA due dates using configuration rows.
- Escalation Flow
  - Scans open queue items for warning and breach thresholds.
  - Records exception and escalation events in the log.
- Review Complete Flow
  - Validates reviewer dispositions and final notes.
  - Closes or escalates queue items and appends immutable log rows.

## Layer 3: Evidence export

### PowerShell components

- `scripts\Export-Evidence.ps1`
  - Builds evidence artifacts.
  - Generates SHA-256 integrity files.
  - Calls the shared `Export-SolutionEvidencePackage` function.
- `scripts\Monitor-Compliance.ps1`
  - Validates the configuration posture before export.
- `scripts\Deploy-Solution.ps1`
  - Produces deployment manifests and stub configuration files for manual implementation.

## ASCII component diagram

```text
+---------------------------------------------------------------+
| Microsoft Purview Communication Compliance                    |
| Flagged Copilot prompts and responses                         |
+------------------------------+--------------------------------+
                               |
                               v
+---------------------------------------------------------------+
| Power Automate layer                                            |
| 1. Ingest Flagged Items                                         |
| 2. Assignment Flow                                              |
| 3. Escalation Flow                                              |
| 4. Review Complete Flow                                         |
+------------------------------+--------------------------------+
                               |
                               v
+------------------------------+--------------------------------+
| Dataverse layer                                                 |
| fsi_cg_fsw_queue   fsi_cg_fsw_log   fsi_cg_fsw_config          |
+------------------------------+--------------------------------+
                               |
                               v
+---------------------------------------------------------------+
| Evidence export layer                                           |
| Export-Evidence.ps1                                             |
| - supervision-queue-snapshot                                   |
| - review-disposition-log                                        |
| - sampling-summary                                              |
| - package hash files                                            |
+---------------------------------------------------------------+
```

## Data flows

1. Purview flags a Copilot-assisted communication.
2. Ingest Flagged Items creates a queue item and initial log entry.
3. Assignment Flow applies zone and tier routing using SupervisionConfig.
4. Supervisory principals review items from SupervisionQueue.
5. Review Complete Flow writes outcomes and notes, then appends final actions to SupervisionLog.
6. Escalation Flow monitors open items and records warning or breach actions.
7. Export-Evidence.ps1 reads configuration or Dataverse data and writes evidence artifacts.
8. Evidence files and `.sha256` companions are archived in the firm's records repository.

## Design considerations

- Queue rows are the operational system of record for review status.
- Log rows should be append-only to preserve reviewer accountability.
- Configuration changes should be tightly controlled because they change supervisory coverage.
- Evidence packaging is separate from workflow execution so firms can export evidence on demand for audits and exams.

