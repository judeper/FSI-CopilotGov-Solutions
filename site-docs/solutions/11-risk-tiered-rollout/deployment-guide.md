# Deployment Guide

## Deployment Objective

Deploy Risk-Tiered Rollout Automation so Copilot rollout activity can proceed through controlled pilot waves with documented prerequisites, approvals, and evidence collection. This guide assumes the target team will bind the documented Power Automate and Power BI assets during implementation.

## Prerequisites Verification

Before deployment, confirm the following:

- `01-copilot-readiness-scanner` is already deployed and has run successfully.
- A current readiness evidence file exists for the target tenant.
- Copilot seat inventory is available for the selected wave size plus rollback reserve.
- Dataverse and Power Automate Premium licensing are available in the target environment.
- Approval owners and CAB contacts are known for the selected governance tier.

## Step 1: Import the Dataverse Solution Package

1. Open the target Power Platform environment that will host rollout tracking.
2. Import the Dataverse solution package that contains the documented table model for:
   - `fsi_cg_rtr_baseline`
   - `fsi_cg_rtr_finding`
   - `fsi_cg_rtr_evidence`
3. Validate that table permissions align to rollout operations, compliance reviewers, and reporting users.
4. Confirm the environment uses the correct region, retention, and backup settings for the target regulatory posture.

## Step 2: Configure Environment Variables

Populate the environment variables or JSON values used by the deployment scripts and Power Automate flows. At a minimum, confirm:

- Tenant identifier
- Wave sizes for Wave 0 through Wave 3
- Tier classification criteria
- Approval-group identifiers
- Readiness evidence path from solution 01
- Notification recipients and channels

Recommended variables:

| Variable | Purpose |
|----------|---------|
| `RTR_TENANT_ID` | Tenant identifier used in manifests and approval messages |
| `RTR_READINESS_ARTIFACT` | Path to the latest readiness-scanner evidence package |
| `RTR_WAVE0_SIZE` | Pilot user limit for Wave 0 |
| `RTR_WAVE1_SIZE` | Expansion size for Wave 1 |
| `RTR_TIER2_APPROVER_GROUP` | Group or distribution list for Tier 2 gate approvers |
| `RTR_TIER3_CAB_GROUP` | CAB group for regulated Wave 3 approvals |

## Step 3: Deploy Power Automate Flows

Deploy the documented flow set in this order:

1. `Wave-Readiness-Check`
   - Validate the trigger can read the readiness artifact from solution 01.
   - Confirm it writes blocked-user findings to `fsi_cg_rtr_finding`.
2. `Gate-Approval-Request`
   - Validate the approver routing logic for baseline, recommended, and regulated tiers.
   - Confirm approval outcomes are written to `fsi_cg_rtr_evidence` or the linked approval-history store.
3. `License-Assignment-Trigger`
   - Validate secure connection references for Graph-based assignment actions.
   - Confirm failed assignments generate a finding and do not silently advance the wave.

## Step 4: Run Deploy-Solution.ps1 with the Initial Wave Configuration

From the solution directory, preview the first wave before any live assignment action:

```powershell
pwsh -File .\scripts\Deploy-Solution.ps1 `
  -ConfigurationTier recommended `
  -TenantId "contoso.onmicrosoft.com" `
  -WaveNumber 0 `
  -Environment "Pilot" `
  -OutputPath .\artifacts `
  -WhatIf
```

Then run the same command without `-WhatIf` when the previewed manifest matches the approved Wave 0 plan. Review the generated `RTR-wave-0-manifest.json` file for:

- Cohort membership
- Risk tiers
- Blocked users and blocker reasons
- Required gate criteria
- License-assignment staging actions

## Step 5: Execute Wave 0 Pilot

1. Review the Wave 0 manifest with the rollout owner and service desk lead.
2. Confirm pilot support coverage and escalation paths for the pilot window.
3. Stage the license-assignment intent for the approved pilot cohort. `Deploy-Solution.ps1` honors a dry-run-by-default posture: `-TriggerLicenseAssignment` on its own produces a **preview** manifest (`licenseAssignment.mode` = `preview`, cohort `assignmentState` = `manifest-only`). To record staged intents for customer-run execution, re-run with `-TriggerLicenseAssignment -ConfirmAssignmentIntentStaging` after the preview is approved. No license is assigned by this script; execution is customer-run and must resolve the tenant `skuId` from `GET /subscribedSkus` (see prerequisites).
4. Run `Monitor-Compliance.ps1` for Wave 0 and record:
   - readiness percent
   - blocked-user count
   - gate-completion status
   - wave health score
5. Export evidence after the pilot begins so approval, readiness, and dashboard artifacts are captured from the first controlled release.

## Step 6: Gate Review and Wave 1 Expansion

Wave 1 should not start until Wave 0 has been reviewed and approved. Recommended review steps:

1. Run `Monitor-Compliance.ps1 -WaveNumber 0`.
2. Confirm the health score meets the configured threshold for expansion.
3. Review open incidents, blocked users, and unresolved findings.
4. Trigger `Gate-Approval-Request` and capture the approver decision.
5. Update the wave number to `1` in `Deploy-Solution.ps1` and generate the next manifest.
6. Repeat the same gate-review pattern for each later wave, adding Tier 2 and Tier 3 controls where required.

## Rollback and Revocation

Safe rollback requires captured prior state and clear ownership **before** any license or group change:

1. Record the rollback owner and approver, and capture each affected user's prior assignment state — whether the Copilot license is **directly assigned** or **inherited from a group** — from `assignedLicenses`/`licenseAssignmentStates` before any removal. Only remove licenses or group memberships that this rollout added; never remove a pre-existing or inherited assignment without recorded ownership.
2. Freeze additional assignments by disabling `License-Assignment-Trigger`.
3. Export the latest evidence package so the rollback start point is preserved.
4. Revoke the affected wave assignments through the correct scope:
   - for group-inherited licenses, remove the user from the wave-based assignment group (an inherited license cannot be removed by a direct user `removeLicenses` call), or
   - for directly assigned licenses, use the tenant-approved Graph (`POST /users/{id}/assignLicense` with `removeLicenses` carrying the tenant `skuId`) or admin process
5. Mark rollback findings in `fsi_cg_rtr_finding` with owner and remediation dates.
6. Record the rollback approval or incident identifier in the approval-history artifact.
7. Re-run `Monitor-Compliance.ps1` to confirm the affected wave is now blocked and awaiting remediation.

## Lab Validation Handoff

A machine-readable lab-validation contract is provided at
`lab/11-risk-tiered-rollout.lab.json` for the external Playwright/API lab executor.
The first validation cycle is **read-only / detect-only**
(`mutations: []`): it verifies tenant identity, discovers the Microsoft 365 Copilot SKU from
`GET /subscribedSkus` by `skuPartNumber`, reads the test cohort group metadata and current
`assignedLicenses`, and confirms documentation source claims — without assigning or removing any
license. Disposable license assignment is intentionally deferred until exact prior-state capture and
ownership can be enforced for a safe, reversible mutation. The contract carries no real tenant IDs,
secrets, or user PII.

## Post-Deployment Review

- Validate the Power BI dashboard refreshes with the latest Dataverse data.
- Confirm approval history is complete for every expanded wave.
- Confirm evidence retention matches the selected governance tier.
- Review stale-readiness detection before scheduling the next wave.
