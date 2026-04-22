# Prerequisites — SharePoint Permissions Drift Detection

## Platform and Licensing

| Requirement | Detail |
|-------------|--------|
| Microsoft 365 tenant | E5 or E5 Compliance license for target users |
| SharePoint Online | Included with Microsoft 365; Advanced Management license recommended for large tenants |
| Power Automate | Per-user or per-flow license for approval-gate workflows |
| Azure Automation (optional) | For scheduled drift scan execution |

## Required Administrative Roles

| Role | Purpose |
|------|---------|
| SharePoint Administrator | Required for baseline capture and drift scan across all sites |
| Global Reader or Security Reader | Sufficient for read-only drift detection (no reversion) |
| Exchange Online Administrator | Required if using Graph API mail notifications |
| Compliance Administrator | Recommended for evidence export review and approval-gate oversight |

## Required PowerShell Modules

| Module | Minimum Version | Purpose |
|--------|----------------|---------|
| `PnP.PowerShell` | 2.3.0 | SharePoint Online site and permission enumeration |
| `Microsoft.Graph` | 2.0.0 | Alert notifications and user/group resolution |
| `Pester` | 5.0.0 | Solution validation tests |

Install required modules:

```powershell
Install-Module -Name PnP.PowerShell -MinimumVersion 2.3.0 -Scope CurrentUser
Install-Module -Name Microsoft.Graph -MinimumVersion 2.0.0 -Scope CurrentUser
Install-Module -Name Pester -MinimumVersion 5.0.0 -Scope CurrentUser
```

> **PnP.PowerShell v3.x note:** PnP.PowerShell 3.x requires PowerShell 7.4 or later and .NET 8.0. Organizations must register their own Microsoft Entra ID application (the multi-tenant PnP app was removed in September 2024). Azure Automation environments are limited to PnP.PowerShell 2.12.0 (PowerShell 7.2 only).

## Application Registration

For unattended (service account) operation, register an Azure AD application with:

| Permission | Type | Purpose |
|------------|------|---------|
| `Sites.Read.All` | Application | Read site permissions for baseline and drift scan |
| `Sites.FullControl.All` | Application | Required only if auto-reversion is enabled |
| `Mail.Send` | Application | Send drift alert and approval request emails |
| `User.Read.All` | Application | Resolve user and group identities |

> **Note:** Use `Sites.Read.All` for detect-only mode. Elevate to `Sites.FullControl.All` only when auto-reversion is explicitly enabled and approved by your security team.

## Upstream Dependency

This solution builds on [Solution 02 — Oversharing Risk Assessment](../02-oversharing-risk-assessment/). Verify that Solution 02 has been deployed or reviewed before proceeding.

The Solution 02 site inventory output provides context for risk scoring. If Solution 02 output is not available, Solution 17 operates independently but without oversharing risk context.

## Network and Service Access

| Endpoint | Protocol | Purpose |
|----------|----------|---------|
| `*.sharepoint.com` | HTTPS 443 | SharePoint Online API access |
| `graph.microsoft.com` | HTTPS 443 | Microsoft Graph API for notifications |
| `login.microsoftonline.com` | HTTPS 443 | Azure AD authentication |

## Operational Readiness

- [ ] Confirm network access to SharePoint Online and Microsoft Graph endpoints
- [ ] Validate service account credentials or application registration
- [ ] Test PnP PowerShell connectivity to a sample site
- [ ] Verify mail flow for alert notifications
- [ ] Confirm baseline output directory exists and is access-controlled
