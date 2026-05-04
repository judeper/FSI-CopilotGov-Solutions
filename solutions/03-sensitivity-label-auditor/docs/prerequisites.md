# Prerequisites

## Licensing

- Microsoft 365 E5/A5/G5, Microsoft Purview Suite, or Microsoft 365 Information Protection and Governance for sensitivity labeling scenarios.
- Microsoft 365 E5/A5/G5, Microsoft Purview Suite, Microsoft Defender + Purview Suite, or Microsoft 365 Information Protection and Governance for service-side automatic sensitivity labeling where the tenant uses auto-labeling.

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
| Sensitivity label definitions | `InformationProtectionPolicy.Read` | `InformationProtectionPolicy.Read.All` | Organization label enumeration uses Microsoft Graph beta `/security/informationProtection/sensitivityLabels`; production use should follow tenant beta API governance. |
| SharePoint and OneDrive label extraction | `Files.Read.All` | `Files.Read.All` | Least-privileged permission for `driveItem: extractSensitivityLabels`; higher permissions such as `Sites.Read.All` should be used only when the tenant-approved design requires them. |
| Approved bulk label assignment extensions | `Files.ReadWrite.All` | `Files.ReadWrite.All` | `assignSensitivityLabel` is a protected SharePoint and OneDrive API; `Sites.ReadWrite.All` is the higher-privileged alternative when justified. |
| Exchange labeling evidence | `Mail.Read` or approved Purview export access | `Mail.Read` or approved Purview export access | Microsoft Graph message resources do not expose a first-class sensitivity-label field, so Exchange coverage requires a documented tenant source such as audit/activity exports, Internet message headers, or extended properties. |

Additional permissions may be needed if the organization extends the solution to workflow automation, but the implementation should use least-privileged permissions and document each approval.

## PowerShell and Modules

- PowerShell 7.x
- `Microsoft.Graph`
- `ExchangeOnlineManagement`
- `PnP.PowerShell`

The scripts are written as implementation-ready stubs and can be extended with tenant-approved authentication and Graph request logic.

## Upstream Solution Dependencies

The following solutions must be complete before solution 03 is considered ready for production monitoring:

- `01-copilot-readiness-scanner` completed
- `02-oversharing-risk-assessment` initial scan completed

Solution 01 provides rollout and workload context. Solution 02 provides oversharing findings that help prioritize unlabeled content in regulated stores.

## Governance and Taxonomy

- The sensitivity label taxonomy must be configured in the Microsoft Purview portal before the audit runs.
- The organization should confirm the FSI label hierarchy and expected business mappings before scanning begins.
- Priority sites, supervisory mailboxes, and regulated repositories should be identified before the first production scan.
