# Prerequisites

## Microsoft 365 and Power Platform Requirements

- Microsoft 365 tenant with Microsoft Copilot Studio licensing assigned to authoring users
- Power Platform environments for development, test, and production scoped for governed Copilot Studio agents
- Microsoft Purview audit logging enabled where audit-log enrichment is planned (optional)

## Required API Permissions (target for live integration)

The Entra application used by CSLT, when live integration is added, should be granted only the permissions required for inventory and lifecycle reads.

- Power Platform admin API access for Copilot Studio agent inventory
- Microsoft Graph delegated or application permissions sufficient to resolve reviewer and owner identities

Admin consent is typically required before these permissions can be used in production.

## Azure and Entra Requirements

- Entra ID application registration dedicated to CSLT monitoring
- Client secret or certificate for app authentication (when live integration is enabled)
- Tenant ID and application ID documented for deployment
- Optional immutable storage account for regulated-tier evidence

## PowerShell Requirements

- PowerShell 7.2 or later
- `Microsoft.PowerApps.Administration.PowerShell` (when live Power Platform admin integration is added)

## Network Requirements

The deployment host should allow outbound access to:

- `api.powerplatform.com`
- `graph.microsoft.com`

## Role Requirements

- Power Platform Administrator or environment-scoped Service Admin for Copilot Studio inventory access
- Purview Compliance Admin for evidence review and retention oversight (when audit enrichment is added)

## Shared Dependencies

CSLT depends on shared repository components:

- `scripts/common/EvidenceExport.psm1`
- `scripts/common/IntegrationConfig.psm1`
- `data/evidence-schema.json`
