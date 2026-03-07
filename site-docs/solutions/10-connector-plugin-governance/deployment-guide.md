# Deployment Guide

This deployment guide follows a documentation-first pattern for Power Automate and Dataverse assets. Complete the design review steps before enabling live approval routing in a production tenant.

## Step 1: Confirm prerequisites and dependency readiness

1. Verify that solution `09-feature-management-controller` is already deployed.
2. Confirm that the deployment team has:
   - Power Platform Administrator access
   - Microsoft 365 Global Admin access for Teams app policy review
   - Dataverse System Administrator access
   - Power Automate Premium licensing
   - A reviewer mailbox or distribution group for approval tasks
3. Confirm the target Power Platform environment ID, Dataverse URL, and reviewer email address.

## Step 2: Import or prepare the Dataverse solution

1. Create or import the Dataverse solution package for CPG in the target environment.
2. Create the Dataverse tables described in `docs\architecture.md`:
   - `fsi_cg_cpg_baseline`
   - `fsi_cg_cpg_finding`
   - `fsi_cg_cpg_evidence`
3. Add columns for connector IDs, publishers, risk levels, approval states, and data-flow boundaries.
4. Configure an alternate key on `connectorId` in the baseline table to reduce duplicate records.

## Step 3: Configure approval workflow assets

1. Document and create the Power Automate flows:
   - `CPG-ConnectorInventory`
   - `CPG-ApprovalRouter`
   - `CPG-DataFlowAudit`
2. Bind the flows to approved connection references only.
3. Configure the reviewer mailbox or approver distribution group used by `CPG-ApprovalRouter`.
4. If the tenant uses Teams-based notifications, validate Teams app policy and channel access before enabling alert delivery.

## Step 4: Select and review the governance tier

Review the tier JSON files under `config\` and confirm the operating model:

- `baseline.json`: Microsoft-built connectors auto-approved, third-party requests reviewed within 72 hours
- `recommended.json`: low-risk auto-approval, 48 hour medium-risk review, explicit high-risk security review
- `regulated.json`: all connectors require approval, 24 hour SLA, mandatory CISO sign-off for high-risk scenarios, 365 day evidence retention

Update blocked connector IDs, data-flow boundaries, and SLA values if internal policy requires stricter treatment.

## Step 5: Run the deployment script

Execute the deployment script from the solution directory or repository root:

```powershell
.\solutions\10-connector-plugin-governance\scripts\Deploy-Solution.ps1 `
  -ConfigurationTier regulated `
  -TenantId <tenant-guid> `
  -Environment <power-platform-environment-id> `
  -DataverseUrl https://contoso.crm.dynamics.com `
  -ApproverEmail cpg-reviewers@contoso.com `
  -OutputPath .\solutions\10-connector-plugin-governance\artifacts `
  -BlockHighRiskConnectors
```

Use `-WhatIf` first in regulated environments to preview connector blocking and approval request generation.

## Step 6: Review the initial inventory run

After the script completes, review the generated artifacts:

- `cpg-deployment-manifest.json`
- `cpg-connector-inventory.json`
- `cpg-approval-register.json`
- `cpg-data-flow-attestations.json`

Validate that:

- Microsoft-built connectors expected for the tenant are present
- third-party and custom connectors are classified correctly
- blocked connectors appear as denied or blocked findings
- approval requests include the correct review stages and due dates

## Step 7: Load baseline approvals and findings into Dataverse

1. Import approved connectors into `fsi_cg_cpg_baseline`.
2. Import unapproved or blocked items into `fsi_cg_cpg_finding`.
3. Import cross-boundary attestation records into `fsi_cg_cpg_evidence`.
4. Confirm that duplicate connector IDs are rejected or merged according to the Dataverse key design.

## Step 8: Enable monitoring and evidence export

Run monitoring and evidence export after the initial inventory load:

```powershell
.\solutions\10-connector-plugin-governance\scripts\Monitor-Compliance.ps1 `
  -ConfigurationTier regulated `
  -AlertOnNewConnectors `
  -OutputPath .\solutions\10-connector-plugin-governance\artifacts

.\solutions\10-connector-plugin-governance\scripts\Export-Evidence.ps1 `
  -ConfigurationTier regulated `
  -OutputPath .\solutions\10-connector-plugin-governance\artifacts
```

Confirm that the evidence package captures connector inventory, approval register, and data-flow attestation outputs with the expected `.sha256` companion file.

## Step 9: Integrate with solution 09 rollout controls

Before production enablement:

1. Map approved connectors and plugins to the rollout ring controls maintained by solution `09-feature-management-controller`.
2. Keep new or high-risk connectors disabled until the approval register shows the required sign-off.
3. Align exception handling so a denied connector request also results in a rollout block or rollback action where needed.
