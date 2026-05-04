# Evidence Export Guide

## Evidence Types

### agent-lifecycle-inventory

Captures the inventory of Copilot Studio agents across the configured environments.

**Schema fields**

- `agentId`
- `displayName`
- `environment`
- `owner`
- `businessSponsor`
- `currentVersion`
- `lastPublishedAt`
- `lastReviewedAt`
- `lifecycleStage`
- `sourceEndpoint`

### publishing-approval-log

Records publishing events and the supervisory approval evidence for each event.

**Schema fields**

- `agentId`
- `version`
- `submittedBy`
- `submittedAt`
- `approvers` (array of reviewer identities)
- `approvedAt`
- `changeSummary`
- `tierApprovalRequirementMet` (boolean)

### version-history

Per-agent version/change records covering published updates and operator-supplied change notes. Microsoft Learn's [Copilot Studio publishing guidance](https://learn.microsoft.com/en-us/microsoft-copilot-studio/publication-fundamentals-publish-channels) documents that each update can be published again and updates connected channels; it does not provide a canonical rollback event API, so rollback references in this scaffold are customer-supplied evidence fields.

**Schema fields**

- `agentId`
- `version`
- `publishedAt`
- `publishedBy`
- `changeNotes`
- `rollbackOf` (optional customer-supplied reference; not populated from a validated Microsoft rollback API in this scaffold)
- `previousVersion` (optional)

### deprecation-evidence

Captures deprecation notices and final disposition records for retired agents.

**Schema fields**

- `agentId`
- `deprecationAnnouncedAt`
- `customerNotifiedAt`
- `sunsetDate`
- `finalDisposition`
- `recordsRetentionConfirmed` (boolean)
- `notes`

## Package Contract

CSLT exports evidence as JSON plus SHA-256 companion files. The four artifacts are created first, and then `scripts/Export-Evidence.ps1` calls the shared `Export-SolutionEvidencePackage` function to create the final package aligned to `data/evidence-schema.json`.

The package contract contains:

- `metadata`: solution, solution code, export version, exported timestamp, governance tier
- `summary`: overall status, record count, finding count, exception count
- `controls`: control-level status entries for 4.14, 4.13, 1.10, 1.16, 4.5, and 4.12
- `artifacts`: named references to the exported JSON files and hash values

## Control Mappings

| Control | Primary Evidence | How CSLT Helps |
|---------|------------------|----------------|
| 4.14 | `agent-lifecycle-inventory`, `deprecation-evidence` | Lifecycle inventory and retirement records support agent governance and supervisory review |
| 4.13 | `publishing-approval-log`, `version-history` | Approval and version records support change-management documentation |
| 1.10 | `agent-lifecycle-inventory` | Agent inventory contributes to broader Copilot Studio governance posture |
| 1.16 | `agent-lifecycle-inventory` | Owner and business sponsor metadata aids in accountability and risk classification |
| 4.5 | `publishing-approval-log` | Lifecycle review cadence findings contribute to ongoing assurance activities |
| 4.12 | `version-history`, `publishing-approval-log` | Change-control evidence aligned to platform-level supervision |

## Examiner Notes

CSLT packages the technical evidence needed to demonstrate Copilot Studio agent change-management discipline, supervisory approval, and deprecation oversight. The export does not submit notices to regulators automatically and does not replace firm WSPs. Operations and compliance teams should add narrative context, supervisory reviewer summaries, and any required attestations before external submission.
