# FINRA Supervision Workflow for Copilot

> **Status:** Documentation-first scaffold | **Version:** v0.2.0 | **Priority:** P0 | **Track:** B

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](../../docs/documentation-vs-runnable-assets-guide.md).

## Overview

FINRA Supervision Workflow for Copilot routes flagged Copilot-assisted communications into a documented supervisory queue, applies zone and governance-tier sampling, enforces review SLAs, and produces examiner-ready evidence exports. It is documentation-first for Dataverse and Power Automate assets so regulated teams can build the flows and tables manually inside a controlled environment.

| Field | Value |
| --- | --- |
| Solution code | FSW |
| Track | B |
| Priority | P0 |
| Solution type | Power Automate, Dataverse |
| Primary controls | 3.4, 3.5, 3.6 |
| Regulations | FINRA 3110, FINRA 2210, SEC Reg BI |
| Evidence outputs | supervision-queue-snapshot, review-disposition-log, sampling-summary |

## What this solution does

This solution routes Copilot-assisted communications that were flagged by Microsoft Purview Communication Compliance into a supervisory review queue. It supports compliance with FINRA supervision obligations by assigning reviewers based on zone and governance tier, applying configurable sampling rates, enforcing review SLAs, and recording review actions in an append-only log.

The solution is documentation-first. Dataverse tables, Power Automate flows, connection references, and environment variables are described here and in the docs folder so that regulated teams can deploy them manually in a controlled Power Platform environment.

By default, repository evidence exports remain configuration-driven sample data until `scripts\Export-Evidence.ps1 -LiveExport` is pointed at a customer-managed Dataverse environment with live queue records.

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not connect to Microsoft Purview Communication Compliance APIs
- ❌ Does not route flagged communications automatically (workflow is documented, not deployed)
- ❌ Does not deploy Power Automate flows (supervision flows are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)

## Regulatory context

- FINRA 3110: supports supervisory review, escalation, and evidence retention for sampled and mandatory communications review.
- FINRA 2210: supports review of communications before or after use based on risk classification and supervisory workflow.
- SEC Reg BI: supports documentation of review outcomes, exception handling, and supervisory accountability.

Use this solution as a control implementation pattern that supports compliance with firm policy and regulatory obligations. It does not replace legal review, records management, or principal sign-off requirements.

## Prerequisites

See [docs\prerequisites.md](docs/prerequisites.md) for the full list. Minimum prerequisites are:

- Power Apps Premium and Power Automate Premium for Dataverse tables and cloud flows.
- Microsoft 365 E5 Compliance for Purview Communication Compliance signals.
- Power Platform Admin, Purview Compliance Admin, and Global Reader access for deployment validation.
- Azure AD groups for supervisory principals, escalation recipients, and service identities.
- PowerShell 7 or later for deployment, monitoring, and evidence export scripts.

## Data model

The solution uses three Dataverse tables following the shared contract `fsi_cg_{solution}_{purpose}`.

| Display name | Logical name | Purpose | Key columns |
| --- | --- | --- | --- |
| SupervisionQueue | fsi_cg_fsw_queue | Stores flagged communications awaiting or completing review. | fsi_queuenumber, fsi_sourcetype, fsi_sourceid, fsi_agentid, fsi_zone, fsi_tier, fsi_state, fsi_assignedprincipal, fsi_sladue, fsi_reviewoutcome, fsi_reviewnotes |
| SupervisionLog | fsi_cg_fsw_log | Maintains append-only review actions for queue items. | fsi_lognumber, fsi_queueitem, fsi_action, fsi_actor, fsi_timestamp |
| SupervisionConfig | fsi_cg_fsw_config | Stores zone and tier sampling and SLA settings. | fsi_zone, fsi_tier, fsi_slahours, fsi_reviewpercent |

Recommended Dataverse ownership model:

- Queue items: organization-owned so supervisory teams can reassign work during outages or staff changes.
- Log items: create-only for service accounts and reviewer flows to support an immutable log pattern.
- Config items: restricted write access to governance administrators.

