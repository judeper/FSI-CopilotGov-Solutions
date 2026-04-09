# Prerequisites

## Required Solution Dependencies

- Solution `09-feature-management-controller` must already be deployed so approved agents can be tied to rollout gating and exception handling.
- Solution `10-connector-plugin-governance` must already be deployed so agent connector dependencies can be cross-referenced during approval workflows.

## Required Roles and Access

| Requirement | Why it is needed |
|-------------|------------------|
| Microsoft 365 Global Admin or Teams Admin role | Required to manage agent request and approval workflows in the M365 Admin Center and review agent deployment policies. |
| Copilot Studio Environment Admin | Required to access the agent catalog, configure sharing restrictions, and review user-created agent deployments. |
| Dataverse System Administrator | Required to import the Dataverse solution, create tables, and manage baseline, finding, and evidence records. |
| Power Automate Premium | Required to run scheduled agent inventory collection and approval routing flows. |
| Security team reviewer account | Required to receive and action approval workflow tasks for agent deployment requests. |

## Platform Requirements

- PowerShell 7 for local execution of deployment, monitoring, and evidence export scripts
- Access to the target Dataverse environment URL
- Microsoft 365 tenant with Copilot licensing and agent management features enabled
- M365 Admin Center agent request and approval workflows enabled (if available in the tenant)
- Copilot Studio admin center access for sharing policy configuration review

## Network Requirements

- Access to Microsoft 365 admin APIs from the deployment environment
- Access to the Dataverse API endpoint for solution import and table management
- Access to Power Automate service endpoints for flow deployment and management

## Shared Modules Used

- `scripts\common\IntegrationConfig.psm1`
- `scripts\common\DataverseHelpers.psm1`
- `scripts\common\TeamsNotification.psm1`
- `scripts\common\EvidenceExport.psm1`

## Governance Preparation

Before deployment, confirm the following decisions are documented:

- agent risk categories and classification criteria for the tenant and regulatory context
- sharing policy controls including org-wide sharing restrictions and external sharing settings
- review mailbox or distribution group for security, business owner, and CISO approval tasks
- target governance tier: `baseline`, `recommended`, or `regulated`
- cross-reference requirements between agent approvals and connector/plugin governance (solution 10)
