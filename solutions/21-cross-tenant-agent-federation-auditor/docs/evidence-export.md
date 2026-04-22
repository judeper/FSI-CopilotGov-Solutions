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
| publishingMode | `single-tenant`, `multi-tenant`, or `restricted-multi-tenant`. |
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

MCP federated server trust records.

| Field | Description |
|-------|-------------|
| serverId | MCP server identifier. |
| transport | Transport (e.g., `https`). |
| signingKeyThumbprint | Sha-256 thumbprint of the attested signing key. |
| attestedAt | Timestamp of the most recent attestation. |
| attestationStatus | `current`, `stale`, or `missing`. |
| scopes | Scopes granted to the MCP server. |

### `agent-id-attestation-evidence`

Entra Agent ID signing, key rotation, and verification metadata.

| Field | Description |
|-------|-------------|
| agentId | Entra Agent ID. |
| signingRequired | Whether signing is required by the active tier. |
| lastKeyRotationAt | Timestamp of the most recent key rotation. |
| nextKeyRotationDueAt | Next required rotation timestamp. |
| verificationStatus | `verified`, `pending`, or `failed`. |

## Integrity

Each JSON artifact has a matching `.sha256` file containing the hash of the artifact bytes. Examiners can recompute the hash to confirm the file has not been altered after export.

## Retention

Retention is tier-driven (`evidenceRetentionDays`): 90 days (baseline), 365 days (recommended), 1825 days (regulated). Regulated retention aligns with broker-dealer record-keeping practice frequently associated with SEC Rule 17a-4 — required broker-dealer records only, where applicable. Organizations should verify their specific retention obligations.
