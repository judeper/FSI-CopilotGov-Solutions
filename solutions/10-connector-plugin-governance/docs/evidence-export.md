# Evidence Export

`Export-Evidence.ps1` packages connector governance outputs into the shared JSON evidence contract and generates a companion `.sha256` file for integrity validation. The export is designed to support audit review, supervisory evidence requests, and DORA third-party risk documentation.

## Evidence Outputs

| Evidence output | Purpose | Typical source |
|-----------------|---------|----------------|
| `connector-inventory` | Shows which connectors and plugins are visible in the environment and how each one is classified. | `Deploy-Solution.ps1`, `CPG-ConnectorInventory`, Dataverse baseline and finding tables |
| `approval-register` | Shows the approval path, reviewer decisions, and SLA timing for requested integrations. | `CPG-ApprovalRouter`, Dataverse finding table |
| `data-flow-attestations` | Shows approved source and destination boundaries for external or regulated data flows. | `CPG-DataFlowAudit`, Dataverse evidence table |

## connector-inventory

Minimum fields for each record:

| Field | Description |
|-------|-------------|
| `connectorId` | Stable connector or plugin identifier from the source inventory. |
| `displayName` | Human-readable connector or plugin name. |
| `publisher` | Microsoft, certified third-party publisher, or custom publisher. |
| `riskLevel` | `low`, `medium`, `high`, or `blocked`. |
| `approvalStatus` | Current approval state such as `approved`, `pending-security-review`, or `blocked`. |
| `dataFlowBoundaries` | One or more approved or requested boundaries such as `internal-m365`, `certified-third-party`, or `regulated-financial-systems`. |

Recommended additional fields:

- `assetType`
- `publisherType`
- `certification`
- `lastSeen`
- `classificationReason`
- `requiresDataFlowAttestation`

## approval-register

Recommended fields for each approval item:

| Field | Description |
|-------|-------------|
| `requestId` | Unique approval request identifier. |
| `connectorId` | Connector or plugin tied to the approval request. |
| `displayName` | Connector or plugin name. |
| `riskLevel` | Risk assigned by the classifier. |
| `requestedAt` | Submission timestamp. |
| `dueBy` | SLA deadline for the current tier and risk level. |
| `approver` | Reviewer mailbox, queue, or owner. |
| `stages` | Required approval stages, such as security review and CISO or DLP review. |
| `status` | Current workflow state such as `submitted`, `approved`, or `denied`. |
| `notes` | Rationale, exceptions, or follow-up actions. |

## data-flow-attestations

Recommended fields for each attestation:

| Field | Description |
|-------|-------------|
| `attestationId` | Unique identifier for the boundary review record. |
| `connectorId` | Connector or plugin covered by the attestation. |
| `displayName` | Connector or plugin name. |
| `sourceBoundary` | Boundary where Copilot or agent data originates. |
| `destinationBoundary` | Boundary the connector or plugin can reach. |
| `businessJustification` | Approved business rationale for the data flow. |
| `reviewedBy` | Reviewer or control owner. |
| `attestedOn` | Attestation date. |
| `expirationDate` | Optional review renewal date for recurring attestations. |
| `status` | `pending`, `approved`, `expired`, or `exception`. |

## Export Package Content

The exported evidence package should contain:

1. metadata including solution slug, solution code `CPG`, tier, and export timestamp
2. control status entries for controls `1.13`, `2.13`, `2.14`, and `4.13`
3. artifact records for `connector-inventory`, `approval-register`, and `data-flow-attestations`
4. a `.sha256` file covering the JSON payload

## Retention and Review Guidance

- Baseline environments should retain evidence long enough to support supervisory sampling and change review.
- Recommended environments should retain evidence long enough to support periodic compliance review and incident follow-up.
- Regulated environments should retain evidence for at least 365 days and reconcile approved third parties to the DORA third-party register.

## Validation Steps

- Confirm that each exported artifact aligns to the selected tier and current connector inventory.
- Confirm that blocked connectors are visible in the approval register or finding records.
- Confirm that cross-boundary use cases include a matching data-flow attestation.
- Confirm that the `.sha256` file validates successfully after export.
