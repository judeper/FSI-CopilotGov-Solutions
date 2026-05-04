# Prerequisites

## Microsoft 365 and Power Platform Requirements

- Microsoft 365 tenant with Microsoft Copilot Studio licensing assigned to authoring users
- Power Platform environments for development, test, and production scoped for governed Copilot Studio agents
- Microsoft Purview audit logging enabled where audit-log enrichment is planned (optional)

## Required API Permissions (target for live integration)

The Entra application used by CSLT, when live integration is added, should be granted only the permissions required for inventory and lifecycle reads.

- Power Platform API delegated permissions for the specific namespace and resource read actions required by the live design; Microsoft Learn states that Power Platform API uses delegated permissions only at this time.
- For service-principal automation, assign a scoped Power Platform RBAC role such as Reader or Contributor instead of relying on application permissions.
- Microsoft Graph delegated or application permissions sufficient to resolve reviewer and owner identities.

Admin consent is typically required before these permissions can be used in production.

## Azure and Entra Requirements

- Entra ID application registration dedicated to CSLT monitoring
- Client secret or certificate for service-principal authentication after scoped RBAC roles are assigned (when live integration is enabled)
- Tenant ID and application ID documented for deployment
- Optional immutable storage account for regulated-tier evidence

## PowerShell Requirements

- Repository scaffold scripts: PowerShell 7.2 or later
- Live integrations that use `Microsoft.PowerApps.Administration.PowerShell`: Windows PowerShell 5.x; the module uses .NET Framework and is incompatible with PowerShell 6.0 and later
- PowerShell 7+ live integrations should use Power Platform REST API/SDK patterns instead of the legacy admin module

## Network Requirements

The deployment host should allow outbound access to:

- `api.powerplatform.com`
- `graph.microsoft.com`

## Role Requirements

- Power Platform Administrator for tenant-wide administration, or Environment Admin for scoped environment administration; assign Dataverse and Copilot Studio roles separately as required
- Audit Logs or View-Only Audit Logs roles in the Microsoft Purview portal for audit search and review; use Purview role groups such as Audit Manager, Audit Reader, or Compliance Administrator according to duties

## Shared Dependencies

CSLT depends on shared repository components:

- `scripts/common/EvidenceExport.psm1`
- `scripts/common/IntegrationConfig.psm1`
- `data/evidence-schema.json`
