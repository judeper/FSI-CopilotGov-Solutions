# Deployment Guide

## Overview

Use this guide to deploy the Copilot Readiness Assessment Scanner into a target tenant, establish the first readiness baseline, and export evidence artifacts for downstream review. The deployment sequence is intentionally simple: validate prerequisites, choose the governance tier, configure the solution, deploy, baseline, export evidence, and review the outputs.

## Prerequisites Check

Before deployment, confirm the following:

- PowerShell 7.x is installed.
- Required modules are available: `Microsoft.Graph`, `ExchangeOnlineManagement`, `PnP.PowerShell`, and `MicrosoftTeams`.
- The operator has Global Administrator rights or the documented combination of workload-specific roles from [prerequisites.md](./prerequisites.md).
- The target output location is approved for the intended evidence retention period.
- Network egress to Microsoft Graph, SharePoint Online, Teams, Power Platform admin endpoints, and Purview services is allowed.

## Step 1: Clone or Navigate to the Solution

```powershell
Set-Location 'C:\Dev\FSI-CopilotGov-Solutions\solutions\01-copilot-readiness-scanner'
```

If the repository is already cloned, ensure you are working from the solution folder so relative configuration and artifact paths resolve correctly.

## Step 2: Select the Governance Tier

Choose one of the tier files under `config\`:

- `baseline.json` for minimum viable governance and weekly scanning
- `recommended.json` for stronger production coverage and daily scanning
- `regulated.json` for examination-ready posture, continuous scanning intent, and long-term evidence retention

The selected tier controls the alert threshold, retention expectation, scan cadence, guest account handling, and Power BI dashboard behavior.

## Step 3: Configure `config\*.json`

Review and update the configuration files before deployment:

1. Open `config\default-config.json` and confirm solution metadata, report format, Graph API version, scan domains, and scoring weights.
2. Open the selected tier file and confirm:
   - `evidenceRetentionDays`
   - `scanSchedule`
   - `alertThreshold`
   - `maxSitesScanned`
   - `includeGuestAccounts`
   - `notificationMode`
3. Ensure the configuration reflects the customer risk posture and operational capacity.

## Step 4: Run `Deploy-Solution.ps1`

```powershell
.\scripts\Deploy-Solution.ps1 `
    -ConfigurationTier recommended `
    -TenantId 'contoso.onmicrosoft.com' `
    -OutputPath '.\artifacts'
```

What the deployment script does:

- Loads default and tier-specific configuration
- Validates required PowerShell modules and shared module dependencies
- Performs a placeholder Graph connectivity check for the target tenant
- Creates a deployment manifest
- Appends a deployment entry to a local deployment log

Use `-WhatIf` when you want to preview the deployment behavior without writing artifacts.

## Step 5: Run `Monitor-Compliance.ps1` to Establish a Baseline

```powershell
.\scripts\Monitor-Compliance.ps1 `
    -ConfigurationTier recommended `
    -TenantId 'contoso.onmicrosoft.com' `
    -ExportPath '.\artifacts'
```

Optional domain scoping example:

```powershell
.\scripts\Monitor-Compliance.ps1 `
    -ConfigurationTier recommended `
    -TenantId 'contoso.onmicrosoft.com' `
    -Domains licensing,identity,purview,copilotConfig `
    -ExportPath '.\artifacts'
```

The script returns a structured domain result object for each requested scan domain, including score, status, issue list, and timestamp.

## Step 6: Export Evidence with `Export-Evidence.ps1`

```powershell
.\scripts\Export-Evidence.ps1 `
    -ConfigurationTier recommended `
    -TenantId 'contoso.onmicrosoft.com' `
    -OutputPath '.\artifacts' `
    -PeriodStart (Get-Date).AddDays(-30) `
    -PeriodEnd (Get-Date)
```

The export creates:

- `readiness-scorecard`
- `data-hygiene-findings`
- `remediation-plan`
- a schema-aligned evidence package JSON file
- a `.sha256` companion file for every JSON artifact

## Step 7: Review Artifacts

Review the generated files under the output folder:

- Confirm the deployment manifest matches the selected tier.
- Confirm the monitoring baseline includes all required domains.
- Confirm the evidence package contains metadata, summary, controls, and artifacts.
- Confirm every JSON artifact has a matching `.sha256` file.
- Confirm the output naming convention aligns with the expected Power BI ingestion pattern.

## Troubleshooting

Deployment issues are most commonly caused by permissions, missing modules, or invalid configuration references.

- Authentication failure: verify the tenant identifier, sign-in context, and Graph scopes.
- Missing tier file: confirm the selected configuration file exists and is named correctly.
- SharePoint connection issues: confirm the operator can authenticate to PnP PowerShell and that the tenant admin URL is reachable.
- Evidence export path failures: confirm the output folder exists or that the operator can create it.

See [troubleshooting.md](./troubleshooting.md) for detailed diagnostic steps and remediation guidance.

## Dependency Statement

This solution has no upstream solution dependencies. It only relies on repository shared modules and Microsoft 365 administrative access required for the scanner workloads.
