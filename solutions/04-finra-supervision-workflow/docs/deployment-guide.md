# Deployment Guide

This guide describes how to deploy the FINRA Supervision Workflow for Copilot in a documentation-first model. Dataverse tables and Power Automate flows are created manually in the target Power Platform environment.

## 1. Prepare the environment

1. Confirm prerequisites in `docs\prerequisites.md`.
2. Identify the Power Platform environment URL, for example `https://contoso.crm.dynamics.com`.
3. Confirm the environment has Dataverse enabled and that makers are allowed to create cloud flows.
4. Create Microsoft Entra ID groups for:
   - Supervisory principals by zone
   - Escalation recipients
   - Governance administrators
5. Record the Microsoft Purview Communication Compliance policy ID, supported Copilot surfaces/item classes, selected AI-app locations, and any applicable pay-as-you-go billing prerequisite. See [Configure generative AI detection](https://learn.microsoft.com/purview/communication-compliance-copilot).
6. Verify table-creation privileges separately from licensing, and verify investigation-role membership plus policy-specific reviewer assignment for anyone validating individual Copilot matches. See [Prerequisites](prerequisites.md).

## 2. Deploy Dataverse schema

Create three custom tables with logical names aligned to the shared contract.

### 2.1 SupervisionQueue

Create table `fsi_cg_fsw_queue` with at least these columns:

Choose **User or team** ownership at table creation if reviewers need access only
to assigned rows. An organization-owned table does not provide the same row-level
ownership model. Set the row owner or approved sharing/team access separately from
the custom `fsi_assignedprincipal` field.

| Column | Suggested type | Notes |
| --- | --- | --- |
| fsi_queuenumber | Text | Alternate key or duplicate detection candidate. |
| fsi_sourcetype | Text or Choice | Example: PurviewCommunicationCompliance. |
| fsi_sourceid | Text | Original source identifier from Purview item. |
| fsi_agentid | Text | Copilot or workload identifier. |
| fsi_zone | Text or Choice | Zone1, Zone2, or Zone3. |
| fsi_tier | Text or Choice | baseline, recommended, or regulated. |
| fsi_state | Text or Choice | PendingReview, InReview, Completed, Escalated. |
| fsi_assignedprincipal | Text, User, or Lookup | Reviewer assignment target. |
| fsi_sladue | Date and time | SLA due timestamp in UTC. |
| fsi_reviewoutcome | Text or Choice | Approved, Rejected, Escalated, ExceptionGranted. |
| fsi_reviewnotes | Multiline text | Reviewer notes and exception rationale. |

### 2.2 SupervisionLog

Create table `fsi_cg_fsw_log` with at least these columns:

| Column | Suggested type | Notes |
| --- | --- | --- |
| fsi_lognumber | Text | Alternate key or duplicate detection candidate. |
| fsi_queueitem | Lookup to fsi_cg_fsw_queue | Required for traceability. |
| fsi_action | Text | Example: ingested, assigned, review-complete, sla-breached. |
| fsi_actor | Text | User principal name, service account, or flow name. |
| fsi_timestamp | Date and time | UTC timestamp for append-only action ordering. |

### 2.3 SupervisionConfig

Create table `fsi_cg_fsw_config` with at least these columns:

| Column | Suggested type | Notes |
| --- | --- | --- |
| fsi_zone | Text or Choice | Zone1, Zone2, or Zone3. |
| fsi_tier | Text or Choice | baseline, recommended, or regulated. |
| fsi_slahours | Whole number | SLA hours for the zone and tier. |
| fsi_reviewpercent | Whole number | Sampling percentage for the zone and tier. |

### 2.4 Security and views

- Create personal or system views for open items by assigned principal, open breaches, and completed reviews by period.
- Restrict write access to SupervisionConfig to governance administrators.
- Withhold Write and Delete privileges on SupervisionLog from reviewers and flows; grant only the Create, Read, and relationship privileges needed for the workflow. Check all assigned roles because privileges are cumulative. This append-only pattern is not immutable storage and does not restrict an administrator who can change permissions.
- Discover each table's actual `EntitySetName` from the Dataverse Web API service document or table metadata, then update `dataverseTables[].entitySetName` in `config/default-config.json`. Do not derive a collection path by pluralizing a logical name. See [Query data using the Web API](https://learn.microsoft.com/power-apps/developer/data-platform/webapi/query/overview).

## 3. Create Power Automate flows

### 3.1 Ingest Flagged Items

1. Validate the Communication Compliance handoff with compliance operations before building the flow. Supported patterns include report exports, audit-log review, or a Power Automate flow launched from a Communication Compliance alert.
2. Use `fsi_cr_fsw_handoff` only for the validated handoff source and `fsi_cr_fsw_dataverse` for Dataverse actions.
3. Receive and validate the actual exported or alert-context metadata before mapping it to the queue. For the documented Power Automate path, use **Automate > Manage Power Automate flows** within an alert. No scheduled policy-match collector is supplied here; do not infer a supported connector or full-content export from the handoff description. See [Microsoft's alert-context integration](https://learn.microsoft.com/purview/communication-compliance-power-automate).
4. Map source metadata into `fsi_cg_fsw_queue`.
5. Write an `ingested` entry to `fsi_cg_fsw_log`.

### 3.2 Assignment Flow

1. Trigger when a new queue row is created.
2. Read the matching `fsi_cg_fsw_config` row by zone and tier.
3. Resolve the supervisory principal from the approved routing map.
4. Set `fsi_assignedprincipal` and `fsi_sladue`, and align actual queue-row ownership or approved sharing/team access with the assigned reviewer when row-scoped review is required.
5. Write an `assigned` log entry.

### 3.3 Escalation Flow

1. Run on a schedule that is shorter than the most aggressive SLA.
2. Query open queue rows where `fsi_sladue` is near or past due.
3. Notify escalation recipients based on tier configuration.
4. Write `sla-warning` or `sla-breached` actions to the log.
5. Capture exception details if an authorized supervisor grants more time.

### 3.4 Review Complete Flow

1. Trigger when `fsi_reviewoutcome` or `fsi_reviewnotes` changes.
2. Validate the outcome is in the allowed disposition list.
3. Set `fsi_state` to Completed or Escalated.
4. Write the final action to `fsi_cg_fsw_log`.
5. Preserve notes and exception reason codes.

## 4. Configure security roles

Create or update roles so that:

- Governance administrators can create, read, update, and delete configuration rows.
- Supervisory principals can read queue rows, update rows available through the approved ownership/sharing model, and create log rows. Verify the assignment field and actual access agree.
- Evidence analysts can read all three tables but cannot modify them.
- Service principals used by flows can create queue and log rows, update queue rows, and hold `Assign` and/or `Share` privileges on `fsi_cg_fsw_queue` when user/team-owned routing transfers row ownership or shares records with the assigned reviewer.

## 5. Apply tier configuration

1. Select one of the JSON tier files in `config`.
2. Run `scripts\Deploy-Solution.ps1` to generate the deployment manifest and stub files.
3. Seed `fsi_cg_fsw_config` with the zone and tier values from the chosen JSON file.
4. Update environment variables with the target environment URL and Purview policy ID.
5. Confirm the Escalation Flow uses the same `escalationEnabled` setting as the chosen JSON file.

## 6. Validation tests

Run the following commands after configuration is complete:

```powershell
.\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended -EnvironmentUrl https://contoso.crm.dynamics.com
.\scripts\Monitor-Compliance.ps1 -ConfigurationTier recommended -OutputPath .\artifacts\monitoring
.\scripts\Export-Evidence.ps1 -ConfigurationTier recommended -OutputPath .\artifacts\evidence -PeriodStart 2026-01-01 -PeriodEnd 2026-01-31
Invoke-Pester -Path .\tests\04-finra-supervision-workflow.Tests.ps1
```

Validation objectives:

- Policy coverage and applicable billing prerequisites match the Copilot surfaces tested; assigned reviewers can inspect the relevant matches and the validated handoff provides the required metadata.
- Queue items are created and assigned correctly.
- SLA values match supervisory policy.
- Escalation notifications fire for breached items.
- Review completion appends log entries; reviewer/flow identities cannot update or delete prior entries, and cumulative roles have been checked. Record administrator limitations rather than calling this immutable storage.
- Evidence export produces all required artifacts and hash files.

The repository commands above validate configuration and representative sample
output, not the deployed flow. Separately verify row ownership/access and denied
log updates/deletes in an approved customer validation environment. Record that
`immutableLogRequired` expresses intent only; export hashes detect later file
changes but do not enforce Dataverse storage controls. See
[Dataverse security roles and privileges](https://learn.microsoft.com/power-platform/admin/security-roles-privileges).
