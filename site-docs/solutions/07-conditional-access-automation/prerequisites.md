# Prerequisites

## Dependency

Complete `05-dlp-policy-governance` before deploying this solution. Conditional Access should reinforce, not replace, the data-governance protections applied to Copilot content.

## Licensing

- Microsoft Entra ID P1 minimum for Conditional Access creation and enforcement.
- Microsoft Entra ID P2 for risk-based policies and Microsoft Entra ID Protection signals.
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

> **Security note:** These permissions are tenant-wide. `Policy.Read.All` grants read access to *all* Conditional Access policies in the tenant, not just Copilot-targeting ones. `Policy.ReadWrite.ConditionalAccess` grants write access to *all* Conditional Access policies. Restrict the service principal or delegated user to the minimum set of administrators required, and audit Graph API calls through Microsoft Entra sign-in and audit logs. Consider using Privileged Identity Management (PIM) to make these permissions just-in-time rather than standing.

Grant admin consent where required before automation runs in production.

## External module dependency

`Export-Evidence.ps1` imports `scripts\common\EvidenceExport.psm1` from the parent repository root (two levels above the solution directory). This shared module provides the `Export-SolutionEvidencePackage` and `Get-CopilotGovSha256` functions used to assemble and hash evidence packages. Ensure the parent repository structure is intact when running `Export-Evidence.ps1` outside the standard solution layout.

## Environment preparation

- Verify the Copilot app IDs in `config\default-config.json`.
- Define tenant-specific named locations before enabling recommended or regulated policies.
- Confirm a protected output path for the baseline and exception register.
- Align environment variables to the `fsi_ev_caa_{setting}` naming convention if deployment automation uses centralized configuration.
