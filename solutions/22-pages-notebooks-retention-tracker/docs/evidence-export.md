# Evidence Export Guide

## Evidence Types

### pages-retention-inventory

Inventory of Copilot Pages with retention metadata and mutability state.

**Schema fields**

- `pageId`: Page identifier
- `title`: Page title
- `owner`: Page owner UPN or display name
- `createdAt` / `lastModifiedAt`: lifecycle timestamps
- `retentionLabel`: Microsoft Purview retention label assigned to the Page
- `retentionDays`: configured retention period for the tier
- `mutabilityState`: `editable`, `branched`, `locked`, or `preserved`
- `branchingParentPageId`: parent Page when the record was branched

### notebook-retention-log

OneNote Notebook retention-policy assignment and inheritance lineage.

**Schema fields**

- `notebookId`
- `displayName`
- `parentContainer`: SharePoint site or OneDrive library
- `retentionLabel`
- `retentionPolicySource`: `direct`, `inherited`, or `none`
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

Page branching, fork, and mutability transition events.

**Schema fields**

- `eventId`
- `sourcePageId`
- `targetPageId`
- `eventType`: `branch`, `fork`, `merge`, `lock`, or `preserve`
- `actor`
- `occurredAt`
- `auditMode`: `summary` or `full` based on tier

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
| 3.14 | `pages-retention-inventory`, `notebook-retention-log` | Records retention-label coverage and lifecycle metadata for Copilot Pages and OneNote Notebooks |
| 3.2 | `pages-retention-inventory`, `loop-component-lineage` | Documents lifecycle and provenance for collaborative Copilot artifacts |
| 3.3 | `notebook-retention-log` | Surfaces retention-policy inheritance and gaps for Microsoft Purview alignment |
| 3.11 | `branching-event-log`, `loop-component-lineage` | Provides eDiscovery and legal-hold readiness context for Pages, Notebooks, and Loop components |
| 2.11 | `branching-event-log` | Audit and supervisory traceability for Copilot artifact lifecycle events |

## Examiner Notes

PNRT packages the technical metadata needed to demonstrate retention coverage and lineage for Copilot collaborative artifacts. It does not export the underlying record content and does not place legal holds. Records-management and compliance teams should add narrative coverage assessments, supervisory-review evidence, and any preservation-lock confirmations before sharing with examiners. Use of PNRT does not on its own satisfy SEC Rule 17a-4 (which applies only to specific broker-dealer required records), FINRA Rule 4511(a), or Sarbanes-Oxley §§302/404.
