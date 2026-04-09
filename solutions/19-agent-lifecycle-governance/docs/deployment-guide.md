# Deployment Guide

This deployment guide follows a documentation-first pattern for Power Automate and Dataverse assets. Complete the design review steps before enabling live approval routing in a production tenant.

## Step 1: Confirm prerequisites and dependency readiness

1. Verify that solution `09-feature-management-controller` is already deployed.
2. Verify that solution `10-connector-plugin-governance` is already deployed for coordinated extensibility governance.
3. Confirm that the deployment team has:
   - Microsoft 365 Global Admin or Teams Admin access for agent management
   - Copilot Studio Environment Admin access for agent catalog and sharing restriction configuration
   - Dataverse System Administrator access
   - Power Automate Premium licensing
   - A reviewer mailbox or distribution group for approval tasks
4. Confirm the target Dataverse URL and reviewer email address.

## Step 2: Import or prepare the Dataverse solution

1. Create or import the Dataverse solution package for ALG in the target environment.
2. Create the Dataverse tables described in `docs\architecture.md`:
   - `fsi_cg_alg_baseline`
   - `fsi_cg_alg_finding`
   - `fsi_cg_alg_evidence`
3. Add columns for agent IDs, publisher types, risk categories, approval states, sharing scopes, and deployment rings.
4. Configure an alternate key on `agentId` in the baseline table to reduce duplicate records.

## Step 3: Configure approval workflow assets

1. Document and create the Power Automate flows:
   - `ALG-AgentRegistry`
   - `ALG-ApprovalRouter`
   - `ALG-SharingPolicyAudit`
2. Bind the flows to approved connection references only.
3. Configure the reviewer mailbox or approver distribution group used by `ALG-ApprovalRouter`.
4. If the tenant uses Teams-based notifications, validate Teams app policy and channel access before enabling alert delivery.

## Step 4: Select and review the governance tier

Review the tier JSON files under `config\` and confirm the operating model:

- `baseline.json`: Microsoft-published agents auto-approved, IT-developed and user-created agents reviewed within standard SLAs
- `recommended.json`: risk-based approval, 48 hour SLA for IT-developed agents, explicit security review for user-created agents
- `regulated.json`: all agents require approval, 24 hour SLA, mandatory CISO sign-off for user-created agents, 365 day evidence retention

Update agent risk categories, sharing policy controls, and SLA values if internal policy requires stricter treatment.

## Step 5: Run the deployment script

Execute the deployment script from the solution directory or repository root:

```powershell
.\solutions\19-agent-lifecycle-governance\scripts\Deploy-Solution.ps1 `
  -ConfigurationTier regulated `
  -TenantId <tenant-guid> `
  -DataverseUrl https://contoso.crm.dynamics.com `
  -ApproverEmail alg-reviewers@contoso.com `
  -OutputPath .\solutions\19-agent-lifecycle-governance\artifacts
```

Use `-WhatIf` first in regulated environments to preview agent classification and approval request generation.

## Step 6: Review the initial inventory run

After the script completes, review the generated artifacts:

- `alg-deployment-manifest.json`
- `alg-agent-registry.json`
- `alg-approval-register.json`
- `alg-sharing-policy-audit.json`

Validate that:

- Microsoft-published agents expected for the tenant are present
- IT-developed and user-created agents are classified correctly
- blocked agents appear as denied or blocked findings
- approval requests include the correct review stages and due dates
- sharing policy audit records reflect the current admin center configuration

## Step 7: Load baseline approvals and findings into Dataverse

1. Import approved agents into `fsi_cg_alg_baseline`.
2. Import unapproved or blocked items into `fsi_cg_alg_finding`.
3. Import sharing policy audit records into `fsi_cg_alg_evidence`.
4. Confirm that duplicate agent IDs are rejected or merged according to the Dataverse key design.

## Step 8: Enable monitoring and evidence export

Run monitoring and evidence export after the initial inventory load:

```powershell
.\solutions\19-agent-lifecycle-governance\scripts\Monitor-Compliance.ps1 `
  -ConfigurationTier regulated `
  -AlertOnNewAgents `
  -OutputPath .\solutions\19-agent-lifecycle-governance\artifacts

.\solutions\19-agent-lifecycle-governance\scripts\Export-Evidence.ps1 `
  -ConfigurationTier regulated `
  -OutputPath .\solutions\19-agent-lifecycle-governance\artifacts
```

Confirm that the evidence package captures agent registry, approval register, and sharing policy audit outputs with the expected `.sha256` companion file.

## Step 9: Integrate with solutions 09 and 10

Before production enablement:

1. Map approved agents to the rollout ring controls maintained by solution `09-feature-management-controller`.
2. Cross-reference agent connector dependencies with solution `10-connector-plugin-governance` approval records.
3. Keep new or user-created agents disabled until the approval register shows the required sign-off.
4. Align exception handling so a denied agent request also results in a rollout block or rollback action where needed.
