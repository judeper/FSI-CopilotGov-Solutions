# Evidence Export

`Export-Evidence.ps1` packages agent governance outputs into the shared JSON evidence contract and generates a companion `.sha256` file for integrity validation. The export is designed to support audit review, supervisory evidence requests, and DORA ICT risk documentation.

## Evidence Outputs

| Evidence output | Purpose | Typical source |
|-----------------|---------|----------------|
| `agent-registry` | Shows which agents are visible in the tenant and how each one is classified by risk category. | `Deploy-Solution.ps1`, `ALG-AgentRegistry`, Dataverse baseline and finding tables |
| `approval-register` | Shows the approval path, reviewer decisions, and SLA timing for requested agent deployments. | `ALG-ApprovalRouter`, Dataverse finding table |
| `sharing-policy-audit` | Shows org-wide sharing restrictions, external sharing settings, and catalog visibility controls. | `ALG-SharingPolicyAudit`, Dataverse evidence table |

## agent-registry

Minimum fields for each record:

| Field | Description |
|-------|-------------|
| `agentId` | Stable agent identifier from the M365 Admin Center or Copilot Studio catalog. |
| `displayName` | Human-readable agent name. |
| `publisherType` | `microsoftPublished`, `itDeveloped`, `userCreated`, or `blocked`. |
| `riskCategory` | Risk classification assigned by the governance configuration. |
| `approvalStatus` | Current approval state such as `approved`, `pending-security-review`, or `blocked`. |
| `sharingScope` | Agent sharing scope such as `individual`, `team`, `org-wide`, or `external`. |
| `deploymentRing` | Rollout ring assignment such as `pilot`, `business`, or `regulated`. |

Recommended additional fields:

- `agentType` (e.g., `copilot-studio`, `declarative-agent`, `microsoft-built`)
- `createdBy`
- `createdOn`
- `lastModifiedOn`
- `connectorDependencies`
- `dataAccessScope`
- `classificationReason`

## approval-register

Recommended fields for each approval item:

| Field | Description |
|-------|-------------|
| `requestId` | Unique approval request identifier. |
| `agentId` | Agent tied to the approval request. |
| `displayName` | Agent name. |
| `riskCategory` | Risk assigned by the classifier. |
| `requestedAt` | Submission timestamp. |
| `dueBy` | SLA deadline for the current tier and risk category. |
| `approver` | Reviewer mailbox, queue, or owner. |
| `stages` | Required approval stages, such as security review, business owner attestation, and CISO sign-off. |
| `status` | Current workflow state such as `submitted`, `approved`, or `denied`. |
| `notes` | Rationale, exceptions, or follow-up actions. |

## sharing-policy-audit

Recommended fields for each sharing policy record:

| Field | Description |
|-------|-------------|
| `auditId` | Unique identifier for the sharing policy audit record. |
| `policyDimension` | Sharing policy dimension such as `orgWideSharingRestriction`, `externalSharingPolicy`, or `catalogVisibility`. |
| `currentSetting` | Current admin center setting value. |
| `expectedSetting` | Expected setting value for the selected governance tier. |
| `isCompliant` | Whether the current setting matches the expected configuration. |
| `auditedOn` | Audit timestamp. |
| `auditedBy` | Reviewer or automated audit process. |
| `notes` | Additional context or remediation guidance. |

## Export Package Content

The exported evidence package should contain:

1. metadata including solution slug, solution code `ALG`, tier, and export timestamp
2. control status entries for controls `1.13`, `2.13`, `2.14`, `4.1`, and `4.13`
3. artifact records for `agent-registry`, `approval-register`, and `sharing-policy-audit`
4. a `.sha256` file covering the JSON payload

## Retention and Review Guidance

- Baseline environments should retain evidence long enough to support supervisory sampling and change review.
- Recommended environments should retain evidence long enough to support periodic compliance review and incident follow-up.
- Regulated environments should retain evidence for at least 365 days and reconcile approved agent deployments to the DORA ICT third-party register where applicable.

## Validation Steps

- Confirm that each exported artifact aligns to the selected tier and current agent inventory.
- Confirm that blocked agents are visible in the approval register or finding records.
- Confirm that sharing policy audit records reflect current admin center configuration.
- Confirm that the `.sha256` file validates successfully after export.
