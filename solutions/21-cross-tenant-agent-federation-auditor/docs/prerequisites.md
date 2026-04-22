# Prerequisites

## Tooling

- PowerShell 7.2 or later.
- Pester 5.x for running the smoke tests.

## Microsoft 365 / Entra (for future live integration)

The repository scaffold runs without tenant connectivity. The following are required only when live integration is wired in a future release:

- Microsoft Entra ID tenant with Copilot Studio enabled.
- Microsoft Entra Agent ID feature enabled in the tenant.
- Entra app registration with delegated read scopes for cross-tenant access policies (least privilege).
- Read access to Copilot Studio agent publishing settings.
- Network egress to MCP server `/.well-known` attestation endpoints, where applicable.

## Roles (for live integration)

Use canonical short names:

- Entra Global Admin (for initial app registration).
- Purview Compliance Admin (for evidence retention coordination).
- M365 Global Admin (for Copilot Studio environment access review).

## Repository

- The shared module path `scripts/common/` is expected at the repository root and is referenced by the deployment and export scripts.
