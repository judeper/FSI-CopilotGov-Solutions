# Prerequisites

## Platform and Licensing

- Entra ID Governance P2 licensing is required for access review creation and management. If licensing is not available, document the limitation before enabling this solution.
- Microsoft 365 E5 Compliance, or an equivalent licensing combination that enables access review features, should be available for the tenant.
- The target tenant should already have a defined Copilot pilot or rollout scope so access reviews can be prioritized against real exposure risk.

## Required Administrative Roles

At least one of the following roles should be assigned to the operator, depending on the task being performed:

- Global Admin
- Identity Governance Admin
- User Admin
- SharePoint Admin (for resolving site owner information)

For access review creation and management, Identity Governance Admin is the recommended least-privilege role.

## Required Microsoft Graph Permissions

The following application permissions are required for the registered app:

- `AccessReview.ReadWrite.All`
- `Sites.Read.All`
- `User.Read.All`
- `GroupMember.Read.All`

## Required PowerShell Modules

Install and approve the following modules on the execution host:

- `Microsoft.Graph`
- `PnP.PowerShell`

Example installation command:

```powershell
Install-Module Microsoft.Graph, PnP.PowerShell -Scope CurrentUser
```

## Upstream Dependency

Solution 02-oversharing-risk-assessment must complete a risk-scored scan before solution 18 is deployed. The output should be available under the upstream artifact path so this solution can validate the dependency and target the highest-risk sites first.

## Network and Service Access

The execution environment must be able to reach:

- Microsoft Graph API endpoints (`https://graph.microsoft.com`)
- Entra ID authentication endpoints (`https://login.microsoftonline.com`)
- SharePoint REST API endpoints (for site owner resolution)

If the environment uses proxy inspection or outbound restrictions, test API connectivity before the initial deployment window.

## Operational Readiness

- Confirm evidence output storage exists and is approved for regulated records.
- Confirm site owner information is accurate and current in SharePoint site properties.
- Confirm reviewer notification content has been reviewed by legal, compliance, and communications stakeholders.
- Confirm review cadence expectations have been approved for the selected governance tier.
