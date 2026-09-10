# Prerequisites

## Required Solution Dependency

- Solution `09-feature-management-controller` must already be deployed so approved connectors and plugins can be tied to rollout gating and exception handling.

## Required Roles and Access

| Requirement | Why it is needed |
|-------------|------------------|
| Power Platform Administrator role | Required to enumerate connectors, review DLP posture, and validate environment level connector configuration. |
| AI Administrator (preferred); Global Administrator only where explicitly required | Required for Microsoft 365 admin center agent and plugin governance actions that affect Microsoft 365 Copilot extensibility. |
| Dataverse System Administrator | Required to import the Dataverse solution, create tables, and manage baseline, finding, and evidence records. |
| Power Automate Premium | Required to run scheduled inventory collection and approval routing flows. |
| Security team reviewer account | Required to receive and action approval workflow tasks for connector and plugin requests. |

## Platform Requirements

- PowerShell 7 for local execution of deployment, monitoring, and evidence export scripts
- Access to the target Power Platform environment ID
- Access to the target Dataverse environment URL
- Access to Entra app registration and admin-consent records approved by the tenant security team for custom connector or API authentication dependencies
- Access to Microsoft 365 admin center Agent Registry and agent details metadata; if programmatic access is approved, document that Microsoft Graph Agent Registry APIs are preview and work with the AI Admin role
- Read access to **Agents > Settings > Allowed agent types**, **Copilot connectors > Your connections**, and **Agents > Tools** for manual Control 2.16 reconciliation
- Approved test identities representing an allowed user and an unapproved user, plus a source-system record the allowed user is not permitted to retrieve

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
- approved tenant-wide publisher-category posture and its effect on agents and apps
- connector-specific allowed-user scope, including which connectors remain at **No users**
- staged rollout groups for approved connector pilots
- acceptable user-authentication and source-system permission test procedure
- separate MCP server availability, blocking, and request posture under **Agents > Tools**
