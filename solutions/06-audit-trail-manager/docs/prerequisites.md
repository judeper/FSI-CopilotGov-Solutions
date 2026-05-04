# Prerequisites

## Licensing

- Microsoft 365 E5, Microsoft Purview Suite (formerly Microsoft 365 E5 Compliance), or Microsoft 365 E5 eDiscovery and Audit add-on for Microsoft Purview Audit, retention, and Microsoft Purview eDiscovery capabilities.
- Power BI Pro for dashboard publication, sharing, and refresh management.

## Roles

The deployment team should have the following roles assigned as appropriate:

- Compliance Administrator
- eDiscovery Manager
- Audit Reader
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

- `AuditLogsQuery.Read.All` or the least-privileged service-specific `AuditLogsQuery-*` permission for the selected workload
- Document records-management permissions separately only if tenant-specific retention automation is later implemented

## Tenant requirements

- Unified Audit Log must be enabled in the tenant.
- Purview retention policies and label publishing must be available.
- Microsoft Purview eDiscovery case management must be enabled for the target compliance team.
- Power BI workspace access and refresh credentials must be available for the dashboard owner.
- Power Automate connections must be approved for alert delivery.
