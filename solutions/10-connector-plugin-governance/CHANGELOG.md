# Changelog

## [Unreleased] — 2026-07-14 — Microsoft currency review (Solution 10)

### Fixed

- Replaced the vague legacy "Graph Agent Registry APIs" wording with the currently documented Microsoft Agent 365 Package Management Graph API. The API is documented as preview; read-only inventory uses `GET /v1.0/copilot/admin/catalog/packages` with `CopilotPackages.Read.All`, requires a Microsoft Agent 365 license and AI Administrator or Global Administrator, and is complementary to the Microsoft 365 admin center registry/CSV experience.
- Corrected sample connector IDs in `config/default-config.json`: `shared_x` → `shared_twitter` (current Power Platform connector ID; display name "X") and `shared_boxpersonal` → `shared_box`.
- Fixed a strict-mode failure in `Export-Evidence.ps1` for the `regulated` tier, which defines no `autoApprovedConnectorIds`; auto-approval lookups are now guarded.

### Changed

- Clarified Microsoft 365 Copilot connector currency: synced (indexed into Microsoft Graph) versus federated (real-time, Model Context Protocol based, early access preview) connector models; federated connectors are read-only.
- Aligned Model Context Protocol (MCP) governance language: MCP servers are governed through Copilot Studio and Power Platform data loss prevention connector classification (Business, Non-Business, Blocked); no universal MCP registry or API is claimed. Updated control 2.16 wording accordingly.
- Clarified that registry filtering and CSV export are read-only while pinning is a mutable action outside this lab cycle, and minimized retained MCP/app-registration/API inventory to pseudonymized or aggregate metadata.
- Added the least-privilege AI Reader read-only role for agent-registry inventory review and confirmed the AI Administrator role is required to manage Microsoft 365 Copilot connectors.
- Updated Scope Boundaries to attribute Microsoft Agent 365 platform governance, the converged agent registry and control plane, and Microsoft Entra Agent ID controls to Microsoft Agent 365 and Solutions 21 and 23.
- Aligned `Export-Evidence.ps1` and `Monitor-Compliance.ps1` with the documentation-first evidence convention: `runtimeMode` and `dataSourceMode` honesty markers, representative-sample control statuses reported as `partial`, and package-relative artifact paths.
- Refreshed `last_verified` in `config/default-config.json` to 2026-07-14.

### Added

- Read-only lab validation contract `lab/10-connector-plugin-governance.lab.json` (`mutations: []`) with repository shared registration in `scripts/test_lab_validation_contracts.py` and `scripts/tests/lab-validation.Tests.ps1`.
- Added a deployment-guide/checklist handoff for aggregate-only Package Management API validation, identifier/secret minimization, and fail-closed ignored staging cleanup.

## [v0.2.3] — 2026-06-05 — MS Learn accuracy pass-2 correction

### Fixed

- Corrected declarative agent description: replaced "through configuration rather than code" with "using Copilot's own orchestrator and models, buildable with low-code or pro-code tooling" per MS Learn. Declarative agents support both low-code (M365 Copilot) and pro-code (VS Code, Visual Studio, M365 Agents Toolkit) authoring paths.



### Fixed

- Corrected Copilot Control System description: CCS is a framework spanning the M365 admin center, Power Platform admin center, and Copilot Studio — not a single centralized admin surface.
- Added scope boundary clarifying that Microsoft Graph connectors API path is not modeled (only Power Platform Admin API surface is documented).
- Replaced retired `shared_twitter` connector ID with current `shared_x` in blocked examples and blocked list.

## Validation Sweep — 2026-05-25

### Verified

- All PowerShell scripts pass syntax validation.
- AI Administrator role confirmed as preferred admin role for M365 admin center agent and plugin governance.
- Power Platform Admin API connector enumeration pattern confirmed current.
- Microsoft Graph Agent Registry APIs correctly noted as preview.
- Risk classification categories (low, medium, high, blocked) align with documented connector governance patterns.
- Regulatory citations (FINRA 3110, OCC 2011-12, DORA) are accurate.
- Facebook connector Learn URL (`https://learn.microsoft.com/connectors/facebook/`) resolves; connector correctly categorized as deprecated/blocked.
- Added `last_verified` to `config/default-config.json`.

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
