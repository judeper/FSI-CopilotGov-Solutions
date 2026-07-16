# Prerequisites

## Platform and Licensing

- SharePoint Advanced Management feature entitlement requires an eligible Microsoft 365
  or Office 365 base subscription (for example, Microsoft 365 E1/E3/E5/A5/E7 or
  Office 365 E3/E5) plus one documented entitlement path: Microsoft 365 Copilot,
  SharePoint Advanced Management Plan 1 add-on, or Microsoft 365 E7 where the current
  Microsoft Learn prerequisites guidance applies. If no supported path is available,
  document the limitation before enabling this solution.
- Microsoft Purview Data Security Posture Management (DSPM) prerequisites should be validated for the selected scenarios, including appropriate permissions, Microsoft Purview auditing, Microsoft 365 Copilot user licensing for Copilot and agents, and any Edge, device onboarding, browser extension, or pay-as-you-go billing requirements that apply.
- The target tenant should already have a defined Copilot pilot or rollout scope so findings can be prioritized against real exposure risk.

## Discoverability Control Prerequisites

- Treat Restricted SharePoint Search (RSS) as legacy transition guidance only. Microsoft Learn states RSS is retiring and new enablement is blocked starting 2026-07-31.
- Use Restricted Content Discovery (RCD) as the go-forward discoverability control. RCD is configured per SharePoint site, does not change permissions, and is SharePoint-only (not OneDrive).
- RCD planning in this solution assumes Copilot plus SharePoint Advanced Management prerequisites are met and that Microsoft Purview audit logging is enabled for traceability.

## Required Administrative Roles

At least one of the following roles should be assigned to the operator, depending on the task being performed:

- SharePoint Administrator
- SharePoint Advanced Management Administrator
- Compliance Administrator (for Purview/DSPM tasks)
- Global Admin

For Restricted Content Discovery operations, SharePoint Administrator is the default role and delegated site-admin management should be approved when used.

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

> **PnP.PowerShell runtime note (project-documented; validate in your lab):** This repository documents a PowerShell 7.4+ execution posture and customer-owned Microsoft Entra app registration patterns for PnP usage. Confirm exact module/runtime behavior in your tenant lab before production rollout because this solution does not treat host-specific PnP runtime combinations as independently verified Microsoft source claims.

## Power Automate Environment

Power Automate is documentation-first in this solution version. A managed Power Automate environment should still be identified in advance so the documented `SiteOwnerNotification` and `RemediationApproval` flows can be implemented without redesigning routing, approvals, or connectors later.

## Upstream Dependency

Solution 01-copilot-readiness-scanner must complete a baseline scan before solution 02 is deployed. The output should be available under the upstream artifact path so this solution can validate the dependency and target the most relevant sites first.

## Shared Repository Modules

The `Export-Evidence.ps1` and `Monitor-Compliance.ps1` scripts optionally import shared modules from the parent repository (`scripts/common/`):

- `EvidenceExport.psm1` — provides `Write-CopilotGovSha256File`, `Get-CopilotGovEvidenceSchemaVersion`, and `Test-CopilotGovEvidencePackage`
- `IntegrationConfig.psm1` — provides cross-solution integration configuration helpers
- `GraphAuth.psm1` — provides `Connect-CopilotGovGraph` and `Invoke-CopilotGovGraphRequest`

When these modules are not present (e.g., standalone or documentation-first usage), the scripts fall back to local implementations or sample data. For production deployments with live Graph API access and evidence packaging, confirm the parent repository's `scripts/common/` directory is available at the expected relative path (`../../scripts/common/` from the `scripts/` directory).

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
