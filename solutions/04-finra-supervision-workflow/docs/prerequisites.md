# Prerequisites

## Licensing

- Power Apps Premium
  - Required for Dataverse table creation and table-based applications.
- Power Automate Premium
  - Required for cloud flows that connect to Dataverse and compliance data sources.
- Microsoft 365 E5 Compliance
  - Required for Microsoft Purview Communication Compliance policies that target Copilot prompts and responses.

## Roles

- Power Platform Admin
  - Creates or approves the Dataverse environment, tables, and connection references.
- Purview Compliance Admin
  - Configures and validates Microsoft Purview Communication Compliance policies and reviewer scope.
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

Use the least privilege model approved by your security team. Typical permissions for metadata and reviewer resolution scenarios are:

- `Policy.Read.All`
- `AuditLog.Read.All`
- `User.Read.All`

If your firm uses delegated access instead of application permissions, document the reviewer and admin accounts approved for export and monitoring tasks.

## Dataverse connection requirements

- Dataverse environment with tables enabled.
- Connection reference named `fsi_cr_fsw_dataverse`.
- Environment variable `fsi_ev_fsw_environmenturl` pointing to the target environment URL.
- Service principal or admin account with read access for evidence export and read-write access for flow execution.

## Purview connection requirements

- Microsoft Purview Communication Compliance policy scoped to Copilot prompt and response activity.
- Connection reference named `fsi_cr_fsw_purview`.
- Environment variable `fsi_ev_fsw_purviewpolicyid` populated with the approved policy identifier.

