# Prerequisites

## Microsoft 365 Requirements

- Microsoft 365 E3 or E5 tenant with Copilot-enabled workloads in scope
- Exchange Online, SharePoint Online, Microsoft Teams, Microsoft Graph-connected services, and Microsoft 365 Apps available for monitoring
- Microsoft 365 Copilot licenses assigned to the pilot or production population being governed
- E5 or equivalent monitoring and security add-ons recommended when Microsoft Sentinel enrichment is planned

## Required API Permissions

The Entra application used by DRM should be granted only the permissions required for monitoring and evidence support.

- `ServiceHealth.Read.All` for Microsoft Graph service-health access
- `SecurityEvents.Read.All` for Graph-based operational and security event enrichment where available

Admin consent is typically required before these permissions can be used in production.

## Azure and Entra Requirements

- Entra ID application registration dedicated to DRM monitoring
- Client secret or certificate for app authentication
- Tenant ID and application ID documented for deployment
- Optional immutable storage account and Microsoft Sentinel workspace for regulated-tier enhancements

## PowerShell Requirements

- PowerShell 7.2 or later
- `Microsoft.Graph.Reports`
- `ExchangeOnlineManagement`

If the target operating model uses certificate-based authentication or broader Graph automation, install the supporting Microsoft Graph authentication module approved by the customer security team.

## Network Requirements

The deployment host and any automation worker should allow outbound access to:

- `graph.microsoft.com`
- `admin.microsoft.com`

If Microsoft Sentinel enrichment is enabled, allow outbound access to the workspace ingestion and query endpoints approved by the customer network team.

## Role Requirements

- Global Reader or Service Support Admin for Microsoft 365 service-health access
- Compliance Admin for evidence review and retention oversight
- Additional Sentinel or storage roles if regulated-tier monitoring and immutable retention are enabled

## Shared Dependencies

DRM depends on shared repository components:

- `scripts/common/EvidenceExport.psm1`
- `scripts/common/IntegrationConfig.psm1`
- `data/evidence-schema.json`
- Dependency solution: `12-regulatory-compliance-dashboard` when centralized reporting is needed

## Recommended

- Azure Sentinel workspace with Copilot activity logs
- Defined escalation list for service-health incidents and resilience-test exceptions
- Approved evidence-retention location for JSON and SHA-256 artifacts
