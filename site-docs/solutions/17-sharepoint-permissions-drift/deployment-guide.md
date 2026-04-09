# Deployment Guide — SharePoint Permissions Drift Detection

## Deployment Sequence

Follow these steps in order to deploy Solution 17 in your environment.

### Step 1 — Verify Upstream Output

Confirm that Solution 02 (Oversharing Risk Assessment) has been deployed or that the site inventory output is available for reference.

```powershell
# Check for Solution 02 deployment artifacts
Test-Path -Path ".\artifacts\deployment\ORA-deployment.json"
```

### Step 2 — Validate Prerequisites

Review [prerequisites.md](prerequisites.md) and confirm all platform, licensing, role, and module requirements are met.

```powershell
# Verify required modules
Get-Module -ListAvailable -Name PnP.PowerShell
Get-Module -ListAvailable -Name Microsoft.Graph
```

### Step 3 — Review Configuration

Select the appropriate configuration tier and review all configuration files:

- `config/default-config.json` — solution metadata and shared defaults
- `config/baseline-config.json` — baseline capture scope and retention
- `config/auto-revert-policy.json` — reversion mode and approval settings
- `config/{tier}.json` — tier-specific overrides

Update the `approvers` list in `auto-revert-policy.json` with actual email addresses for your institution.

### Step 4 — Run Deploy-Solution.ps1

```powershell
.\scripts\Deploy-Solution.ps1 `
    -ConfigurationTier recommended `
    -TenantId "00000000-0000-0000-0000-000000000000"
```

This validates configuration, checks prerequisites, and generates a deployment manifest.

### Step 5 — Capture Initial Baseline

Schedule the initial baseline capture during a period when permissions are in a known-good state (e.g., after a permissions review cycle).

```powershell
.\scripts\New-PermissionsBaseline.ps1 `
    -TenantUrl "https://contoso.sharepoint.com" `
    -OutputPath "./baselines" `
    -ConfigPath "./config/baseline-config.json"
```

### Step 6 — Run First Drift Scan

After the baseline is established, run an initial drift scan to verify the workflow:

```powershell
.\scripts\Invoke-DriftScan.ps1 `
    -TenantUrl "https://contoso.sharepoint.com" `
    -BaselinePath "./baselines/latest-baseline.json" `
    -OutputPath "./reports" `
    -ConfigPath "./config/baseline-config.json" `
    -AlertRecipient "compliance-officer@contoso.com"
```

### Step 7 — Review Drift Report

Examine the drift report output for accuracy. For the initial scan immediately after baseline capture, minimal or no drift should be detected.

### Step 8 — Configure Reversion Policy

Based on your institution's risk appetite, update `config/auto-revert-policy.json`:

- **Conservative** — Keep `autoRevertEnabled: false` (approval-gate for all drift)
- **Moderate** — Enable auto-revert for LOW-risk drift only
- **Aggressive** — Enable auto-revert for LOW and MEDIUM risk; approval-gate for HIGH

### Step 9 — Schedule Ongoing Scans

Configure a recurring schedule for drift scans:

```powershell
# Azure Automation Runbook or Windows Task Scheduler
.\scripts\Monitor-Compliance.ps1 `
    -ConfigurationTier recommended `
    -TenantId "00000000-0000-0000-0000-000000000000"
```

Default scan frequency is every 24 hours (configurable in `baseline-config.json`).

### Step 10 — Export Evidence

Generate the evidence package for compliance review:

```powershell
.\scripts\Export-DriftEvidence.ps1 `
    -DriftReportPath "./reports/drift-report-latest.json" `
    -BaselinePath "./baselines/latest-baseline.json" `
    -OutputPath "./evidence"
```

## Rollback Guidance

To roll back the solution:

1. Stop any scheduled drift scan jobs
2. Disable Power Automate approval flows
3. Archive baseline and drift report files
4. Remove application registration permissions (if no longer needed)
5. Notify stakeholders that drift monitoring has been suspended

> **Note:** Rolling back the solution does not revert any permission changes that were auto-reverted during operation. Review the reversion log before decommissioning.
