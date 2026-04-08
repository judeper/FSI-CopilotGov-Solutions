# Deployment Guide

## Prerequisites

Review [docs/prerequisites.md](prerequisites.md) before deployment. The deployment script assumes Microsoft 365 service-health access, an Entra ID application registration, PowerShell 7.2 or later, and access to the shared modules under `scripts/common/`.

## Step 1: Clone and Configure

1. Clone the repository and move to the DRM solution directory.
2. Set environment variables for the tenant and application identity.
3. Handle the client secret through a secure input method or an approved secret-management platform.

```powershell
git clone https://github.com/judeper/FSI-CopilotGov-Solutions.git
Set-Location C:\Dev\FSI-CopilotGov-Solutions\13-dora-resilience-monitor
$env:AZURE_TENANT_ID = '<tenant-guid>'
$env:AZURE_CLIENT_ID = '<app-registration-guid>'
$clientSecret = Read-Host 'Enter client secret' -AsSecureString
```

Recommended secret-handling options:

- PowerShell SecretManagement or a managed vault
- Certificate-based authentication where permitted by the customer security team
- Just-in-time retrieval of secrets during deployment rather than persistent shell storage

## Step 2: Select Governance Tier and Review Configuration

Choose the governance tier that matches the operating model and review `config/<tier-name>.json` together with `config/default-config.json`.

- `baseline`: hourly monitoring and summary alerting
- `recommended`: 15-minute polling, incident register creation, and resilience-test reminders
- `regulated`: 5-minute polling, DORA-oriented reporting thresholds, Sentinel integration settings, and evidence immutability options

Confirm the following before deployment:

- Monitored service list is correct for the tenant
- Notification channel matches the target operating team
- Retention values match policy
- Sentinel and immutable storage environment variables are available where required

## Step 3: Run Deploy-Solution.ps1 with -ConfigurationTier and -WhatIf First

Run the deployment script in preview mode to validate configuration and manifest content before creating artifacts.

```powershell
.\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId $env:AZURE_TENANT_ID -OutputPath .\artifacts -WhatIf -Verbose
```

If the preview is acceptable, rerun without `-WhatIf`.

```powershell
.\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId $env:AZURE_TENANT_ID -OutputPath .\artifacts -Verbose
```

## Step 4: Verify Deployment Manifest in artifacts/

After deployment, confirm that the manifest is present in `artifacts/` and review:

- Selected tier and polling interval
- Monitored services list
- Severity thresholds
- Dataverse table names and connection references
- Dependency on 12-regulatory-compliance-dashboard

## Step 5: Run Initial Monitor-Compliance.ps1 to Baseline Service Health

Capture the initial service-health baseline and resilience-test state.

```powershell
.\scripts\Monitor-Compliance.ps1 -ConfigurationTier recommended -OutputPath .\artifacts -TenantId $env:AZURE_TENANT_ID -ClientId $env:AZURE_CLIENT_ID -ClientSecret $clientSecret -Verbose
```

Review the output for:

- Health entries for all monitored services
- Any open incidents classified as major, significant, or minor
- Resilience-test due status
- Overall status for dashboard consumption

## Step 6: Configure Power Automate Flow

This solution uses a documentation-first pattern for Power Automate.

1. Create a scheduled cloud flow that runs at the interval defined by the selected tier.
2. Read the monitoring snapshot or invoke the monitoring script through an approved automation host.
3. Route major or significant incidents to the operations, resilience, and compliance distribution lists.
4. Optionally write follow-up tasks or service tickets for incident register enrichment and root-cause analysis.
5. If using Sentinel, add a branch that enriches the alert context with workspace data.

The repository does not deploy the flow automatically. Manual implementation and approval are required in the target tenant.

## Step 7: Run Export-Evidence.ps1 and Verify .sha256

Export the evidence package after the initial baseline is captured.

```powershell
.\scripts\Export-Evidence.ps1 -ConfigurationTier recommended -OutputPath .\artifacts -Verbose
```

Verify the following files exist:

- `service-health-log-<tier>.json`
- `incident-register-<tier>.json`
- `resilience-test-results-<tier>.json`
- `13-dora-resilience-monitor-evidence.json`
- Matching `.sha256` files for each JSON artifact

## Rollback Instructions

If the deployment needs to be rolled back:

1. Remove the generated deployment manifest and monitoring artifacts from the designated `artifacts/` path.
2. Disable or delete the manually created Power Automate flow.
3. Revoke the app secret or certificate assignment if the monitoring identity is no longer required.
4. Remove any downstream dashboard ingestion references in 12-regulatory-compliance-dashboard.
5. Archive prior evidence exports according to the customer retention policy before deleting current working files.

## Dependencies on 12-regulatory-compliance-dashboard

DRM produces operational-risk data that can be consumed by solution 12-regulatory-compliance-dashboard. Deploy solution 12 first when a centralized reporting surface is required, then point the dashboard ingestion process to the DRM evidence output path. If solution 12 is not deployed, DRM still operates as a standalone monitoring and evidence solution.
