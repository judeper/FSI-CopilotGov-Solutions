# Prerequisites

## Microsoft 365 Requirements

- Microsoft 365 E3 or E5 tenant with Microsoft Copilot, OneNote, Loop, and SharePoint Online enabled
- Copilot Pages enabled for the population in scope for inventory
- Microsoft Purview retention labels and policies configured for collaborative content

## Required API Permissions

The Entra application used by PNRT should be granted only the read-only scopes required for inventory and lineage reporting.

- `Notes.Read.All` for OneNote Notebook enumeration
- `Sites.Read.All` for SharePoint and OneDrive container resolution
- Loop and Copilot Pages read scopes as released by Microsoft for the tenant
- Microsoft Purview read access for retention labels and policies

Admin consent is typically required before these permissions can be used in production.

## Azure and Entra Requirements

- Entra ID application registration dedicated to PNRT inventory
- Client secret or certificate for app authentication
- Tenant ID and application ID documented for deployment
- Optional immutable storage account for regulated-tier WORM evidence (`PNRT_IMMUTABLE_STORAGE_ACCOUNT`)

## PowerShell Requirements

- PowerShell 7.2 or later
- `Microsoft.Graph` modules for Notes and Sites
- Pester 5 or later for tests

## Network Requirements

The deployment host should allow outbound access to:

- `graph.microsoft.com`
- `loop.cloud.microsoft` (or successor Loop service endpoints)
- Microsoft Purview compliance endpoints approved by the customer

## Role Requirements

- Global Reader for tenant-wide inventory visibility
- Purview Compliance Admin for retention-policy lookup
- Records-management owner for retention period agreement
- Designated Supervisor role recommended for the regulated tier supervisory-review queue

## Shared Dependencies

PNRT can plug into shared repository components when wired:

- `scripts/common/EvidenceExport.psm1`
- `scripts/common/IntegrationConfig.psm1`
- `data/evidence-schema.json`

## Recommended

- Microsoft Purview retention policies pre-published for the SharePoint and OneDrive containers that host Copilot Pages and OneNote Notebooks
- Documented records-management policy mapping Copilot artifact types to required retention periods
- Approved evidence-retention location for JSON and SHA-256 artifacts
