# Deployment Guide

## Prerequisites

Review [docs/prerequisites.md](prerequisites.md) before deployment. PNRT assumes Microsoft 365 with Copilot, OneNote, and Loop enabled, an Entra ID application registration with read-only scopes, and PowerShell 7.2 or later.

## Step 1: Clone and Configure

1. Clone the repository and move to the PNRT solution directory.
2. Set environment variables for the tenant and application identity.
3. Handle the client secret through a secure input method or an approved secret-management platform.

```powershell
git clone https://github.com/judeper/FSI-CopilotGov-Solutions.git
Set-Location C:\Dev\FSI-CopilotGov-Solutions\solutions\22-pages-notebooks-retention-tracker
$env:AZURE_TENANT_ID = '<tenant-guid>'
$env:AZURE_CLIENT_ID = '<app-registration-guid>'
```

## Step 2: Select Governance Tier and Review Configuration

Choose the governance tier that matches the operating model and review `config/<tier-name>.json` together with `config/default-config.json`.

- `baseline`: 365-day retention defaults, summary branching audit, optional Loop provenance
- `recommended`: 7-year retention defaults, full branching audit, required Loop provenance, retention-label inheritance check
- `regulated`: 7-year retention with preservation-lock expectations, signed Loop lineage, supervisory-review queue, WORM storage settings aligned to SEC Rule 17a-4(f) for in-scope records

Confirm the following before deployment:

- Retention values match the customer records-management policy and any specific records subject to SEC Rule 17a-4 or FINRA Rule 4511(a).
- Loop workspace seed list reflects the workspaces in scope for provenance reporting.
- Evidence output path is on a controlled location with write access.

## Step 3: Run Deploy-Solution.ps1 with -WhatIf First

```powershell
.\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId $env:AZURE_TENANT_ID -OutputPath .\artifacts -WhatIf -Verbose
```

If the preview is acceptable, rerun without `-WhatIf` to write the deployment manifest.

## Step 4: Run Monitor-Compliance.ps1 to Capture the Initial Sample Inventory

```powershell
.\scripts\Monitor-Compliance.ps1 -ConfigurationTier recommended -OutputPath .\artifacts -Verbose
```

Review the output for:

- Pages inventory with retention labels and mutability state
- Notebook retention assignment summary
- Loop component provenance records
- Branching event records for the sample period

## Step 5: Configure the Documentation-First Power Automate Flow

This solution uses a documentation-first pattern for Power Automate.

1. Create a scheduled cloud flow that runs at the interval defined by the selected tier.
2. Read the monitoring snapshot or invoke the monitoring script through an approved automation host.
3. Route retention-coverage gaps to the records-management and compliance distribution lists.
4. In the regulated tier, route preservation-lock requests and supervisory-review tasks to the designated reviewer queue.

The repository does not deploy the flow automatically.

## Step 6: Run Export-Evidence.ps1 and Verify .sha256

```powershell
.\scripts\Export-Evidence.ps1 -ConfigurationTier recommended -OutputPath .\artifacts -Verbose
```

Verify the following files exist:

- `pages-retention-inventory-<tier>.json` and matching `.sha256`
- `notebook-retention-log-<tier>.json` and matching `.sha256`
- `loop-component-lineage-<tier>.json` and matching `.sha256`
- `branching-event-log-<tier>.json` and matching `.sha256`

## Rollback Instructions

1. Remove the generated deployment manifest and evidence artifacts from the designated `artifacts/` path.
2. Disable or delete any manually created Power Automate flow.
3. Revoke the app secret or certificate assignment if the inventory identity is no longer required.
4. Archive prior evidence exports according to the customer retention policy before deleting current working files.
