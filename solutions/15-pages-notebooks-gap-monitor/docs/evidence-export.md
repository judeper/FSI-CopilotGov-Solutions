# Evidence Export

## Overview

Copilot Pages and Notebooks Compliance Gap Monitor exports documentation-led evidence that helps compliance, legal, and audit teams explain what the tenant can and cannot do today. The package does not claim native platform remediation. Instead, it captures current gaps, the compensating controls used to manage those gaps, and the preservation exceptions that must be tracked until native coverage improves.

## gap-findings

The `gap-findings` artifact records each known gap discovered by the solution.

| Field | Description |
|-------|-------------|
| `gapId` | Stable identifier for the documented gap |
| `description` | Plain-language description of the platform limitation or review finding |
| `affectedCapability` | Capability impacted, such as Copilot Pages retention coverage or notebook Microsoft Purview eDiscovery validation |
| `affectedRegulation[]` | One or more regulations affected by the gap |
| `severity` | Severity rating, typically `high`, `medium`, or `low` |
| `discoveredAt` | Timestamp when the gap was first recorded or revalidated |
| `status` | `open`, `mitigated`, or `closed` |
| `platformUpdateRequired` | Boolean indicating whether a Microsoft platform update is needed before the gap can be closed |

## compensating-control-log

The `compensating-control-log` artifact records the interim control assigned to each open gap.

| Field | Description |
|-------|-------------|
| `controlId` | Stable identifier for the compensating control entry |
| `gapId` | Identifier of the gap addressed by the control |
| `controlDescription` | Description of the manual or administrative control |
| `controlType` | Control type such as `manual-export`, `access-review`, or `ediscovery-workaround` |
| `implementedAt` | Timestamp when the control was placed into service |
| `implementedBy` | Role or team that implemented the control |
| `approvedBy` | Reviewer who approved the control for use |
| `reviewDueDate` | Next review date for confirming the control remains in place |
| `status` | Current control status, such as `active`, `planned`, or `retired` |

## preservation-exception-register

The `preservation-exception-register` artifact records formal exceptions used when native platform coverage is incomplete.

| Field | Description |
|-------|-------------|
| `exceptionId` | Stable identifier for the exception record |
| `gapId` | Identifier of the associated gap |
| `regulation` | Regulation affected, such as `SEC 17a-4` or `FINRA 4511` |
| `exceptionRationale` | Business and compliance rationale for using the exception |
| `approvedBy` | Approver for the exception or `Pending legal sign-off` when still in draft |
| `approvalDate` | Date the exception was approved, if approved |
| `expiryDate` | Date the exception must be reviewed or renewed |
| `reviewHistory[]` | Array of review entries with reviewer, date, and notes |

## Package Contract

The combined evidence package uses the shared repository contract:

- `metadata.solution`
- `metadata.solutionCode`
- `metadata.exportVersion`
- `metadata.exportedAt`
- `metadata.tier`
- `summary.overallStatus`
- `summary.recordCount`
- `summary.findingCount`
- `summary.exceptionCount`
- `controls[]` with `controlId`, `status`, and `notes`
- `artifacts[]` with `name`, `type`, `path`, and `hash`

Each export creates:

1. a structured JSON evidence package
2. a companion `.sha256` file for integrity verification
3. standalone JSON artifact files for `gap-findings`, `compensating-control-log`, and `preservation-exception-register`

## Control mappings

| Control | Primary evidence | Notes |
|---------|------------------|-------|
| 2.11 | `gap-findings`, `compensating-control-log` | Documents sharing-control gaps and access restriction workarounds |
| 3.2 | `gap-findings`, `compensating-control-log` | Documents retention gaps and manual preservation steps |
| 3.3 | `gap-findings`, `compensating-control-log` | Tracks notebook and Loop discovery coverage and manual investigation procedures |
| 3.11 | `gap-findings`, `preservation-exception-register` | Records books-and-records gaps, approvals, and review deadlines |

## Examiner notes

When presenting this solution to SEC or FINRA examiners, lead with the gap register and explain that the organization is documenting where native platform capabilities remain incomplete. An effective presentation should include:

- the current scope of Copilot Pages, Loop, and notebook usage in the tenant
- the specific gap tied to the regulation under review
- the compensating control currently in place
- the named owner and review date for that control
- any preservation exception approvals and expiry dates
- the process used to monitor Microsoft platform updates that could close the gap

Adequate compensating controls typically include a named owner, a repeatable written procedure, evidence of execution, supervisory approval, and a recurring review cycle. If those elements are missing, the gap should remain open and the control should be described as incomplete or draft.
