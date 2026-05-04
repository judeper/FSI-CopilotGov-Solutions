# Delivery Checklist

Use this checklist before promoting the FINRA Supervision Workflow for Copilot solution into a managed Power Platform environment.

## 1. Prerequisites and access

- [ ] Confirm Power Apps Premium, Power Automate Premium, and eligible Communication Compliance licensing such as Microsoft Purview Suite (formerly Microsoft 365 E5 Compliance), Office 365 Enterprise E5, or Office 365 Enterprise E3 with Advanced Compliance are assigned.
- [ ] Confirm Power Platform administrator, Global Reader, and Communication Compliance Admins role group or Compliance Administrator role/role group access are available to the deployment team.
- [ ] Confirm Microsoft Entra ID groups exist for supervisory principals, escalation recipients, and service accounts.
- [ ] Confirm the target Dataverse environment URL is known and approved for use.
- [ ] Confirm PowerShell 7 or later is installed on the admin workstation.
- [ ] Confirm Microsoft Graph Audit Search permissions and any customer-validated Communication Compliance handoff (report export, audit-log review, or alert-launched Power Automate) are approved for live export or validation workflows.

## 2. Configuration files

- [ ] Review `config\default-config.json` for solution metadata, evidence outputs, and connection reference naming.
- [ ] Select the appropriate tier file: `baseline.json`, `recommended.json`, or `regulated.json`.
- [ ] Verify sampling rates align to supervisory policy for each enabled zone.
- [ ] Verify SLA hours align to written supervisory procedures.
- [ ] Verify evidence retention days align to records retention requirements.
- [ ] Replace placeholder values for Purview policy ID and Dataverse environment URL before production use.

## 3. Dataverse setup

- [ ] Create the `fsi_cg_fsw_queue` table with the required queue fields.
- [ ] Create the `fsi_cg_fsw_log` table with append-only action logging fields.
- [ ] Create the `fsi_cg_fsw_config` table with zone, tier, SLA, and sampling columns.
- [ ] Configure alternate keys or duplicate detection for queue and log numbers.
- [ ] Configure column security or role restrictions for review notes and exception details.
- [ ] Seed configuration rows for each supported zone and tier.

## 4. Power Automate flows

- [ ] Create the Ingest Flagged Items flow and validate the customer-approved Communication Compliance handoff (report export, audit-log review, or alert-launched Power Automate) rather than an unsupported scheduled policy-match polling connector.
- [ ] Create the Assignment Flow and validate principal routing by zone and tier.
- [ ] Create the Escalation Flow and validate warning and breach notifications.
- [ ] Create the Review Complete Flow and validate disposition logging.
- [ ] Create connection references `fsi_cr_fsw_handoff` (only for the validated handoff source) and `fsi_cr_fsw_dataverse`.
- [ ] Create environment variables `fsi_ev_fsw_purviewpolicyid`, `fsi_ev_fsw_environmenturl`, `fsi_ev_fsw_escalationenabled`, and `fsi_ev_fsw_defaulttier`.

## 5. Validation and evidence

- [ ] Run `scripts\Deploy-Solution.ps1` for the chosen tier and archive the deployment manifest.
- [ ] Run `scripts\Monitor-Compliance.ps1` and review any drift or partial control status findings.
- [ ] Run `scripts\Export-Evidence.ps1` for the current reporting period.
- [ ] Verify the evidence package contains `supervision-queue-snapshot`, `review-disposition-log`, and `sampling-summary`.
- [ ] Verify each evidence file has a matching `.sha256` companion file.
- [ ] Verify the final evidence package conforms to `config\evidence-schema.json`.

## 6. Sign-off

- [ ] Supervisory principal has reviewed queue routing, SLAs, and sampling thresholds.
- [ ] Compliance operations has approved the Purview policy scope and reviewer assignments.
- [ ] Power Platform administrator has approved Dataverse security roles and environment variables.
- [ ] Records management has approved the retention period for evidence artifacts.
- [ ] Project owner has recorded final deployment date, tier, and evidence package location.

