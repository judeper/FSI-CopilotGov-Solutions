# Prerequisites

## Required Solution Dependency

- Solution `09-feature-management-controller` must already be deployed so approved connectors and plugins can be tied to rollout gating and exception handling.

## Required Roles and Access

| Requirement | Why it is needed |
|-------------|------------------|
| Power Platform Administrator role | Required to enumerate connectors, review DLP posture, and validate environment level connector configuration. |
| AI Administrator (required for Microsoft 365 Copilot connector management); AI Reader for read-only agent-registry review; Global Administrator only where explicitly required | Required for Microsoft 365 admin center connector, agent, and plugin governance actions that affect Microsoft 365 Copilot extensibility. Managing Microsoft 365 Copilot connectors requires the AI Administrator role; viewing the agent registry inventory needs only the least-privilege AI Reader role. |
| AI Administrator or Global Administrator plus `CopilotPackages.Read.All` | Required only when the read-only lab validates the preview Microsoft Agent 365 Package Management API. The API also requires a Microsoft Agent 365 license; write permissions and operations remain out of scope. |
| Dataverse System Administrator | Required to import the Dataverse solution, create tables, and manage baseline, finding, and evidence records. |
| Power Automate Premium | Required to run scheduled inventory collection and approval routing flows. |
| Security team reviewer account | Required to receive and action approval workflow tasks for connector and plugin requests. |

## Platform Requirements

- PowerShell 7 for local execution of deployment, monitoring, and evidence export scripts
- Access to the target Power Platform environment ID
- Access to the target Dataverse environment URL
- Access to Entra app registration and admin-consent records approved by the tenant security team for custom connector or API authentication dependencies
- Access to the Microsoft Agent 365 agent registry in the Microsoft 365 admin center (Agents > All agents > Registry) for read-only agent and plugin inventory review; the registry supports CSV export and is viewable with the least-privilege AI Reader role. Optional preview API validation uses `GET /v1.0/copilot/admin/catalog/packages`, `CopilotPackages.Read.All`, a Microsoft Agent 365 license, and AI Administrator or Global Administrator. Agent identities are managed in Microsoft Entra Agent ID, which is out of scope for this solution.

## Shared Modules Used

- `scripts\common\IntegrationConfig.psm1`
- `scripts\common\DataverseHelpers.psm1`
- `scripts\common\TeamsNotification.psm1`
- `scripts\common\EvidenceExport.psm1`

## Governance Preparation

Before deployment, confirm the following decisions are documented:

- blocked connector IDs for the tenant and regulatory context
- approved data-flow boundaries for Copilot extensibility use cases
- review mailbox or distribution group for security and CISO or DLP approval tasks
- target governance tier: `baseline`, `recommended`, or `regulated`
