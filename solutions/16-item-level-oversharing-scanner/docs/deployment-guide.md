# Deployment Guide

## Deployment Sequence

Follow this sequence to deploy solution 16 in a controlled manner.

## 1. Verify Upstream Output

Before deploying, confirm that solution 02-oversharing-risk-assessment has already produced site-level findings. The deployment script checks for upstream evidence so item-level scans can be targeted at sites already flagged for broad sharing, guest access, or regulated content exposure.

## 2. Run the Prerequisites Check

Review [prerequisites.md](prerequisites.md) and confirm:

- PnP PowerShell module is installed and can connect to the target SharePoint tenant
- Required admin roles are assigned
- API permissions are configured for item-level permission enumeration

## 3. Review and Adjust Configuration

Inspect the JSON files under `config\`:

- `default-config.json` for common defaults, controls, and scan limits
- `risk-thresholds.json` for base risk scores and content-type weighting multipliers
- `remediation-policy.json` for remediation mode per risk tier
- `baseline.json` for minimal rollout posture
- `recommended.json` for broader scanning scope
- `regulated.json` for extended evidence retention and examiner-ready requirements

Tune `maxSitesPerRun`, `maxItemsPerLibrary`, and risk threshold settings before the first execution window.

## 4. Run Deploy-Solution.ps1

Example deployment:

```powershell
.\scripts\Deploy-Solution.ps1 `
  -ConfigurationTier recommended `
  -TenantId 00000000-0000-0000-0000-000000000000 `
  -OutputPath .\artifacts\deployment
```

Expected outcomes:

- Selected configuration is merged and validated
- Upstream dependency status is captured
- A deployment manifest is written to the output path

## 5. Run the Item-Level Scan

Start with a constrained set of high-risk sites:

```powershell
.\scripts\Get-ItemLevelPermissions.ps1 `
  -SiteUrls @("https://tenant.sharepoint.com/sites/finance","https://tenant.sharepoint.com/sites/legal") `
  -TenantUrl "https://tenant-admin.sharepoint.com" `
  -OutputPath .\artifacts\scan
```

Why start small:

- Validates PnP connectivity and permissions enumeration
- Helps identify throttling thresholds for the tenant
- Reduces the chance of disrupting production workloads during pilot

## 6. Apply FSI Risk Scoring

Run the scoring script against the scan output:

```powershell
.\scripts\Export-OversharedItems.ps1 `
  -InputPath .\artifacts\scan\item-permissions.csv `
  -OutputPath .\artifacts\scored `
  -ConfigPath .\config\risk-thresholds.json
```

Review the risk-scored report for:

- HIGH-risk items with anyone links or external sharing of sensitive content
- MEDIUM-risk items with organization-wide edit access
- LOW-risk items with broad group access

## 7. Review Remediation Actions

Run the remediation script in approval-gate mode (the default):

```powershell
.\scripts\Invoke-BulkRemediation.ps1 `
  -InputPath .\artifacts\scored\risk-scored-report.csv `
  -OutputPath .\artifacts\remediation `
  -ConfigPath .\config\remediation-policy.json `
  -TenantUrl "https://tenant-admin.sharepoint.com"
```

Review the `pending-approvals.json` output before approving any actions. Cross-check HIGH-risk items with site owners and compliance reviewers.

## 8. Plan Remediation Waves

Recommended sequence:

1. Wave 1: HIGH-risk items with anyone links or external sharing of PII/trading data
2. Wave 2: MEDIUM-risk items with organization-wide edit access
3. Wave 3: LOW-risk items with broad group access

Document the owner, due date, approval path, and rollback expectation for each wave.

## 9. Export Evidence

Run the evidence export after each scan or remediation cycle:

```powershell
.\scripts\Export-Evidence.ps1 `
  -ConfigurationTier recommended `
  -TenantId 00000000-0000-0000-0000-000000000000 `
  -OutputPath .\artifacts\evidence `
  -PeriodStart (Get-Date).AddDays(-7) `
  -PeriodEnd (Get-Date)
```

The export writes:

- `item-oversharing-findings.json`
- `risk-scored-report.json`
- `remediation-actions.json`
- A schema-aligned evidence package and `.sha256` checksum files

## 10. Rollback Guidance

If deployment settings need to be reversed:

1. Stop any in-progress remediation by removing pending approvals
2. Revert to the previous tier JSON
3. Archive the evidence from the failed or rolled-back window for audit traceability
4. Re-run the scan to confirm the items are back to the intended permission state

Rollback decisions should be documented whenever item permissions are changed after approval.
