# Deployment Guide

## Prerequisites

Review [docs/prerequisites.md](prerequisites.md) before deployment. The deployment script assumes Power Platform admin access for the live integration target, an Entra ID application registration where authentication is later wired in, and PowerShell 7.2 or later.

## Step 1: Clone and Configure

```powershell
git clone https://github.com/judeper/FSI-CopilotGov-Solutions.git
Set-Location C:\Dev\FSI-CopilotGov-Solutions\solutions\23-copilot-studio-lifecycle-tracker
$env:AZURE_TENANT_ID = '<tenant-guid>'
```

Recommended secret-handling options when live integration is added:

- PowerShell SecretManagement or a managed vault
- Certificate-based authentication where permitted by the customer security team

## Step 2: Select Governance Tier and Review Configuration

Choose the governance tier that matches the operating model and review `config/<tier-name>.json` together with `config/default-config.json`.

- `baseline`: daily inventory, informational publishing approval recording, 180-day review cadence
- `recommended`: 8-hour inventory, single-approver publishing requirement, 90-day review cadence
- `regulated`: hourly inventory, dual-approver publishing requirement, 30-day review cadence, evidence immutability

## Step 3: Run Deploy-Solution.ps1 with -WhatIf First

```powershell
.\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended -OutputPath .\artifacts -WhatIf -Verbose
```

If the preview is acceptable, rerun without `-WhatIf`.

```powershell
.\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended -OutputPath .\artifacts -Verbose
```

## Step 4: Verify the Deployment Manifest

Confirm that the manifest is present in `artifacts/` and review:

- Selected tier and lifecycle review cadence
- Publishing approval requirement and approver count
- Versioning retention and deprecation notice window
- Dataverse table names and connection references

## Step 5: Run Initial Monitor-Compliance.ps1

```powershell
.\scripts\Monitor-Compliance.ps1 -ConfigurationTier recommended -OutputPath .\artifacts -Verbose
```

Review the output for:

- Agent inventory entries across the configured environments
- Publishing approval records that satisfy the tier requirement
- Lifecycle review findings, including any overdue agents
- Deprecation evidence entries for retired agents

## Step 6: Run Export-Evidence.ps1 and Verify .sha256

```powershell
.\scripts\Export-Evidence.ps1 -ConfigurationTier recommended -OutputPath .\artifacts -Verbose
```

Verify the following files exist:

- `agent-lifecycle-inventory-<tier>.json`
- `publishing-approval-log-<tier>.json`
- `version-history-<tier>.json`
- `deprecation-evidence-<tier>.json`
- Matching `.sha256` files for each JSON artifact

## Rollback Instructions

1. Remove the generated deployment manifest and lifecycle artifacts from the designated `artifacts/` path.
2. Revoke any monitoring identity credentials issued for the live integration when no longer required.
3. Archive prior evidence exports per the customer retention policy before deleting current working files.
