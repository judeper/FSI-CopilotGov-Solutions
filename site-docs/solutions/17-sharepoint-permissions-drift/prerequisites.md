# Prerequisites — SharePoint Permissions Drift Detection

## Platform and Licensing

| Requirement | Detail |
|-------------|--------|
| Microsoft 365 tenant | E5 or E5 Compliance license for target users |
| SharePoint Online | Included with Microsoft 365; Advanced Management license recommended for large tenants |
| Power Automate | Per-user or per-flow license for approval-gate workflows |
| Azure Automation (optional) | For scheduled drift scan execution |

## Required Administrative Roles

| Role / Access | Purpose |
|---------------|---------|
| SharePoint Administrator or site owner | Required for baseline capture and drift scan across in-scope sites |
| Microsoft Graph application permissions | Required for complete read-only permission inventory; use `Files.Read.All` for drive item permissions and `Sites.Read.All` where site-wide inventory requires it |
| Mail sender mailbox and `Mail.Send` consent | Required if using Microsoft Graph mail notifications; scope the sender mailbox per institutional policy |
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

> **PnP.PowerShell v3.x note:** PnP.PowerShell 3.x requires PowerShell 7.4 or later and .NET 8.0. Organizations must register their own Microsoft Entra ID application (the multi-tenant PnP app was removed in September 2024). Azure Automation supports PowerShell 7.4 and Windows PowerShell 5.1; validate region, cloud, and selected `PnP.PowerShell` module compatibility before scheduling runbooks.

## Application Registration

For unattended (service account) operation, register a Microsoft Entra ID application with:

| Permission | Type | Purpose |
|------------|------|---------|
| `Files.Read.All` | Application | Read drive item permissions for detect-only inventory |
| `Sites.Read.All` | Application | Read site permissions where site-wide inventory requires it |
| `Sites.FullControl.All` | Application | Required only if auto-reversion is enabled |
| `Mail.Send` | Application | Send drift alert and approval request emails |
| `User.Read.All` | Application | Resolve user identities |
| `GroupMember.Read.All` / `Group.Read.All` or `Directory.Read.All` | Application | Resolve group identities and membership, depending on the queries used |

> **Note:** Use `Files.Read.All` and, where site-wide inventory requires it, `Sites.Read.All` for detect-only mode. Elevate to `Sites.FullControl.All` only when auto-reversion is explicitly enabled and approved by your security team.

## Upstream Dependency

This solution builds on [Solution 02 — Oversharing Risk Assessment](../02-oversharing-risk-assessment/index.md). Verify that Solution 02 has been deployed or reviewed before proceeding.

The Solution 02 site inventory output provides context for risk scoring. If Solution 02 output is not available, Solution 17 operates independently but without oversharing risk context.

## Network and Service Access

| Endpoint | Protocol | Purpose |
|----------|----------|---------|
| `*.sharepoint.com` | HTTPS 443 | SharePoint Online API access |
| `graph.microsoft.com` | HTTPS 443 | Microsoft Graph API for notifications |
| `login.microsoftonline.com` | HTTPS 443 | Microsoft Entra ID authentication |

## Operational Readiness

- [ ] Confirm network access to SharePoint Online and Microsoft Graph endpoints
- [ ] Validate service account credentials or application registration
- [ ] Test PnP PowerShell connectivity to a sample site
- [ ] Verify mail flow for alert notifications
- [ ] Confirm baseline output directory exists and is access-controlled
