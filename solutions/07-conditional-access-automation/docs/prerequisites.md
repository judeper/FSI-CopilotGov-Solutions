# Prerequisites

## Dependency

Complete `05-dlp-policy-governance` before deploying this solution. Conditional Access should reinforce, not replace, the data-governance protections applied to Copilot content.

## Licensing

- Azure AD P1 minimum for Conditional Access creation and enforcement.
- Azure AD P2 for risk-based policies and Identity Protection signals.
- Microsoft 365 E3 or E5 with the required Copilot entitlement for app targeting and user assignment.

## Required roles

- Conditional Access Administrator or Global Administrator for policy creation and modification.
- Security Reader for monitoring, evidence review, and sign-in log analysis.
- Optional approver roles for exception workflows, such as Information Security Manager or Chief Compliance Officer.

## PowerShell and modules

- PowerShell 7.0 or later.
- `Microsoft.Graph` for Graph authentication and Conditional Access operations.
- `MSAL.PS` or `Az.Accounts` if your automation standard uses token-based access outside the Graph SDK.

Example installation commands:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module MSAL.PS -Scope CurrentUser
```

## Graph API permissions

Minimum delegated or application permissions should be approved according to the task:

- `Policy.Read.All` for monitoring and evidence collection.
- `Policy.ReadWrite.ConditionalAccess` for deployment and policy updates.

Grant admin consent where required before automation runs in production.

## Environment preparation

- Verify the Copilot app IDs in `config\default-config.json`.
- Define tenant-specific named locations before enabling recommended or regulated policies.
- Confirm a protected output path for the baseline and exception register.
- Align environment variables to the `fsi_ev_caa_{setting}` naming convention if deployment automation uses centralized configuration.
