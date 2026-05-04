# Evidence Export Guide

## Evidence Types

### pages-retention-inventory

Inventory of Copilot Pages with storage/container, retention-policy, limited retention-label, Purview audit, and version-history metadata. Microsoft Learn notes that retention labels cannot be viewed or applied directly from a Copilot Page.

**Schema fields**

- `pageId`: Page identifier
- `title`: Page title
- `owner`: Page owner UPN or display name
- `createdAt` / `lastModifiedAt`: lifecycle timestamps
- `retentionLabel`: Microsoft Purview retention label resolved from supported OneDrive, SharePoint, Loop, or Purview paths; manual application from Copilot Pages is limited
- `retentionDays`: configured retention period for the tier
- `versionEvidenceStatus`: sample status for Purview audit-log or version-history evidence
- `internalSampleState`: repository-only sample taxonomy; not a Microsoft 365 Copilot Pages lifecycle state
- `internalSampleParentPageId`: optional parent reference for repository-only sample lineage

### notebook-retention-log

OneNote section and folder retention-policy coverage, grouped by Notebook metadata. Microsoft Learn states that OneNote pages inherit retention settings from their parent section file.

**Schema fields**

- `sectionId`: OneNote section file identifier
- `sectionDisplayName`: OneNote section display name
- `notebookId` / `displayName`: Notebook grouping metadata
- `parentContainer`: SharePoint site, OneDrive library, or folder that stores the section file
- `retentionLabel`
- `retentionPolicySource`: `section-label`, `folder-inherited`, `policy-inherited`, or `none`
- `retentionDays`
- `lastReviewedAt`

### loop-component-lineage

Provenance for Loop components embedded in Copilot Pages or chats.

**Schema fields**

- `componentId`
- `componentType`: e.g., `task-list`, `table`, `paragraph`
- `originatingWorkspace`
- `parentContainer`
- `embeddedInPageId`: Page or chat reference where the component is rendered
- `createdBy` / `createdAt`
- `lineageHash`: optional signed lineage hash when the regulated tier requires it

### branching-event-log

Repository-only internal sample lineage rows plus documented Purview audit/version-history context. The artifact name is retained for compatibility; the rows are not Microsoft 365 branch, fork, or mutability events.

**Schema fields**

- `eventId`
- `sourcePageId`
- `targetPageId`
- `eventType`: `sample-internal-derive`, `sample-internal-copy`, `sample-internal-consolidate`, `sample-internal-review`, or `sample-internal-retention-check`
- `actor`
- `occurredAt`
- `taxonomySource`: identifies PNRT internal sample taxonomy, not Microsoft 365 product events
- `documentedEvidence`: Purview audit logs or version history reference
- `internalSampleLineageMode`: `summary`, `full`, or tier-specific sample mode

## Package Contract

PNRT exports each artifact as a JSON file plus a SHA-256 companion. The four artifacts are produced by `scripts/Export-Evidence.ps1` and can be wrapped by the shared `Export-SolutionEvidencePackage` function for downstream packaging.

The package contract contains:

- `metadata`: solution, solution code, export version, exported timestamp, and governance tier
- `summary`: overall status, record count, and coverage-gap count
- `controls`: control-level status entries for 3.14, 3.2, 3.3, 3.11, and 2.11
- `artifacts`: named references to the exported JSON files and hash values

## Control Mappings

| Control | Primary Evidence | How PNRT Helps Meet the Control |
|---------|------------------|---------------------------------|
| 3.14 | `pages-retention-inventory`, `notebook-retention-log` | Records retention-policy coverage, limited retention-label evidence, and section-level OneNote coverage for Copilot Pages and Notebook content |
| 3.2 | `pages-retention-inventory`, `loop-component-lineage` | Documents lifecycle, version-history context, and provenance for collaborative Copilot artifacts |
| 3.3 | `notebook-retention-log` | Surfaces section/folder retention-policy coverage and gaps for Microsoft Purview alignment |
| 3.11 | `branching-event-log`, `loop-component-lineage` | Provides Purview audit/version-history context and internal sample lineage for eDiscovery and legal-hold readiness |
| 2.11 | `branching-event-log` | Documents audit-log and supervisory traceability context for Copilot artifact lifecycle review |

## Examiner Notes

PNRT packages the technical metadata needed to demonstrate retention coverage, Purview audit/version-history context, and internal sample lineage for Copilot collaborative artifacts. It does not export the underlying record content and does not place legal holds. Records-management and compliance teams should add narrative coverage assessments, supervisory-review evidence, and any preservation-lock confirmations before sharing with examiners. Use of PNRT does not on its own satisfy SEC Rule 17a-4 (which applies only to specific broker-dealer required records), FINRA Rule 4511(a), or Sarbanes-Oxley §§302/404.
