# Prerequisites

## Tooling

- PowerShell 7.2 or later.
- Pester 5.x for running the smoke tests.

## Microsoft 365 / Entra (for future live integration)

The repository scaffold runs without tenant connectivity. The following are required only when live integration is wired in a future release:

- Microsoft Entra ID tenant with Copilot Studio enabled.
- Microsoft Agent 365 is generally available (since May 1, 2026) and licensed per user for the commercial cloud. Microsoft 365 E5 is the recommended base; base agent registry inventory is broadly available, while advanced Agent 365 governance requires a qualifying Microsoft Agent 365 license or Microsoft 365 E7 (which bundles Agent 365). Microsoft currently describes the Agent 365 Package Management Graph API as preview even though read endpoints are documented under v1.0.
- Microsoft Entra Agent ID is in preview. Conditional Access review of agent identities requires Microsoft Entra ID P1, and ID Protection risk review requires Microsoft Entra ID P2 (during preview); ID Governance and network controls (for example Global Secure Access) may require additional Entra licenses.
- Microsoft Entra Agent ID preview enabled in the tenant for agent identity review.
- Entra app registration with Microsoft Graph `Policy.Read.All` as the least-privileged read permission for `/policies/crossTenantAccessPolicy/partners`; `Policy.ReadWrite.CrossTenantAccess` applies only to write scenarios, which this detective solution does not perform.
- For read-only Agent 365 registry inventory via the Package Management API, `CopilotPackages.Read.All` is the least-privileged Microsoft Graph scope and a Microsoft Agent 365 license is required.
- Admin consent and a compatible delegated role for cross-tenant access policy reads, such as Security Reader or Global Reader (least privilege); Security Administrator or Global Secure Access Administrator is needed only for write scenarios, which are out of scope here.
- Read access to Copilot Studio channel, authentication, organization sharing, and multitenant mode (preview) settings for target environments.
- Network egress to approved MCP server URLs; required API key or OAuth endpoints for the selected authentication method; and identity-provider discovery endpoints if OAuth 2.0 dynamic discovery is used.

## Roles (for live integration)

Use canonical Microsoft Entra role names and least privilege:

- Global Administrator (only for initial tenant or app setup when a lesser role cannot complete the action).
- Security Reader or Global Reader (read-only cross-tenant access policy review).
- AI Reader for read-only Agent 365 registry inventory; use time-bound AI Administrator or Global Administrator only when the preview Package Management API read is required.
- Global Reader or Security Reader for read-only Microsoft Entra Agent ID owner/sponsor, permission, Conditional Access, and audit posture review. Agent ID Administrator/Developer are reserved for later configuration work.
- AI Administrator or AI Reader (Microsoft 365 Copilot and AI service configuration review).
- Compliance Administrator (evidence retention coordination).

## Repository

- The shared module path `scripts/common/` is expected at the repository root and is referenced by the deployment and export scripts.
