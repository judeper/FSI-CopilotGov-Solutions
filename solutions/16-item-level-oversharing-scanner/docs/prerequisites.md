# Prerequisites

## Platform and Licensing

- SharePoint Advanced Management licensing is recommended for the intended production posture. If licensing is not available, document the limitation before enabling this solution.
- Microsoft 365 E5 Compliance, or an equivalent licensing combination that enables DSPM for AI investigations, should be available for the tenant.
- The target tenant should already have a defined Copilot pilot or rollout scope so item-level findings can be prioritized against real exposure risk.

## Upstream Dependency

Solution 02-oversharing-risk-assessment must complete a site-level assessment before solution 16 is deployed. The site-level findings are used to prioritize which sites warrant item-level scanning. The deployment script checks for upstream output to validate this dependency.

## Required Administrative Roles

At least one of the following roles should be assigned to the operator, depending on the task being performed:

- SharePoint Admin
- Compliance Admin
- Global Admin

For app-only authentication, the application registration requires `Sites.FullControl.All` permission in Microsoft Graph.

## Required PowerShell Modules

Install and approve the following modules on the execution host:

- `PnP.PowerShell` — Required for item-level permission enumeration via `Connect-PnPOnline`
- `Microsoft.Graph` — Required for Graph-based authentication and supplementary queries

Example installation command:

```powershell
Install-Module PnP.PowerShell, Microsoft.Graph -Scope CurrentUser
```

> **PnP.PowerShell v3.x note:** PnP.PowerShell 3.x requires PowerShell 7.4 or later and .NET 8.0. Organizations must register their own Microsoft Entra ID application (the multi-tenant PnP app was removed in September 2024). Azure Automation environments are limited to PnP.PowerShell 2.12.0 (PowerShell 7.2 only).

## API Permissions

When using app-only authentication with PnP PowerShell, the following Microsoft Graph API permissions are required:

- `Sites.FullControl.All` — Read and enumerate permissions on all site content
- `User.Read.All` — Resolve user identities in permission entries

When using delegated authentication, the operator must have site collection administrator access on target sites.

## Network and Service Access

The execution environment must be able to reach:

- SharePoint REST API endpoints
- Microsoft Graph API endpoints
- SharePoint admin center endpoints

If the environment uses proxy inspection or outbound restrictions, test PnP connectivity before the initial scan window.

## Operational Readiness

- Confirm evidence output storage exists and is approved for regulated records.
- Confirm scan windows and throttling expectations have been approved for large document library enumerations.
- Confirm that solution 02 site-level findings are available to guide scanning scope.
