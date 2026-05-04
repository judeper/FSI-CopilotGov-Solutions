# Prerequisites

## Microsoft 365 Requirements

- Microsoft 365 E3/E5 or an equivalent qualifying subscription with Microsoft 365 Copilot add-on licensing for in-scope users, plus OneNote, Loop, and SharePoint Online enabled
- Copilot Pages and Copilot Notebooks enabled for the population in scope for inventory
- Microsoft Purview retention policies and supported retention labels configured for collaborative content

## Required Access and Permissions

The Entra application and administrative accounts used by PNRT should be granted only the read-only access required for inventory and evidence reporting.

- `Notes.Read.All` for OneNote notebook and section metadata where a live OneNote inventory is implemented
- `Sites.Read.All` for SharePoint, OneDrive, and supported file/container metadata where applicable
- SharePoint Embedded administrator access to retrieve Copilot Pages, Copilot Notebooks, and Loop container URLs for Purview targeting
- Microsoft Purview read access for audit-log search/export and retention label/policy lookup

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
- SharePoint admin center and SharePoint Embedded administration endpoints approved by the customer
- Microsoft Purview compliance endpoints approved by the customer

## Role Requirements

- Global Reader for tenant-wide inventory visibility
- Compliance Administrator or a custom role group with Retention Management / View-Only Retention Management for retention-policy lookup
- Records Management role group for records-management and disposition tasks where required
- Designated Supervisor role recommended for the regulated tier supervisory-review queue

## Shared Dependencies

PNRT can plug into shared repository components when wired:

- `scripts/common/EvidenceExport.psm1`
- `scripts/common/IntegrationConfig.psm1`
- `data/evidence-schema.json`

## Recommended

- Microsoft Purview retention policies pre-published for All SharePoint Sites or specific SharePoint Embedded container URLs for Copilot Pages and Copilot Notebooks, plus SharePoint/OneDrive folders or section files for OneNote content
- Documented records-management policy mapping Copilot artifact types to required retention periods
- Approved evidence-retention location for JSON and SHA-256 artifacts
