# Prerequisites

## Required Solution Dependency

- Solution `09-feature-management-controller` must already be deployed so approved connectors and plugins can be tied to rollout gating and exception handling.

## Required Roles and Access

| Requirement | Why it is needed |
|-------------|------------------|
| Power Platform Administrator role | Required to enumerate connectors, review DLP posture, and validate environment level connector configuration. |
| Microsoft 365 Global Admin | Required for Teams app policy review and plugin deployment controls that affect Microsoft 365 Copilot extensibility. |
| Dataverse System Administrator | Required to import the Dataverse solution, create tables, and manage baseline, finding, and evidence records. |
| Power Automate Premium | Required to run scheduled inventory collection and approval routing flows. |
| Security team reviewer account | Required to receive and action approval workflow tasks for connector and plugin requests. |

## Platform Requirements

- PowerShell 7 for local execution of deployment, monitoring, and evidence export scripts
- Access to the target Power Platform environment ID
- Access to the target Dataverse environment URL
- Access to Microsoft Graph inventory permissions approved by the tenant security team

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
