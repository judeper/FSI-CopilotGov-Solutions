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
5. Record the Microsoft Purview Communication Compliance policy ID for the policy that detects Microsoft 365 Copilot and Microsoft 365 Copilot Chat interactions. Use the **Detect Microsoft Copilot interactions** template, or a custom policy that includes the **Microsoft Copilot experiences** location, and confirm reviewers are named on the policy.

## 2. Deploy Dataverse schema

Create three custom tables with logical names aligned to the shared contract.

### 2.1 SupervisionQueue

Create table `fsi_cg_fsw_queue` with at least these columns:

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
| fsi_queueitem | Lookup to fsi_cg_fsw_queue, or Text | Required for traceability. If implemented as a lookup, its Web API value is exposed as `_fsi_queueitem_value`; align the live-export `$select` accordingly. |
| fsi_action | Text | Example: ingested, assigned, review-complete, sla-breached. |
| fsi_actor | Text | User principal name, service account, or flow name. |
| fsi_timestamp | Date and time | UTC timestamp for append-only governance ordering; not a platform immutability guarantee. |

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
- Restrict update access to SupervisionLog so reviewers and flows can append but not change prior entries.

### 2.5 Confirm Web API entity set names

Before configuring live evidence export or any raw Dataverse Web API call, read each table's `EntitySetName` from tenant metadata rather than assuming the default plural collection name:

```http
GET {environmentUrl}/api/data/v9.2/EntityDefinitions(LogicalName='fsi_cg_fsw_queue')?$select=EntitySetName
```

Repeat for `fsi_cg_fsw_log` and `fsi_cg_fsw_config`, then align the `entitySetName` values in `config\default-config.json`. The Microsoft Dataverse connector actions ("Add a row", "List rows") resolve the entity set from the table's logical name, but any HTTP-with-Entra actions in the flows must target the metadata-confirmed entity set name.

## 3. Create Power Automate flows

### 3.1 Ingest Flagged Items

1. Validate the Communication Compliance handoff with compliance operations before building the flow. Supported patterns include report exports, audit-log review, or a Power Automate flow created from a recommended default template through the **Automate** menu on a Communication Compliance alert.
2. Use `fsi_cr_fsw_handoff` only for the validated handoff source and `fsi_cr_fsw_dataverse` for Dataverse actions.
3. Receive exported or alert-context Copilot communication metadata; do not configure unsupported scheduled polling of policy matches.
4. Map source metadata into `fsi_cg_fsw_queue`.
5. Write an `ingested` entry to `fsi_cg_fsw_log`.

### 3.2 Assignment Flow

1. Trigger when a new queue row is created.
2. Read the matching `fsi_cg_fsw_config` row by zone and tier.
3. Resolve the supervisory principal from the approved routing map.
4. Set `fsi_assignedprincipal` and `fsi_sladue`.
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
- Supervisory principals can read queue rows, update assigned rows, and create log rows.
- Evidence analysts can read all three tables but cannot modify them.
- Service principals used by flows can create queue and log rows and update queue rows.

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

- Queue items are created and assigned correctly.
- SLA values match supervisory policy.
- Escalation notifications fire for breached items.
- Review completion writes append-only governance log entries under restricted update permissions.
- Evidence export produces all required artifacts and hash files.

## 7. Lab validation handoff

A machine-readable lab validation contract is provided at
`lab\04-finra-supervision-workflow.lab.json`. It defines a **read-only, detect-only**
first cycle (`mutations: []`) for validating this solution against a US commercial-cloud
Microsoft 365 tenant without changing any policy, case, review, Dataverse row, flow,
retention, or role. The contract records the Microsoft source claims behind the
Communication Compliance, licensing, role, Power Automate handoff, and Dataverse Web API
statements in this solution.

- Validate the contract with `python scripts\validate-lab-contracts.py solutions\04-finra-supervision-workflow\lab\04-finra-supervision-workflow.lab.json`.
- The contract's execution phases cover confirming licensing and reviewer roles, running the
  documentation-first scripts and flow contract offline, inspecting the existing
  Communication Compliance policy and Copilot interaction scope read-only, and reading each
  Dataverse table's `EntitySetName` from metadata read-only.
- Tenant identity must match a separately maintained sanctioned-lab record. Dataverse metadata
  reads use runtime environment URL/token variables and fail closed on missing or placeholder
  values; any EntitySetName mismatch is recorded as follow-up rather than changed in this cycle.
- Offline artifacts use ignored `lab-evidence/04-finra-supervision-workflow` staging, which is
  removed fail-closed after the lab result packager captures required evidence.
- Runtime execution and evidence capture happen in the separate studio executor lane; this
  repository stores only the contract and its validators.
