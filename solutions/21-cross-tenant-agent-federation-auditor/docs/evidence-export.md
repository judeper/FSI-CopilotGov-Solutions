# Evidence Export

CTAF produces four evidence artifacts per run, written as JSON files with SHA-256 companion files.

## Artifacts

### `agent-federation-inventory`

Inventory of Copilot Studio agents and Entra Agent IDs exposed across tenant boundaries.

| Field | Description |
|-------|-------------|
| agentId | Stable identifier for the agent. |
| displayName | Human-readable name. |
| sourceTenantId | Tenant that publishes the agent. |
| channel | Copilot Studio channel used to make the agent available. |
| authenticationType | Authentication option selected for users who chat with the agent. |
| requireUsersToSignIn | Whether sign-in is required for the sample governance classification. |
| sharingScope | Organization sharing scope or approved audience classification. |
| allowedUsersOrGroups | Users, groups, or partner tenant review groups approved for access in the sample record. |
| approvedAudienceTenants | Tenant IDs explicitly approved for invocation. |
| lastReviewedAt | Timestamp of the most recent governance review. |

### `cross-tenant-trust-assessment`

Review status of cross-tenant access settings and external collaboration scopes that affect agent invocation.

| Field | Description |
|-------|-------------|
| relationshipId | Identifier for the cross-tenant trust relationship. |
| direction | `inbound`, `outbound`, or `bidirectional`. |
| allowedAudiences | Allowed app or agent audiences. |
| reviewStatus | `current`, `due`, or `overdue` based on the tier cadence. |

### `mcp-trust-relationship-log`

MCP server connection review records.

| Field | Description |
|-------|-------------|
| serverId | MCP server identifier. |
| serverUrl | HTTPS URL configured for the MCP server connection. |
| transportType | MCP transport type; Copilot Studio currently supports Streamable transport. |
| authenticationType | Configured authentication method, such as API key or OAuth 2.0. |
| allowedTools | Tool names approved for the connection review. |
| approvalRequired | Whether tool-call approval is required by the sample governance classification. |
| lastConnectionReviewAt | Timestamp of the most recent connection/authentication review. |
| connectionReviewStatus | `current`, `stale`, or `missing` based on the tier cadence. |
| scopes | Scopes granted to the MCP server. |

### `agent-id-attestation-evidence`

Microsoft Entra Agent ID identity-governance review metadata.

| Field | Description |
|-------|-------------|
| agentIdentityId | Microsoft Entra Agent ID identity account for the agent. |
| displayName | Human-readable Agent ID name. |
| blueprintId | Agent identity blueprint reference, when used. |
| owner | Accountable owner recorded for the agent identity. |
| sponsor | Sponsor recorded for the agent identity, where applicable. |
| assignedPermissions | Permissions assigned to the agent identity for review. |
| conditionalAccessPosture | Sample review status for Conditional Access coverage. |
| auditLogReference | Reference to sign-in or audit log evidence used in the review. |
| lastReviewedAt | Timestamp of the most recent identity-governance review. |
| reviewStatus | `current`, `due`, or `overdue` based on the tier cadence. |

If an organization tracks signing or key-rotation controls for its own agent implementation, treat those as customer-defined evidence fields outside the documented Microsoft Entra Agent ID schema.

## Integrity

Each JSON artifact has a matching `.sha256` file containing the hash of the artifact bytes. Examiners can recompute the hash to confirm the file has not been altered after export.

## Retention

Retention is tier-driven (`evidenceRetentionDays`): 90 days (baseline), 365 days (recommended), 1825 days (regulated). Regulated retention aligns with broker-dealer record-keeping practice frequently associated with SEC Rule 17a-4 — required broker-dealer records only, where applicable. Organizations should verify their specific retention obligations.
