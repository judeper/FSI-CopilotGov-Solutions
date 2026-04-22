# Pages and Notebooks Retention Tracker Architecture

## Solution Overview

The Pages and Notebooks Retention Tracker (PNRT) provides a repeatable inventory and lineage pattern for Microsoft Copilot Pages, OneNote Notebooks, and Loop components in financial-services environments. It focuses on retention-label coverage, mutability and branching lineage, and Loop component provenance. The repository version uses representative sample data so the schemas and evidence package shape can be validated before live tenant integration is wired.

## Component Diagram

```text
+---------------------------------------------------------------+
| Microsoft Graph (Copilot Pages, OneNote, Loop) - live target  |
| Microsoft Purview (retention labels and policies) - live      |
+------------------------------+--------------------------------+
                               |
                               v
+------------------------------+--------------------------------+
| Monitor-Compliance.ps1                                        |
| - Pages Inventory Builder                                     |
| - Notebook Retention Resolver                                 |
| - Loop Provenance Builder                                     |
| - Branching Event Recorder                                    |
+------------------------------+--------------------------------+
                               |
                               v
+------------------------------+--------------------------------+
| Export-Evidence.ps1                                           |
| - pages-retention-inventory                                   |
| - notebook-retention-log                                      |
| - loop-component-lineage                                      |
| - branching-event-log                                         |
| - JSON + SHA-256 packaging                                    |
+---------------------------------------------------------------+
```

## Data Flow

1. Microsoft Graph and Microsoft Loop APIs can expose Pages, OneNote Notebooks, and Loop component metadata when a live implementation is wired.
2. `scripts/Monitor-Compliance.ps1` currently emits representative sample inventories that mirror the target contract for each artifact type.
3. The Pages Inventory Builder records the retention-label assignment, mutability state, and branching parent for each Page.
4. The Notebook Retention Resolver records the retention label assigned to each Notebook and any inheritance from the parent SharePoint or OneDrive container.
5. The Loop Provenance Builder records the originating workspace, container, and parent Page or chat for each component.
6. The Branching Event Recorder documents Page branching, fork, and mutability transitions for supervisory record reconstruction.
7. `scripts/Export-Evidence.ps1` packages each inventory and lineage artifact as a JSON file with a SHA-256 companion.

## Components

### Pages Inventory Builder

Catalogs Copilot Pages with title, owner, retention label, mutability state, and branching parent reference. The current repository version emits representative sample Pages; live integration requires Microsoft Graph beta endpoints for Copilot Pages enumeration once available to the customer tenant.

### Notebook Retention Resolver

Records OneNote Notebook retention-label assignment and resolves inheritance from the parent SharePoint site or OneDrive library. Helps surface Notebooks that fall outside any retention policy.

### Loop Provenance Builder

Captures Loop component identifier, parent container, originating workspace, and the Page or chat in which the component is embedded. Supports investigations that need to reconstruct where a Loop component was created and how it propagated.

### Branching Event Recorder

Records Page branching, fork, and mutability transitions to aid in supervisory record reconstruction. Each event includes a source Page identifier, target Page identifier, actor, and timestamp.

### Evidence Packager

Creates the four PNRT JSON artifacts and a SHA-256 file for each. Designed to plug into the shared `Export-SolutionEvidencePackage` function when tighter integration is wired.

## Integration Points

### Microsoft Graph

- Endpoint pattern (subject to availability): Copilot Pages and OneNote Notebook listings under the user or group context
- Minimum permission focus: `Notes.Read.All`, `Sites.Read.All`, and any Copilot Pages read scope released by Microsoft

### Microsoft Loop

- Purpose: Enumerate Loop workspaces, containers, and component metadata for provenance
- Integration is documentation-first; replace the sample provenance generator when Loop API access is approved

### Microsoft Purview

- Purpose: Resolve retention labels and policies that apply to Copilot Pages and OneNote Notebooks
- Helps detect coverage gaps between the artifact inventory and active retention policies

## Security Considerations

- Use least-privilege Microsoft Graph and Purview permissions for inventory reads; do not request write scopes.
- Restrict access to the exported lineage files because branching and provenance records can reveal investigation patterns.
- Apply preservation-lock and WORM storage to evidence in regulated tier when Pages or Notebooks contain records subject to SEC Rule 17a-4 (where applicable to broker-dealer required records).
- Coordinate with records-management and legal teams before changing retention configuration to avoid over-retention or premature deletion.

## Regulatory Alignment Notes

PNRT helps meet SEC Rule 17a-4 (where applicable to broker-dealer required records) by recording retention coverage and lineage for Pages and Notebooks that may contain communications or required books and records. It supports compliance with FINRA Rule 4511(a) by surfacing books-and-records coverage gaps in collaborative Copilot artifacts. It aids in Sarbanes-Oxley §§302/404 (where applicable to ICFR) artifact preservation when Pages, Notebooks, or Loop components participate in financial-reporting workflows. PNRT does not on its own satisfy any of these regulations.
