# Prerequisites

## Licensing

- Confirm the feature-specific entitlement in the [Microsoft Purview service description](https://learn.microsoft.com/office365/servicedescriptions/microsoft-365-service-descriptions/microsoft-365-tenantlevel-services-licensing-guidance/microsoft-purview-service-description); manual labeling and automatic labeling have different requirements.
- Client- and service-side automatic labeling examples include Microsoft 365 E5, Office 365 E5, Microsoft Purview Suite, and Microsoft 365 E5 Information Protection and Governance. Confirm the exact plan and add-on prerequisites rather than inferring eligibility from a generic P2 designation; the service description lists Enterprise Mobility + Security E5 for client-side automatic labeling only.
- Assign the required Standard/Plan 1 service plan as well as the applicable Premium/Plan 2 plan. License each benefiting user, including relevant administrators, mailbox/OneDrive users, and owners or members of shared locations, as described in the service description.

Baseline monitoring can begin before enforcement use cases are approved, but bulk labeling and advanced policy scenarios should not proceed until licensing is confirmed for the users, shared locations, and services that benefit from the Purview features.

## Required Roles

Deployment and evidence operators should use the least-privileged Microsoft Purview role group or role that matches their task:

- Information Protection
- Information Protection Admins
- Information Protection Analysts
- Information Protection Investigators
- Information Protection Readers
- Sensitivity Label Administrator for label management tasks
- Sensitivity Label Reader for read-only label review
- Compliance Administrator or Security Administrator only when the role assignment has been approved for broader compliance operations

Organizations may split duties between deployment, records, and audit teams. Reserve Global Administrator for break-glass role assignment rather than day-to-day operation.

## Graph API Permissions

The monitoring design assumes approved access to the following Microsoft Graph permissions or tenant-approved export patterns:

| Surface | Delegated permission | Application permission | Notes |
|---------|----------------------|------------------------|-------|
| Sensitivity label definitions | `InformationProtectionPolicy.Read` | `InformationProtectionPolicy.Read.All` | Delegated lookup uses beta `/me/security/informationProtection/sensitivityLabels`; organization lookup uses beta `/security/informationProtection/sensitivityLabels` with application permissions. Microsoft does not support beta APIs in production applications. |
| SharePoint and OneDrive label extraction | `Files.Read.All` | `Files.Read.All` | Least-privileged permission for `driveItem: extractSensitivityLabels`; higher permissions such as `Sites.Read.All` should be used only when the tenant-approved design requires them. |
| Approved bulk label assignment extensions | `Files.ReadWrite.All` | `Files.ReadWrite.All` | `assignSensitivityLabel` is a protected SharePoint and OneDrive API; `Sites.ReadWrite.All` is the higher-privileged alternative when justified. |
| Exchange labeling evidence | `Mail.Read` or approved Purview export access | `Mail.Read` or approved Purview export access | Microsoft Graph message resources do not expose a first-class sensitivity-label field, so Exchange coverage requires a documented tenant source such as audit/activity exports, Internet message headers, or extended properties. |

Additional permissions may be needed if the organization extends the solution to workflow automation, but the implementation should use least-privileged permissions and document each approval.

See [List sensitivityLabels](https://learn.microsoft.com/graph/api/security-informationprotection-list-sensitivitylabels?view=graph-rest-beta)
for the route/permission split and beta warning. For approved assignment extensions,
complete protected-API validation and [metered API setup](https://learn.microsoft.com/graph/metered-api-setup)
separately from Graph consent; this remains a prerequisite documented by the
[assignment action](https://learn.microsoft.com/graph/api/driveitem-assignsensitivitylabel?view=graph-rest-1.0).
Assignment is not part of the monitoring scaffold.

## PowerShell and Modules

- PowerShell 7.x
- `Microsoft.Graph`
- `ExchangeOnlineManagement`

The scripts are written as implementation-ready stubs and can be extended with tenant-approved authentication and Graph request logic.

## Upstream Solution Dependencies

The following solutions must be complete before solution 03 is considered ready for production monitoring:

- `01-copilot-readiness-scanner` completed
- `02-oversharing-risk-assessment` initial scan completed

Solution 01 provides rollout and workload context. Solution 02 provides oversharing findings that help prioritize unlabeled content in regulated stores.

## Governance and Taxonomy

- Review the configured taxonomy in the Microsoft Purview portal at **Solutions > Information Protection > Sensitivity labels**. Use **Sensitivity Label Reader** or an appropriate Information Protection Readers role group for read-only label review; label-reading access does not grant file or email content access.
- Observe the classic/modern label scheme and group membership without starting a migration. [Label-group migration](https://learn.microsoft.com/purview/migrate-sensitivity-label-scheme) is irreversible and availability is tenant-dependent.
- The organization should confirm the FSI label hierarchy and expected business mappings before scanning begins.
- Priority sites, supervisory mailboxes, and regulated repositories should be identified before the first production scan.
