# Deployment Guide

## Dependency Verification

Before deploying solution 03, confirm the following dependency states:

- `01-copilot-readiness-scanner` baseline complete
- `02-oversharing-risk-assessment` initial scan complete

The auditor depends on readiness scope from solution 01 and uses solution 02 findings to prioritize unlabeled content in high-risk containers.

## Prerequisites Check

1. Review `docs\prerequisites.md`.
2. Confirm the deployment operator has the required admin role and Graph permissions.
3. Confirm the target tenant has the appropriate Purview and Microsoft 365 Compliance licensing.
4. Confirm the label taxonomy has been approved for Copilot-facing workloads.

## Step 1: Review Label Taxonomy in Purview Portal

Validate that the deployed labels match the FSI governance model:

- Tier 1: Public
- Tier 2: Internal
- Tier 3: Confidential
- Tier 4: Highly Confidential
- Tier 5: Restricted

Confirm that regulated repositories, mailboxes, and records locations have a documented expected label or default label policy.

## Step 2: Configure `config\*.json`

Update configuration values before the first scan:

- Set `coverageThreshold` in `config\default-config.json`.
- Set `workloadsToAudit` in the selected tier file.
- Populate `prioritySites` with regulated SharePoint or OneDrive locations that require elevated scanning attention.
- Confirm `remediationManifestMaxItems` aligns to available operations capacity.
- Set notification and evidence retention settings for the chosen governance tier.

## Step 3: Run `Deploy-Solution.ps1`

Register the deployment and capture a label taxonomy snapshot.

```powershell
.\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId "<tenant-id>" -OutputPath ".\artifacts\deployment"
```

Expected outcome:

- Tier configuration is loaded.
- Placeholder Purview licensing validation is recorded.
- Upstream dependencies are validated.
- A deployment manifest and deployment registration record are written to the output path.

## Step 4: Run Initial Coverage Scan with `Monitor-Compliance.ps1`

Run the first monitoring pass to generate workload metrics.

```powershell
.\scripts\Monitor-Compliance.ps1 -ConfigurationTier recommended -TenantId "<tenant-id>" -OutputPath ".\artifacts\monitoring"
```

Expected outcome:

- Per-workload coverage report is generated.
- Label tier distribution is calculated.
- Oversharing findings are cross-referenced if solution 02 output is present.
- Gap findings are produced for unlabeled sites, drives, and mailboxes.

## Step 5: Review `label-gap-findings`

Review the findings with compliance, records, and workload owners:

- Confirm the highest-priority unlabeled containers are accurate.
- Validate risk scores for regulated sites and mailboxes.
- Confirm any false positives or known migration exceptions are documented.

## Step 6: Generate `remediation-manifest`

The monitoring and export scripts generate a remediation manifest that:

- ranks the highest-priority unlabeled containers
- recommends a likely next label
- supports approval before bulk remediation

Use the manifest to separate immediate corrective action from longer-term policy tuning.

## Step 7: Plan Remediation Waves

Plan remediation in waves with data owners and service administrators.

- Respect the Purview auto-labeling cap of 100,000 files per day per tenant.
- Use bulk labeling only after owner review and change approval.
- Sequence regulated repositories and mailboxes ahead of general collaboration areas.

## Step 8: Export Evidence Package

Create the evidence outputs and SHA-256 companion files:

```powershell
.\scripts\Export-Evidence.ps1 -ConfigurationTier recommended -TenantId "<tenant-id>" -OutputPath ".\artifacts\evidence"
```

Review the resulting package for:

- `label-coverage-report`
- `label-gap-findings`
- `remediation-manifest`
- package metadata, control statuses, and artifact paths

## Rollback

This solution is monitor-only during the initial deployment path and does not make destructive configuration changes by default. If a rollout must be paused, stop scheduled executions, archive the deployment manifest, and review the current gap findings before enabling any bulk labeling activity.
