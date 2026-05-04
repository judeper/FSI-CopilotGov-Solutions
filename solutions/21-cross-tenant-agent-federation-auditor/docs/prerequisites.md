# Prerequisites

## Tooling

- PowerShell 7.2 or later.
- Pester 5.x for running the smoke tests.

## Microsoft 365 / Entra (for future live integration)

The repository scaffold runs without tenant connectivity. The following are required only when live integration is wired in a future release:

- Microsoft Entra ID tenant with Copilot Studio enabled.
- For Microsoft Entra Agent ID governance review, users assigned a Microsoft Agent 365 or Microsoft 365 E7 license; additional Entra licenses may be required for Conditional Access, ID Protection, ID Governance, or Global Secure Access features used by live integration.
- Microsoft Entra Agent ID feature enabled in the tenant.
- Entra app registration with Microsoft Graph `Policy.Read.All` as the least-privileged read permission for `/policies/crossTenantAccessPolicy/partners`; use `Policy.ReadWrite.CrossTenantAccess` only for write scenarios.
- Admin consent and a compatible delegated role for cross-tenant access policy reads, such as Security Reader, Global Reader, Global Secure Access Administrator, Teams Administrator, or Security Administrator.
- Read access to Copilot Studio channel, authentication, and organization sharing settings for target environments.
- Network egress to approved MCP server URLs; required API key or OAuth endpoints for the selected authentication method; and identity-provider discovery endpoints if OAuth 2.0 dynamic discovery is used.

## Roles (for live integration)

Use canonical Microsoft Entra role names and least privilege:

- Global Administrator (only for initial tenant or app setup when a lesser role cannot complete the action).
- Security Reader or Global Reader (read-only cross-tenant access policy review).
- Agent ID Administrator or Agent ID Developer (Agent ID identity work, depending on duty separation).
- AI Administrator or AI Reader (Microsoft 365 Copilot and AI service configuration review).
- Compliance Administrator (evidence retention coordination).

## Repository

- The shared module path `scripts/common/` is expected at the repository root and is referenced by the deployment and export scripts.
