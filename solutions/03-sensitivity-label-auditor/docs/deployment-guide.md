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

In the Microsoft Purview portal, open **Solutions > Information Protection >
Sensitivity labels** and review the existing taxonomy with approved read access.
Observe label groups and migration availability without starting migration;
[migration is irreversible](https://learn.microsoft.com/purview/migrate-sensitivity-label-scheme).

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
- Treat `maxItemsPerScan: -1` in the regulated tier as no configured per-workload cap; tenant-specific implementations should still set operational guardrails before live scans.
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

These outputs use representative sample data, not a live tenant assessment.
A future collector must distinguish confirmed label absence from extraction
errors, unsupported files, and unavailable message metadata. Label presence does
not itself establish encryption or Copilot exclusion.

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

- The [dedicated Purview auto-labeling article](https://learn.microsoft.com/purview/apply-sensitivity-label-automatically) currently documents a ceiling of 500,000 automatically labeled files per tenant per day. The [SharePoint/OneDrive PDF guidance](https://learn.microsoft.com/purview/sensitivity-labels-sharepoint-onedrive-files) still states 100,000 per day; confirm the applicable service limit before sizing waves. Do not treat either figure as a guaranteed processing rate or Graph assignment quota.
- Use bulk labeling only after owner review and change approval.
- For a separately approved Graph `assignSensitivityLabel` extension, verify protected-API access, metered API setup, the correct write permission, and completed asynchronous operation status. The monitor does not perform assignment.
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
