# Prerequisites

## Licensing

- Power Apps Premium
  - Required for Dataverse table creation and table-based applications.
- Power Automate Premium
  - Required for cloud flows that connect to Dataverse and compliance data sources.
- Microsoft Purview Suite (formerly Microsoft 365 E5 Compliance), Office 365 Enterprise E5, or Office 365 Enterprise E3 with the Advanced Compliance add-on
  - Required for users covered by Microsoft Purview Communication Compliance policies that target Copilot prompts and responses.

## Roles

- Power Platform administrator
  - Creates or approves the Dataverse environment, tables, and connection references.
- Communication Compliance Admins role group or approved Compliance Administrator role/role group
  - Configures and validates Microsoft Purview Communication Compliance policies and reviewer scope using least privilege.
- Global Reader
  - Provides read-only verification of tenant-wide configuration and service readiness.

## Microsoft Entra ID and identity prerequisites

- Microsoft Entra ID groups for Zone1, Zone2, and Zone3 supervisory principals.
- Microsoft Entra ID group for escalation recipients.
- Microsoft Entra ID application or managed identity for any automation that performs live evidence export.
- Admin consent for the chosen application permissions.

## PowerShell and workstation requirements

- PowerShell 7 or later.
- Network access to the Power Platform environment URL.
- Ability to import repository shared modules from `scripts\common`.

## Graph API permissions

Use the least privilege model approved by your security team. For Microsoft Graph Audit Search API scenarios such as `/security/auditLog/queries`, use `AuditLogsQuery-*` permissions that match the service data required for the workflow:

- `AuditLogsQuery-Entra.Read.All` where Entra audit data is sufficient.
- Service-specific permissions such as `AuditLogsQuery-Exchange.Read.All`, `AuditLogsQuery-OneDrive.Read.All`, or `AuditLogsQuery-SharePoint.Read.All` where those audit workloads are approved.
- `AuditLogsQuery.Read.All` only where broad Audit Search query coverage is approved.
- `User.Read.All` only where separate user or group lookup is required.

Do not substitute `AuditLog.Read.All` or `Policy.Read.All` for Microsoft Graph Audit Search API queries. If your firm uses delegated access instead of application permissions, document the reviewer and admin accounts approved for export and monitoring tasks.

## Dataverse connection requirements

- Dataverse environment with tables enabled.
- Connection reference named `fsi_cr_fsw_dataverse`.
- Environment variable `fsi_ev_fsw_environmenturl` pointing to the target environment URL.
- Service principal or admin account with read access for evidence export and read-write access for flow execution.

## Communication Compliance handoff requirements

- Microsoft Purview Communication Compliance policy scoped to Copilot prompt and response activity.
- Customer-validated handoff pattern, such as a Communication Compliance report export, audit-log review, or Power Automate flow launched from a Communication Compliance alert.
- Connection reference named `fsi_cr_fsw_handoff` only when the validated handoff source requires one.
- Environment variable `fsi_ev_fsw_purviewpolicyid` populated with the approved policy identifier for traceability.

