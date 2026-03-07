# Prerequisites

## Platform and Licensing

- SharePoint Advanced Management licensing is required for the intended production posture. If licensing is not available, document the limitation before enabling this solution.
- Microsoft 365 E5 Compliance, or an equivalent licensing combination that enables DSPM for AI investigations, should be available for the tenant.
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

## Power Automate Environment

Power Automate is documentation-first in this solution version. A managed Power Automate environment should still be identified in advance so the documented `SiteOwnerNotification` and `RemediationApproval` flows can be implemented without redesigning routing, approvals, or connectors later.

## Upstream Dependency

Solution 01-copilot-readiness-scanner must complete a baseline scan before solution 02 is deployed. The output should be available under the upstream artifact path so this solution can validate the dependency and target the most relevant sites first.

## Network and Service Access

The execution environment must be able to reach:

- SharePoint REST API endpoints
- Microsoft Graph API endpoints
- Tenant admin endpoints needed for sharing and search configuration review

If the environment uses proxy inspection or outbound restrictions, test API connectivity before the initial scan window.

## Operational Readiness

- Confirm evidence output storage exists and is approved for regulated records.
- Confirm site owner notification content has been reviewed by legal, compliance, and communications stakeholders if notifications will be enabled.
- Confirm scan windows and throttling expectations have been approved for large SharePoint or OneDrive inventories.