## Power Automate flows

The implementation uses four manual Power Automate cloud flows:

1. Ingest Flagged Items
   - Trigger: scheduled poll or event-driven connector action that reads flagged Copilot prompt and response items from Purview Communication Compliance.
   - Actions: normalize source metadata, classify zone and tier, create a SupervisionQueue row, and append a SupervisionLog action of `ingested`.

2. Assignment Flow
   - Trigger: when a new SupervisionQueue row is created.
   - Actions: look up the supervisory principal for the item's zone and tier, set `fsi_assignedprincipal`, calculate `fsi_sladue`, and append an `assigned` log entry.

3. Escalation Flow
   - Trigger: scheduled flow that scans open queue items nearing or breaching SLA.
   - Actions: notify escalation recipients, update exception tracking fields, and append `sla-warning` or `sla-breached` log entries.

4. Review Complete Flow
   - Trigger: when a reviewer updates review outcome fields or completes a review form.
   - Actions: validate disposition, mark queue state, append a `review-complete` or `exception-granted` log entry, and preserve reviewer notes.

See [docs\architecture.md](docs/architecture.md) and [docs\deployment-guide.md](docs/deployment-guide.md) for manual build steps.

## Deployment steps

1. Review [docs\prerequisites.md](docs/prerequisites.md) and confirm licensing, roles, network access, and Azure AD group membership.
2. Create Dataverse tables and columns in the target environment as described in [docs\deployment-guide.md](docs/deployment-guide.md).
3. Create connection references named `fsi_cr_fsw_purview` and `fsi_cr_fsw_dataverse`.
4. Set environment variables such as `fsi_ev_fsw_purviewpolicyid` and `fsi_ev_fsw_environmenturl`.
5. Run `scripts\Deploy-Solution.ps1` to generate the deployment manifest and configuration stubs for the chosen tier.
6. Build the four Power Automate flows manually and test queue routing, review completion, and escalation behavior.
7. Run `scripts\Monitor-Compliance.ps1` and `scripts\Export-Evidence.ps1` to validate readiness and produce evidence artifacts.

## Evidence Export

Run the export script after configuration changes and at the end of each review period.

```powershell
.\scripts\Export-Evidence.ps1 `
  -ConfigurationTier regulated `
  -OutputPath .\artifacts\evidence `
  -PeriodStart 2026-01-01 `
  -PeriodEnd 2026-01-31
```

Evidence artifacts follow `data\evidence-schema.json` and include:

- `supervision-queue-snapshot`
- `review-disposition-log`
- `sampling-summary`

Each export writes a `.sha256` companion file so reviewers can verify package integrity before filing evidence in the firm's records repository.

## Related Controls

| Control | Supervisory objective | Solution capability | Evidence output |
| --- | --- | --- | --- |
| 3.4 | Coverage of flagged Copilot-assisted communications | Zone and tier sampling, mandatory review routing, and SLA assignment | supervision-queue-snapshot, sampling-summary |
| 3.5 | Review disposition accountability | Reviewer outcome capture, principal assignment, and append-only action log | review-disposition-log |
| 3.6 | Exception and escalation tracking | SLA breach detection, escalation recipients, and exception reason capture | supervision-queue-snapshot, review-disposition-log, sampling-summary |

## Regulatory Alignment

This solution supports compliance with FINRA 3110, FINRA 2210, and SEC Reg BI by documenting supervisory intake, reviewer assignment, escalation handling, and retained evidence for Copilot-assisted communications. It provides an implementation pattern for supervisory workflow evidence and does not replace legal review, principal sign-off, or firm-specific written supervisory procedures.

## Known limitations

- Power Automate flows and Dataverse tables are documented, not deployed as code, because this solution avoids a hard dependency on Power Platform CLI.
- Purview Communication Compliance signal availability depends on upstream policy configuration and service latency.
- Live evidence export requires Dataverse API connectivity and an access token supplied through the deployment environment.
- Sampling configuration supports compliance with supervisory review design, but firms still need written supervisory procedures that define exception handling and sign-off authority.

