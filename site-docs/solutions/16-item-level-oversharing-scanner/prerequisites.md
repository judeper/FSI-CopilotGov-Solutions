# Prerequisites

## Platform and Licensing

- Restricted Content Discovery (RCD) is the go-forward SharePoint discoverability control for Copilot governance review windows.
- Restricted SharePoint Search (RSS) is retiring; starting 2026-07-31, new enablement is blocked.
- RCD is discoverability-only: it doesn't change permissions, isn't a security boundary, and isn't supported for OneDrive sites.
- SharePoint Advanced Management prerequisites for US commercial tenants require a qualifying base subscription (Office 365 E3/E5/A5 or Microsoft 365 E1/E3/E5/A5) and at least one of: an assigned Microsoft 365 Copilot license, the SharePoint Advanced Management Plan 1 add-on (with SharePoint K/P1/P2), or Microsoft 365 E7.
- Microsoft Purview Data Security Posture Management (DSPM) licensing and permissions should be available for the tenant; if using DSPM for AI, document it as DSPM for AI (classic).
- The target tenant should already have a defined Copilot pilot or rollout scope so item-level findings can be prioritized against real exposure risk.

## Upstream Dependency

Solution 02-oversharing-risk-assessment must complete a site-level assessment before solution 16 is deployed. The site-level findings are used to prioritize which sites warrant item-level scanning. The deployment script checks for upstream output to validate this dependency.

## Required Administrative Roles

Use task-specific access rather than treating Microsoft 365 admin roles as interchangeable for SharePoint content access:

- For delegated item-level permission enumeration, the operator should be a site collection administrator on each target site.
- SharePoint Administrator or SharePoint Advanced Management Administrator roles are required for SharePoint Advanced Management and Restricted Content Discovery administration, but these roles don't automatically provide content access to every site or OneDrive.
- Use Compliance Administrator, Microsoft Purview Compliance Administrator, or DSPM roles for Purview/DSPM review and investigation tasks, not as substitutes for target-site content access.

## Required PowerShell Modules

Install and approve the following module on the execution host for the current scaffold:

- `PnP.PowerShell` — Required for tenant-specific item-level permission enumeration via `Connect-PnPOnline`

`Microsoft.Graph` is optional and implementation-dependent until tenant binding adds direct Graph cmdlet usage for supplementary queries.

Example installation command:

```powershell
Install-Module PnP.PowerShell -Scope CurrentUser
```

> **Runtime note:** Microsoft Learn documents Azure Automation support for PowerShell 7.4 runbooks. PnP.PowerShell module version behavior and app-registration compatibility should be documented in the project runbook and validated in lab before production rollout.

## API Permissions

When using Microsoft Graph to list `driveItem` permissions, use the documented least-privileged permission for the selected auth model:

- Delegated least privilege: `Files.Read`
- Application least privilege: `Files.Read.All`
- Higher privilege options: `Files.ReadWrite.All`, `Sites.Read.All`, `Sites.ReadWrite.All`

The `driveItem` list-permissions API returns all sharing permissions only to owners (including co-owners). Non-owner callers only receive permission entries that apply to the caller.

Use broader SharePoint/PnP or write permissions only when the approved implementation requires remediation or site administration, and document that API surface separately. If identity enrichment uses a separate endpoint, document and consent only the least-privileged permission required for that endpoint.

When using delegated authentication, the operator must have site collection administrator access on target sites.

## Network and Service Access

The execution environment must be able to reach:

- SharePoint REST API endpoints
- Microsoft Graph API endpoints, if optional Graph enrichment is enabled
- SharePoint admin center endpoints

If the environment uses proxy inspection or outbound restrictions, test PnP connectivity before the initial scan window.

## Operational Readiness

- Confirm evidence output storage exists and is approved for regulated records.
- Confirm scan windows and throttling expectations have been approved for large document library enumerations.
- Confirm that solution 02 site-level findings are available to guide scanning scope.
