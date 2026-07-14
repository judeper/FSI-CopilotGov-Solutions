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
- Communication Compliance Analysts role group (least-privileged reviewer)
  - Accesses and investigates Communication Compliance alerts and policy matches for the policies where the user is named as a reviewer, without configuring policies or taking advanced remediation actions. Reviewers must also be added to the Reviewers field of the Communication Compliance policy.
- Communication Compliance Investigators role group
  - Required only when the validated handoff uses advanced remediation actions such as escalation for investigation, item download, or running Communication Compliance Power Automate flows.
- Communication Compliance Viewers role group
  - Provides read-only access to Communication Compliance reports for oversight without alert investigation.
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
- Before live evidence export, confirm each Dataverse table's `EntitySetName` from tenant metadata (for example, `GET {environmentUrl}/api/data/v9.2/EntityDefinitions(LogicalName='fsi_cg_fsw_queue')?$select=EntitySetName`) and align the `entitySetName` values in `config\default-config.json`. Microsoft guidance is to read the Web API entity set name from metadata rather than assuming the default plural collection name.

## Communication Compliance handoff requirements

- Microsoft Purview Communication Compliance policy created from the **Detect Microsoft Copilot interactions** template (or an equivalent custom policy) that includes the **Microsoft Copilot experiences** location so it captures Microsoft 365 Copilot and Microsoft 365 Copilot Chat prompts and responses.
  - Detecting Microsoft 365 Copilot data does not require pay-as-you-go billing. Adding the **Enterprise AI apps** or **Other AI apps** locations for non-Microsoft 365 AI activity requires pay-as-you-go billing to be enabled in Microsoft Purview.
- Customer-validated handoff pattern, such as a Communication Compliance report export, audit-log review, or a Power Automate flow created from a recommended default template through the **Automate** menu on a Communication Compliance alert.
  - Creating or running Communication Compliance Power Automate flows requires membership in a Communication Compliance role group (for example, Communication Compliance or Communication Compliance Investigators).
- Connection reference named `fsi_cr_fsw_handoff` only when the validated handoff source requires one.
- Environment variable `fsi_ev_fsw_purviewpolicyid` populated with the approved policy identifier for traceability.

