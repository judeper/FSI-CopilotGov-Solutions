# Prerequisites

## Licensing

- Power Apps Premium
  - One licensing option for a Dataverse-backed supervisory app, not the exclusive entitlement for custom-table creation.
- Power Automate Premium
  - One licensing option for standalone cloud flows using premium connectors such as Dataverse. Confirm app-context flow rights and existing qualifying entitlements before assigning both licenses to every participant.
- Microsoft Purview Suite (formerly Microsoft 365 E5 Compliance), Office 365 Enterprise E5, or Office 365 Enterprise E3 with the Advanced Compliance add-on
  - Required for users covered by Microsoft Purview Communication Compliance policies that target Copilot prompts and responses.

Licensing is separate from authorization. Microsoft documents custom-table rights
under qualifying Dynamics 365, Power Apps, or Power Automate licenses. See
[License requirements for tables](https://learn.microsoft.com/power-apps/maker/data-platform/data-platform-entity-licenses)
and [Premium connectors](https://learn.microsoft.com/connectors/connector-reference/connector-reference-premium-connectors).
The Communication Compliance SKU examples remain current per
[Plan for Communication Compliance](https://learn.microsoft.com/purview/communication-compliance-plan).

## Roles

- Power Platform administrator
  - Coordinates environment administration; verify the operator's actual Dataverse customization and data privileges rather than assuming the tenant role grants all table access.
- System Customizer and the required Entity table Create, Read, and Write privileges
  - Required for the table-creation path described in [Create and edit tables using Power Apps](https://learn.microsoft.com/power-apps/maker/data-platform/create-edit-entities-portal). Schema creation rights and queue/log data access are separate.
- Communication Compliance Admins role group or approved Compliance Administrator role/role group
  - Configures and validates Microsoft Purview Communication Compliance policies and reviewer scope using least privilege.
- Global Reader
  - Provides supported read-only tenant configuration checks only; it does not replace Communication Compliance investigation roles or Dataverse table privileges.
- Communication Compliance, Communication Compliance Analysts, or Communication Compliance Investigators role group
  - Required for investigating Copilot interactions; reviewers must also be assigned to the relevant policy. Policy administration alone is not proof of access to individual flagged communications.

See [Communication Compliance permissions](https://learn.microsoft.com/purview/communication-compliance-permissions)
and [Copilot interaction prerequisites](https://learn.microsoft.com/purview/communication-compliance-copilot#prerequisites).

## Microsoft Entra ID and identity prerequisites

- Microsoft Entra ID groups for Zone1, Zone2, and Zone3 supervisory principals.
- Microsoft Entra ID group for escalation recipients.
- Microsoft Entra ID application or managed identity for any automation that performs live evidence export.
- Admin consent for the chosen application permissions.

## PowerShell and workstation requirements

- PowerShell 7 or later.
- Network access to the Power Platform environment URL.
- Ability to import repository shared modules from `scripts\common`.

## Optional Graph API permissions

The repository's `-LiveExport` path reads Dataverse; it does not call Microsoft
Graph or query Communication Compliance matches. The permissions below apply only
to a separately implemented, customer-approved audit-log handoff.

Use the least privilege model approved by your security team. For Microsoft Graph Audit Search API scenarios such as `/security/auditLog/queries`, use `AuditLogsQuery-*` permissions that match the service data required for the workflow:

- `AuditLogsQuery-Entra.Read.All` where Entra audit data is sufficient.
- Service-specific permissions such as `AuditLogsQuery-Exchange.Read.All`, `AuditLogsQuery-OneDrive.Read.All`, or `AuditLogsQuery-SharePoint.Read.All` where those audit workloads are approved.
- `AuditLogsQuery.Read.All` only where broad Audit Search query coverage is approved.
- `User.Read.All` only where separate user-profile lookup requires that scope. For group membership, choose permissions for the specific group endpoint; do not assume `User.Read.All` authorizes group enumeration.

See [List auditLogQueries](https://learn.microsoft.com/graph/api/security-auditcoreroot-list-auditlogqueries?view=graph-rest-1.0)
and [List group members](https://learn.microsoft.com/graph/api/group-list-members?view=graph-rest-1.0#permissions).

Do not substitute `AuditLog.Read.All` or `Policy.Read.All` for Microsoft Graph Audit Search API queries. If your firm uses delegated access instead of application permissions, document the reviewer and admin accounts approved for export and monitoring tasks.

## Dataverse connection requirements

- Dataverse environment with tables enabled.
- Connection reference named `fsi_cr_fsw_dataverse`.
- Environment variable `fsi_ev_fsw_environmenturl` pointing to the target environment URL.
- Service identity with read access for evidence export and the table-specific privileges required by each flow. Queue updates do not justify log Write/Delete access; log creation needs the approved Create/Read and relationship privileges only.

## Communication Compliance handoff requirements

- Microsoft Purview Communication Compliance policy scoped to Copilot prompt and response activity.
- Confirm supported applications/item classes and explicitly select the relevant AI-app locations in the policy. Coverage varies by surface; non-Microsoft-365 AI data and Copilot Studio agents published to non-Microsoft channels require applicable pay-as-you-go billing. See [Configure generative AI detection](https://learn.microsoft.com/purview/communication-compliance-copilot).
- Customer-validated handoff pattern, such as a Communication Compliance report export, audit-log review, or Power Automate flow launched from a Communication Compliance alert.
- For alert-context flows, use **Automate > Manage Power Automate flows** inside an alert with the required Communication Compliance role-group access. This repository provides no scheduled policy-match collector; this boundary is not a claim that Microsoft prohibits every custom polling implementation. See [Use Power Automate with Communication Compliance](https://learn.microsoft.com/purview/communication-compliance-power-automate).
- Validate the actual handoff payload and map available identifiers/metadata to the queue schema; an alert or audit record is not proof that full prompt/response content is exported.
- Connection reference named `fsi_cr_fsw_handoff` only when the validated handoff source requires one.
- Environment variable `fsi_ev_fsw_purviewpolicyid` populated with the approved policy identifier for traceability.
