# Prerequisites

## Platform and Licensing

- Microsoft Entra ID Governance or Microsoft Entra Suite subscriptions are required for many access review capabilities. If licensing is not available, document the limitation before enabling this solution.
- For application or group access review scenarios where Microsoft Learn lists additional options, validate Microsoft Entra ID P2 or Enterprise Mobility + Security (EMS) E5 coverage as applicable.
- The target tenant should already have a defined Copilot pilot or rollout scope so access reviews can be prioritized against real exposure risk.

## Required Administrative Roles

At least one of the following roles should be assigned to the operator, depending on the task being performed:

- Global Administrator (break-glass use)
- Identity Governance Administrator
- User Administrator
- Privileged Role Administrator (for role-assignable groups or role reviews)
- SharePoint Administrator (for resolving site owner information and group-to-site mappings)

For access review creation and management of groups or applications, User Administrator or Identity Governance Administrator is the recommended least-privilege role.

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
- Microsoft Entra ID authentication endpoints (`https://login.microsoftonline.com`)
- SharePoint REST API endpoints (for site owner resolution)

If the environment uses proxy inspection or outbound restrictions, test API connectivity before the initial deployment window.

## Operational Readiness

- Confirm evidence output storage exists and is approved for regulated records.
- Confirm site owner information is accurate and current in SharePoint site properties.
- Confirm reviewer notification content has been reviewed by legal, compliance, and communications stakeholders.
- Confirm review cadence expectations have been approved for the selected governance tier.
