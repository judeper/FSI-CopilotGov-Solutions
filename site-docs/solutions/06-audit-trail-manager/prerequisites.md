# Prerequisites

## Licensing

- Microsoft 365 E5 or Microsoft 365 E5 Compliance for Microsoft Purview Audit, retention, and eDiscovery capabilities.
- Power BI Pro for dashboard publication, sharing, and refresh management.

## Roles

The deployment team should have the following roles assigned as appropriate:

- Compliance Administrator
- eDiscovery Manager
- Audit Log Reader
- Global Reader

## PowerShell modules

Install or update these modules before running the scripts:

- `ExchangeOnlineManagement`
- `Microsoft.Graph`

Example:

```powershell
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module Microsoft.Graph -Scope CurrentUser
```

## Graph permissions

Approve and document the following permissions for the service principal or delegated workflow used by the solution:

- `AuditLog.Read.All`
- `RecordsManagement.Read.All`

## Tenant requirements

- Unified Audit Log must be enabled in the tenant.
- Purview retention policies and label publishing must be available.
- Purview eDiscovery case management must be enabled for the target compliance team.
- Power BI workspace access and refresh credentials must be available for the dashboard owner.
- Power Automate connections must be approved for alert delivery.
