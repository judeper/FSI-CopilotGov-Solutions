# Changelog

## [v0.2.1] — 2026-05-23 — Council review remediation

### VERIFIED-BUG

- Broadened Dataverse URL validation to accept sovereign cloud Dataverse hosts and environment paths.
- Standardized data-flow attestation expiration timestamps on ISO 8601 format.
- Aligned deployment, monitoring, and evidence-export sample connector inventories to the same six representative records.

### VERIFIED-DEAD-CONFIG

- Read active-tier `autoApprovedConnectorIds` when classifying connector approval status, falling back to baseline when the active tier does not define an override.
- Mapped deployment attestation expiration to the active tier `evidenceRetentionDays` setting.

### VERIFIED-VERSION-DRIFT

- Aligned the solution metadata with documentation-only control 2.16 and bumped catalog-facing version metadata to v0.2.1.

## v0.2.0

- Added cross-reference to Solution 19 (Agent Lifecycle and Deployment Governance) for agent-specific lifecycle governance coverage.

## [v0.1.1] - 2026-05-04

- Corrected least-privilege role guidance for Microsoft 365 admin center agent and plugin governance.
- Clarified Agent Registry and Microsoft Graph Agent Registry API preview boundaries for agent/plugin inventory.
- Moved the deprecated Facebook connector out of active blocked connector examples.

## v0.1.0

- Replaced shallow scaffold content with detailed connector and plugin governance guidance tailored to financial services operations and analytics teams.
- Added deployment, monitoring, and evidence export PowerShell stubs that model connector discovery, approval routing, data-flow attestation, and compliance monitoring.
- Added realistic baseline, recommended, and regulated configuration files for connector risk categories, blocked connectors, approval SLAs, and evidence retention.
- Expanded Pester coverage for documentation presence, script metadata, connector governance configuration, and PowerShell syntax validation.
