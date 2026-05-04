# Deployment Guide

## Pre-Deployment Checks

Before running the solution scripts, confirm the following:

- Microsoft 365 Copilot license inventory is known and finance-approved for the scoped population.
- Required Graph permissions are approved: `Reports.Read.All`, `LicenseAssignment.Read.All`, and `User.Read.All`; use `Directory.Read.All` only as a higher-privileged alternative when already approved.
- The target tenant has a documented owner for reallocation decisions and exception approvals.
- The dependency output from `11-risk-tiered-rollout` is available or an alternate protected-user list has been defined.
- Power BI workspace ownership, dataset refresh ownership, and retention expectations are documented.
- The automation host can reach `login.microsoftonline.com`, `graph.microsoft.com`, and `api.powerbi.com`.

## Step 1: Configure Authentication

Choose one of the following supported authentication patterns for Microsoft Graph:

### Option A: App registration

1. Create or identify an Entra ID app registration for LGR automation.
2. Grant application permissions for:
   - `Reports.Read.All`
   - `LicenseAssignment.Read.All` for license inventory via `subscribedSkus`
   - `User.Read.All`
3. Use `Directory.Read.All` only as a higher-privileged alternative when already approved.
4. Grant tenant admin consent.
5. Store the application secret or certificate outside the repository in the customer-approved secret store.
6. Record the tenant identifier that will be passed to `Deploy-Solution.ps1`.

### Option B: Service principal used by an automation platform

1. Create a service principal in the automation platform or deployment subscription.
2. Assign the same Graph permissions listed above.
3. Confirm the service principal can authenticate to Microsoft Graph from the scheduled execution host.
4. Document the execution identity in the delivery notes.

The current script validates connectivity planning and required endpoints. Replace the stub planning logic with the customer-approved live Graph connection process during implementation.

## Step 2: Run Deploy-Solution.ps1

From the solution root:

```powershell
.\scripts\Deploy-Solution.ps1 `
    -ConfigurationTier recommended `
    -TenantId '<tenant-guid>' `
    -Environment NonProd `
    -OutputPath '.\artifacts\deployment'
```

What this step does:

- Loads `default-config.json` and the selected tier settings.
- Builds a Graph query plan for user inventory, subscribed SKUs, and Copilot usage reporting.
- Documents Dataverse tables `fsi_cg_lgr_baseline`, `fsi_cg_lgr_finding`, and `fsi_cg_lgr_evidence`.
- Writes `08-license-governance-roi-deployment.json` to the chosen output path.

Use `-WhatIf` to review the deployment plan without writing the manifest:

```powershell
.\scripts\Deploy-Solution.ps1 -ConfigurationTier regulated -TenantId '<tenant-guid>' -Environment Prod -WhatIf
```

## Step 3: Configure the Power BI Dataset

This solution does not ship a `.pbix` file. Configure a customer-owned Power BI dataset using the architecture guidance:

1. Create a dataset or semantic model with the documented logical tables:
   - `LicenseInventorySnapshot`
   - `CopilotUsageDetail`
   - `VivaImpactSignals`
   - `RiskTierAssignments`
   - `ReallocationRecommendations`
2. Define relationships on `UserPrincipalName`, `BusinessUnit`, and reporting period where applicable.
3. Add measures for utilization percentage, inactive-seat count, recoverable spend, and ROI signal coverage.
4. Configure refresh credentials and, if required, an on-premises data gateway for curated feeds.
5. Restrict workspace access to governance reviewers, platform owners, and approved finance stakeholders.

## Step 4: Schedule Monitor-Compliance.ps1

Schedule the monitoring script using Task Scheduler, Azure Automation, GitHub Actions, or another approved orchestration platform:

```powershell
.\scripts\Monitor-Compliance.ps1 `
    -ConfigurationTier recommended `
    -OutputPath '.\artifacts\monitor'
```

Recommended cadence:

- Baseline: weekly review
- Recommended: every three to seven days
- Regulated: daily or every business day

The script output should feed both management review and the reallocation workflow. If solution `11-risk-tiered-rollout` identifies protected users, ensure that the monitoring output marks those users for manual review before any seat is reclaimed.

## Step 5: Validate Evidence Export

Generate an evidence package after the first monitoring run:

```powershell
.\scripts\Export-Evidence.ps1 `
    -ConfigurationTier recommended `
    -OutputPath '.\artifacts\evidence'
```

Then validate the generated package hash:

```powershell
Import-Module '..\..\scripts\common\EvidenceExport.psm1' -Force
Test-EvidencePackageHash -Path '.\artifacts\evidence\08-license-governance-roi-evidence.json'
```

Expected output:

- `08-license-governance-roi-evidence.json`
- `08-license-governance-roi-evidence.json.sha256`
- `license-utilization-report.json`
- `roi-scorecard.json`
- `reallocation-recommendations.csv`

## Rollback Steps

If the deployment must be rolled back:

1. Disable or remove the scheduled execution for `Monitor-Compliance.ps1`.
2. Archive or remove generated artifacts from the target output path if they were produced from an invalid configuration.
3. Revert the tier configuration to the last approved JSON settings.
4. Remove or deactivate the LGR Dataverse tables from the customer environment if they were provisioned as part of the deployment.
5. Revert Power BI dataset changes or restore the prior semantic model from the workspace deployment pipeline.
6. Document the rollback rationale and any seat-assignment exceptions that were opened during the failed deployment window.
