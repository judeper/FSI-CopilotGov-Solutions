# Evidence Export

## Evidence Outputs

`Export-Evidence.ps1` produces three solution-specific evidence artifacts and wraps them in the shared package contract by calling `Export-SolutionEvidencePackage`.

### `policy-template-export`

This artifact records the policy templates prepared for publication.

Schema:

| Field | Type | Description |
|-------|------|-------------|
| `policyName` | string | Published or planned policy name |
| `policyType` | string | Policy category such as AI disclosure or promotional review |
| `scope` | string[] | Communication channels and audience scope |
| `keywords` | string[] | Supervised terms and lexicon words |
| `conditions` | string[] | Matching conditions documented for reviewer interpretation |
| `createdAt` | string | ISO 8601 timestamp for template creation |
| `publishedAt` | string | ISO 8601 timestamp for manual portal publication or planned publication |
| `version` | string | Template or policy version |

### `reviewer-queue-metrics`

This artifact records queue health at the time of export.

Schema:

| Field | Type | Description |
|-------|------|-------------|
| `snapshotDate` | string | ISO 8601 timestamp of the queue snapshot |
| `totalPending` | number | Total queued review items |
| `avgAgeHours` | number | Average queue age in hours |
| `p90AgeHours` | number | 90th percentile queue age in hours |
| `dispositionBreakdown[]` | array | Counts by reviewer disposition |
| `escalatedCount` | number | Number of items escalated for supervision or legal review |
| `overdueCount` | number | Number of items over the configured SLA |

### `lexicon-update-log`

This artifact records approved lexicon changes.

Schema:

| Field | Type | Description |
|-------|------|-------------|
| `updateDate` | string | ISO 8601 or ISO date value for the lexicon change |
| `wordAdded[]` | array | Words or phrases added to the supervised lexicon |
| `wordRemoved[]` | array | Words or phrases removed from the supervised lexicon |
| `updatedBy` | string | Owner who applied the change |
| `approvedBy` | string | Approver for the lexicon change |
| `policyVersion` | string | Version aligned to the published policy set |

## Package Contract

The packaged evidence JSON follows the shared schema fields:

- `metadata`: `solution`, `solutionCode`, `exportVersion`, `exportedAt`, `tier`
- `summary`: `overallStatus`, `recordCount`, `findingCount`, `exceptionCount`
- `controls[]`: `controlId`, `status`, `notes`
- `artifacts[]`: `name`, `type`, `path`, `hash`

The solution writes the package and SHA-256 hash file into the selected output folder.

## Control Mappings

| Control | Status Target | Evidence Contribution |
|---------|---------------|-----------------------|
| 2.10 | `monitor-only` | Insider risk correlation template and reviewer escalation notes |
| 3.4 | `implemented` | Published policy templates and queue metrics guidance |
| 3.5 | `implemented` | FINRA 2210 promotional content and financial advice review templates |
| 3.6 | `partial` | Reviewer queue metrics and supervision workflow evidence require manual reviewer actions |
| 3.9 | `partial` | AI disclosure policy templates are exported, but monitoring remains partly manual |

## Operational Notes

- Evidence export packages generated content and documented monitoring data; it does not attest that all policies are published unless customer operations maintain the required portal records.
- Queue metrics may reflect documentation-first monitoring if automated collection is not available.
- Lexicon approvals should be retained alongside the generated JSON artifacts for examinations.
