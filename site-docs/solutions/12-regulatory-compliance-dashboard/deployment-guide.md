# Deployment Guide

## Deployment Sequence

This solution is deployed after the evidence-producing solutions it depends on. Use the steps below to stage Dataverse, flows, and the documentation-led Power BI dataset in a controlled order.

## Verify Dependency Solutions

Before deploying the dashboard, confirm the following solutions are already deployed in the target environment:

- `06-audit-trail-manager`
- `11-risk-tiered-rollout`

Recommended validation checks:

- Confirm each dependency can run its evidence export script successfully.
- Confirm each dependency publishes current evidence packages and hash files.
- Confirm the target environment can access Dataverse, Power Automate, and Power BI with the same tenant context.

## Step 1: Import Dataverse Solution

Import the Dataverse solution components that define the dashboard storage layer:

- `fsi_cg_rcd_baseline`
- `fsi_cg_rcd_finding`
- `fsi_cg_rcd_evidence`

Verify table creation before proceeding. The deployment script documents these table contracts, but environment administrators should create or import them in Dataverse before connecting the Power BI dataset.

## Step 2: Configure Environment Variables

Set environment variables or deployment settings for the dashboard:

- Evidence aggregation source list, including solutions 01-15 or the subset currently deployed
- Evidence freshness thresholds by tier
- Dataverse URL
- Power BI workspace name
- Examination package output location
- Notification channel for stale evidence alerts

Suggested variable names:

- `fsi_cg_rcd_EvidenceSources`
- `fsi_cg_rcd_FreshnessThresholdHours`
- `fsi_cg_rcd_DataverseUrl`
- `fsi_cg_rcd_PowerBIWorkspace`
- `fsi_cg_rcd_ExaminationPackageTarget`

## Step 3: Deploy Power Automate Flows

Deploy and configure the following flows:

- `RCD-EvidenceAggregator` for daily evidence normalization
- `RCD-FreshnessMonitor` for hourly stale evidence checks
- `RCD-ExaminationPackager` for on-demand packaging

Update connection references after import and confirm that the Dataverse, Power BI, and storage connectors are authenticated successfully.

## Step 4: Run Deploy-Solution.ps1

From the solution root, run the deployment script to validate dependencies and generate the initial control status snapshot:

```powershell
pwsh .\scripts\Deploy-Solution.ps1 `
  -ConfigurationTier recommended `
  -TenantId '00000000-0000-0000-0000-000000000000' `
  -Environment 'fsi-copilotgov-dev' `
  -DataverseUrl 'https://contoso.crm.dynamics.com'
```

Expected outputs:

- Control status snapshot seed JSON
- Dataverse table contract JSON
- Deployment manifest for the selected tier

Use `-WhatIf` for change review before writing artifacts.

## Step 5: Import Power BI Template and Configure Dataset

This repository does not store a binary `.pbix` or `.pbit`. Instead, use the documented template specification from `docs\architecture.md` to create or update the Power BI report with these dataset tables:

- `ControlMaster`
- `ImplementationStatus`
- `EvidenceLog`
- `RegulatoryMapping`

Configure dataset relationships, DAX measures, and report pages for executive summary, control RAG, evidence freshness, regulatory coverage, and examination readiness.

## Step 6: Configure Data Refresh Schedule

Configure scheduled refresh after the dataset is bound:

- Daily full refresh for the dashboard dataset
- Hourly freshness status recalculation for evidence age flags
- On-demand refresh before generating examination readiness packages

If gateway settings are required by your environment, validate credentials before publishing the report.

## Step 7: Publish to Power BI Workspace and Set Up Row-Level Security

Publish the report to the target workspace and configure row-level security for at least these audiences:

- Executive readers
- Control owners
- Regulatory readiness or audit reviewers

Recommended RLS filters:

- Business unit
- Legal entity
- Region
- Solution owner group

## Post-Deployment Validation

After deployment:

1. Run `scripts\Monitor-Compliance.ps1` and confirm the maturity score and freshness results are returned.
2. Run `scripts\Export-Evidence.ps1` and confirm both the evidence JSON and `.sha256` files are created.
3. Validate that the Power BI coverage matrix reflects the enabled frameworks for the chosen tier.
4. Generate at least one examination readiness package to confirm the packaging flow is wired correctly.
