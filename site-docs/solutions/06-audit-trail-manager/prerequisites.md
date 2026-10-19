# Prerequisites

## Licensing

- An eligible subscription for Audit (Standard); Microsoft-developed Copilot activity auditing does not itself require Audit (Premium).
- Microsoft 365 E5 or an eligible base subscription with Microsoft Purview Suite (formerly Microsoft 365 E5 Compliance) or Microsoft 365 E5 eDiscovery and Audit add-on for Audit (Premium) and premium eDiscovery features. Assign the appropriate licenses to users whose activities/data benefit from those features.
- Validate retention policy, auto-apply cloud-attachment label, and records-management entitlements independently in the [Microsoft Purview service description](https://learn.microsoft.com/office365/servicedescriptions/microsoft-365-service-descriptions/microsoft-365-tenantlevel-services-licensing-guidance/microsoft-purview-service-description). The eDiscovery and Audit add-on does not license every retention feature.
- Power BI Pro or Premium Per User for publishing/sharing in shared workspaces. Reader requirements depend on the workspace's capacity and license type; see [Power BI licensing](https://learn.microsoft.com/power-bi/fundamentals/service-features-license-type).
- If scope expands to non-Microsoft AI apps, verify collection/onboarding and pay-as-you-go billing separately against [Copilot and AI audit guidance](https://learn.microsoft.com/purview/audit-copilot).

## Roles

The deployment team should have the following roles assigned as appropriate:

- Audit Reader for portal audit search/export; Audit Manager when audit administration is required. Exchange Online audit cmdlets additionally require the corresponding Exchange admin center Audit Logs or View-Only Audit Logs roles.
- eDiscovery Manager and access to the target case for searches, holds, and exports. Compliance Administrator or Global Reader alone is not a substitute for case/search/export access.
- Retention administration permissions appropriate to the policy operation. Do not assign all listed roles to every operator.

See [audit permissions](https://learn.microsoft.com/purview/audit-get-started) and [eDiscovery permissions](https://learn.microsoft.com/purview/edisc-permissions).

## PowerShell runtime

Local scaffold scripts declare PowerShell 7.0 or later and do not require service connections. For optional tenant administration, match the runtime, operating system, and installed module version to the [Exchange Online support matrix](https://learn.microsoft.com/powershell/exchange/exchange-online-powershell-v2): on supported Windows systems, ExchangeOnlineManagement 3.10.0+ requires PowerShell 7.6.0+, while 3.5.0-3.9.2 requires PowerShell 7.4.0+. The script minimum is not a compatibility promise for the latest module.

## PowerShell modules

These modules are for separately implemented tenant workflows, not local JSON generation:

- `ExchangeOnlineManagement`
- `Microsoft.Graph`

Example:

```powershell
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module Microsoft.Graph -Scope CurrentUser
```

## Graph permissions

Only approve permissions for a separately implemented tenant collection workflow; repository scripts do not call Graph.

- `AuditLogsQuery.Read.All` for Copilot audit queries. Named scopes such as `AuditLogsQuery-SharePoint.Read.All` cover only that workload, not arbitrary Copilot queries. Review delegated/application consent separately against the [Audit Search API permission table](https://learn.microsoft.com/graph/api/security-auditcoreroot-post-auditlogqueries?view=graph-rest-1.0).
- Document records-management permissions separately only if tenant-specific retention automation is later implemented

## Tenant requirements

- Unified Audit Log must be enabled in the tenant.
- Purview retention policies for **Microsoft Copilot experiences** must be available for new prompt/response policies; label publishing targets supported files/records separately.
- Microsoft Purview eDiscovery case management must be enabled for the target compliance team.
- Power BI workspace access and refresh credentials must be available for the dashboard owner.
- Power Automate connections must be approved for alert delivery.
