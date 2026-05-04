# Pages and Notebooks Retention Tracker Architecture

## Solution Overview

The Pages and Notebooks Retention Tracker (PNRT) provides a repeatable inventory and evidence pattern for Microsoft Copilot Pages, OneNote sections grouped by Notebook metadata, and Loop components in financial-services environments. It focuses on retention-policy coverage, limited retention-label evidence, Purview audit logs, version-history context, and Loop component provenance. The repository version uses representative sample data so the schemas and evidence package shape can be validated before live tenant integration is wired.

## Component Diagram

```text
+---------------------------------------------------------------+
| SharePoint Embedded containers + Graph DriveItem/export       |
| Microsoft Purview audit/retention + Cloud Policy admin        |
+------------------------------+--------------------------------+
                               |
                               v
+------------------------------+--------------------------------+
| Monitor-Compliance.ps1                                        |
| - Pages Inventory Builder                                     |
| - Notebook Retention Resolver                                 |
| - Loop Provenance Builder                                     |
| - Audit and Version Evidence Mapper                          |
+------------------------------+--------------------------------+
                               |
                               v
+------------------------------+--------------------------------+
| Export-Evidence.ps1                                           |
| - pages-retention-inventory                                   |
| - notebook-retention-log                                      |
| - loop-component-lineage                                      |
| - branching-event-log (internal sample lineage)               |
| - JSON + SHA-256 packaging                                    |
+---------------------------------------------------------------+
```

## Data Flow

1. A live implementation should use documented surfaces: SharePoint Embedded container URLs, Microsoft Graph DriveItem/export capabilities where documented, OneNote section metadata, Microsoft Purview audit/retention, and Cloud Policy or SharePoint admin controls.
2. `scripts/Monitor-Compliance.ps1` currently emits representative sample inventories that mirror the target contract for each artifact type.
3. The Pages Inventory Builder records retention-policy coverage, limited retention-label evidence, source container references, and version-history/audit context for each Page.
4. The Notebook Retention Resolver records OneNote section and folder retention coverage and keeps Notebook identity only as grouping metadata.
5. The Loop Provenance Builder records the originating workspace, container, and parent Page or chat for each component.
6. The Audit and Version Evidence Mapper documents Purview audit-log and version-history context; repository sample lineage rows are internal taxonomy only and are not Microsoft 365 branch, fork, or mutability events.
7. `scripts/Export-Evidence.ps1` packages each inventory and lineage artifact as a JSON file with a SHA-256 companion.

## Components

### Pages Inventory Builder

Catalogs Copilot Pages with title, owner, storage/container reference, retention-policy coverage, limited retention-label evidence, and version-history context. The current repository version emits representative sample Pages; live integration should use SharePoint Embedded container discovery, documented Microsoft Graph DriveItem/export capabilities, and Purview audit/retention data where available.

### Notebook Retention Resolver

Records OneNote section and folder retention coverage from the parent SharePoint site or OneDrive library, with Notebook identifiers used for grouping and reporting. Helps surface sections or folders that fall outside any retention policy.

### Loop Provenance Builder

Documents Loop component identifier, parent container, originating workspace, and the Page or chat in which the component is embedded. Supports investigations that need to reconstruct where a Loop component was created and how it propagated.

### Audit and Version Evidence Mapper

Documents Purview audit-log and version-history context for Pages and Notebooks. The `branching-event-log` artifact name is retained for compatibility, but its rows are repository-only internal sample lineage taxonomy and are not emitted by Microsoft 365 as branch, fork, or mutability events.

### Evidence Packager

Creates the four PNRT JSON artifacts and a SHA-256 file for each. Designed to plug into the shared `Export-SolutionEvidencePackage` function when tighter integration is wired.

## Integration Points

### Microsoft Graph and SharePoint Embedded

- Endpoint pattern: documented DriveItem/export and file metadata capabilities where available, plus OneNote notebook/section metadata for OneNote evidence
- Minimum permission focus: `Notes.Read.All` for OneNote, `Sites.Read.All` for SharePoint/OneDrive file metadata, and SharePoint Embedded administrator access for container URL discovery when required

### Loop and Copilot Pages admin surfaces

- Purpose: Locate SharePoint Embedded containers, Loop workspace context, and Cloud Policy or SharePoint admin controls that govern creation and storage
- Integration is documentation-first; replace the sample provenance generator only with documented SharePoint Embedded, Cloud Policy, Purview, or Graph file/export surfaces

### Microsoft Purview

- Purpose: Resolve retention policies and limited retention-label evidence that apply to Copilot Pages, SharePoint Embedded containers, and OneNote section files/folders
- Caveat: Retention labels cannot be viewed or applied directly from a Copilot Page, and record/regulatory-record labels cannot be manually applied in Copilot Pages or Loop
- Helps detect coverage gaps between the artifact inventory and active retention policies

## Security Considerations

- Use least-privilege Microsoft Graph, SharePoint Embedded, and Purview permissions for inventory reads; do not request write scopes.
- Restrict access to the exported lineage files because internal sample lineage and provenance records can reveal investigation patterns.
- Apply preservation-lock and WORM storage to evidence in regulated tier when Pages or Notebooks contain records subject to SEC Rule 17a-4 (where applicable to broker-dealer required records).
- Coordinate with records-management and legal teams before changing retention configuration to avoid over-retention or premature deletion.

## Regulatory Alignment Notes

PNRT helps meet SEC Rule 17a-4 (where applicable to broker-dealer required records) by documenting retention coverage, audit-log availability, version-history context, and OneNote section/folder coverage for Pages and Notebooks that may contain communications or required books and records. It supports compliance with FINRA Rule 4511(a) by surfacing books-and-records coverage gaps in collaborative Copilot artifacts. It aids in Sarbanes-Oxley §§302/404 (where applicable to ICFR) artifact preservation when Pages, Notebooks, or Loop components participate in financial-reporting workflows. PNRT does not on its own satisfy any of these regulations.
