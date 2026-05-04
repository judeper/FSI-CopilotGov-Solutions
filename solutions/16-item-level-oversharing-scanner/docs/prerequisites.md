# Prerequisites

## Platform and Licensing

- SharePoint Advanced Management licensing is recommended for the intended production posture. If licensing is not available, document the limitation before enabling this solution.
- Microsoft Purview Data Security Posture Management (DSPM) licensing and permissions should be available for the tenant; if using DSPM for AI, document it as DSPM for AI (classic).
- The target tenant should already have a defined Copilot pilot or rollout scope so item-level findings can be prioritized against real exposure risk.

## Upstream Dependency

Solution 02-oversharing-risk-assessment must complete a site-level assessment before solution 16 is deployed. The site-level findings are used to prioritize which sites warrant item-level scanning. The deployment script checks for upstream output to validate this dependency.

## Required Administrative Roles

Use task-specific access rather than treating Microsoft 365 admin roles as interchangeable for SharePoint content access:

- For delegated item-level permission enumeration, the operator should be a site collection administrator on each target site.
- A SharePoint Administrator or Global Administrator may grant or manage site access, but those roles do not automatically provide content access to every site or OneDrive.
- Use Compliance Administrator, Microsoft Purview Compliance Administrator, or DSPM roles for Purview/DSPM review and investigation tasks, not as substitutes for target-site content access.

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

When using Microsoft Graph to list `driveItem` permissions, select permissions documented for that endpoint. For read-only application enumeration, `Files.Read.All` is the least-privileged application permission; `Files.ReadWrite.All`, `Sites.Read.All`, and `Sites.ReadWrite.All` are higher-privileged options.

Use broader SharePoint/PnP or write permissions only when the approved implementation requires remediation or site administration, and document that API surface separately. If identity enrichment uses a separate endpoint, document and consent only the least-privileged permission required for that endpoint.

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
