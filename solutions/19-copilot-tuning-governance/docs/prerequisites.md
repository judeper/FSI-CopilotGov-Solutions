# Prerequisites

## Platform and Licensing

- Microsoft 365 Copilot Tuning is an early access preview capability with limited customer availability. During public preview, only tenants with at least 5,000 Microsoft 365 Copilot licenses are eligible, and Copilot Tuning settings must be visible in the Microsoft 365 admin center before tenant-specific governance decisions proceed.
- Microsoft 365 E5 or equivalent licensing should be available for the tenant to support compliance and governance features.
- The target tenant should already have a defined Copilot rollout scope so tuning governance can be aligned with active deployment.

## Required Administrative Roles

At least one of the following roles should be assigned to the operator, depending on the task being performed:

- AI Administrator for Microsoft 365 Copilot, AI-related enterprise services, and agent administration tasks
- Compliance Administrator for evidence review and regulatory alignment tasks
- Global Administrator only for exceptional tasks that require broader tenant privileges

For tuning governance management, AI Administrator is the recommended least-privilege role for Copilot and agent administration. Global Administrator should be reserved for scenarios that still require high-privilege tenant administration.

## Model Risk Management Stakeholders

The following stakeholders should be identified before deploying tuning governance:

- **Data Owner**: Responsible for confirming source data classification and appropriateness for tuning
- **Model Risk Officer**: Responsible for assessing tuning risk against institutional model risk management policy
- **Compliance Officer**: Responsible for confirming regulatory alignment and evidence requirements
- **Tuned Model Owner**: Responsible for ongoing lifecycle management of each tuned agent

## Required PowerShell Modules

Install and approve the following modules on the execution host:

- `Microsoft.Graph`

Example installation command:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

## Network and Service Access

The execution environment must be able to reach:

- Microsoft 365 Admin Center (`https://admin.microsoft.com`)
- Microsoft Graph API endpoints (`https://graph.microsoft.com`)
- Entra ID authentication endpoints (`https://login.microsoftonline.com`)

If the environment uses proxy inspection or outbound restrictions, test connectivity before the initial deployment window.

## Operational Readiness

- Confirm evidence output storage exists and is approved for regulated records.
- Confirm model risk management policy is documented and approved by compliance stakeholders.
- Confirm tuning approval workflow stakeholders are identified and available.
- Confirm governance tier selection has been reviewed and approved.
