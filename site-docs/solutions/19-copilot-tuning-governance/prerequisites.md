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

For read-only review, evidence verification, and lab validation tasks, use a read-only role such as **AI Reader** (read-only access to the Copilot control system) or **Global Reader** so operators can inspect Copilot Tuning availability settings and the Agent 365 tuned-agent inventory without changing tenant state.

## Cloud Availability and Data Residency

Per current Microsoft Learn guidance for the early access preview, evaluate the following before planning tuning governance:

- This solution covers Copilot Tuning during public preview only within its documented commercial-cloud availability.
- Copilot Tuning is **not enabled by default for tenants with Advanced Data Residency (ADR)** commitments during public preview. ADR tenants that want to use Copilot Tuning must formally waive ADR requirements through their Microsoft account team.
- Copilot Tuning follows Microsoft 365 data residency at the **macro region** level and respects EU Data Boundary commitments for EU-based tenants during public preview.
- **Multi-Geo** data residency commitments do not apply to Copilot Tuning during public preview.
- The authoritative inventory and lifecycle controls for tuned agents are provided in the **Agent 365 portal**; confirm read-only access for governance reviewers.

## Model Risk Management Stakeholders

The following stakeholders should be identified before deploying tuning governance:

- **Data Owner**: Responsible for confirming source data classification and appropriateness for tuning
- **Model Risk Officer**: Responsible for assessing tuning risk against institutional model risk management policy
- **Compliance Officer**: Responsible for confirming regulatory alignment and evidence requirements
- **Tuned Model Owner**: Responsible for ongoing lifecycle management of each tuned agent

## Required PowerShell Modules

The documentation-first scripts in this solution do not require additional PowerShell modules beyond built-in PowerShell capabilities. `Microsoft.Graph` is optional and forward-looking for future tenant-bound integrations that introduce supported Graph cmdlet usage.

Optional installation command for future live integrations:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

## Network and Service Access

For production tenant-bound integrations, the execution environment should be able to reach:

- Microsoft 365 Admin Center (`https://admin.microsoft.com`)
- Microsoft Graph API endpoints (`https://graph.microsoft.com`)
- Entra ID authentication endpoints (`https://login.microsoftonline.com`)

If the environment uses proxy inspection or outbound restrictions, test connectivity before the initial deployment window.

## Operational Readiness

- Confirm evidence output storage exists and is approved for regulated records.
- Confirm model risk management policy is documented and approved by compliance stakeholders.
- Confirm tuning approval workflow stakeholders are identified and available.
- Confirm governance tier selection has been reviewed and approved.
