# Prerequisites

## Platform and Licensing

- SharePoint Advanced Management feature entitlement for the intended production posture requires an eligible base license plus either a Microsoft 365 Copilot license assigned to at least one user in the organization or a standalone Microsoft SharePoint Advanced Management license. If neither entitlement path is available, document the limitation before enabling this solution.
- Microsoft Purview Data Security Posture Management (DSPM) prerequisites should be validated for the selected scenarios, including appropriate permissions, Microsoft Purview auditing, Microsoft 365 Copilot user licensing for Copilot and agents, and any Edge, device onboarding, browser extension, or pay-as-you-go billing requirements that apply.
- The target tenant should already have a defined Copilot pilot or rollout scope so findings can be prioritized against real exposure risk.

## Required Administrative Roles

At least one of the following roles should be assigned to the operator, depending on the task being performed:

- SharePoint Admin
- Compliance Admin
- Global Admin

For Teams-specific governance review, an approved Teams administrator or collaboration governance contact is recommended even though the core script uses site-backed exposure logic.

## Required PowerShell Modules

Install and approve the following modules on the execution host:

- `PnP.PowerShell`
- `Microsoft.Graph`
- `ExchangeOnlineManagement`

Example installation command:

```powershell
Install-Module PnP.PowerShell, Microsoft.Graph, ExchangeOnlineManagement -Scope CurrentUser
```

> **PnP.PowerShell v3.x note:** PnP.PowerShell 3.x requires PowerShell 7.4 or later and .NET 8.0. Organizations must register their own Microsoft Entra ID application (the multi-tenant PnP app was removed in September 2024). Azure Automation environments are limited to PnP.PowerShell 2.12.0 (PowerShell 7.2 only).

## Power Automate Environment

Power Automate is documentation-first in this solution version. A managed Power Automate environment should still be identified in advance so the documented `SiteOwnerNotification` and `RemediationApproval` flows can be implemented without redesigning routing, approvals, or connectors later.

## Upstream Dependency

Solution 01-copilot-readiness-scanner must complete a baseline scan before solution 02 is deployed. The output should be available under the upstream artifact path so this solution can validate the dependency and target the most relevant sites first.

## Shared Repository Modules

The `Export-Evidence.ps1` and `Monitor-Compliance.ps1` scripts optionally import shared modules from the parent repository (`scripts/common/`):

- `EvidenceExport.psm1` — provides `Write-CopilotGovSha256File`, `Get-CopilotGovEvidenceSchemaVersion`, and `Test-CopilotGovEvidencePackage`
- `IntegrationConfig.psm1` — provides cross-solution integration configuration helpers
- `GraphAuth.psm1` — provides `Connect-CopilotGovGraph` and `Invoke-CopilotGovGraphRequest`

When these modules are not present (e.g., standalone or documentation-first usage), the scripts fall back to local implementations or sample data. For production deployments with live Graph API access and evidence packaging, ensure the parent repository's `scripts/common/` directory is available at the expected relative path (`../../scripts/common/` from the `scripts/` directory).

## Network and Service Access

The execution environment must be able to reach:

- SharePoint REST API endpoints
- Microsoft Graph API endpoints, including approval for driveItem `extractSensitivityLabels` permissions such as `Files.Read.All` or `Sites.Read.All` when item-level label extraction is enabled
- Tenant admin endpoints needed for sharing and search configuration review

If the environment uses proxy inspection or outbound restrictions, test API connectivity before the initial scan window.

## Operational Readiness

- Confirm evidence output storage exists and is approved for regulated records.
- Confirm site owner notification content has been reviewed by legal, compliance, and communications stakeholders if notifications will be enabled.
- Confirm scan windows and throttling expectations have been approved for large SharePoint or OneDrive inventories.
