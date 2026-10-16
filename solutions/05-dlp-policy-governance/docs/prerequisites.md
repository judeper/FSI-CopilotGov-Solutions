# Prerequisites

## Licensing

- For Copilot DLP, prompt safeguards are available to users of Microsoft 365 Copilot and Copilot Chat; restricting Copilot from processing files and emails requires an eligible Microsoft 365 E5, Office 365 E5, or Microsoft Purview suite plan
- Confirm entitlement for the Copilot experiences being reviewed; do not require a Microsoft 365 Copilot add-on solely for Copilot Chat prompt safeguards
- Power Automate licensing for the connectors used by the exception workflow; the standard Approvals connector does not itself require Premium. Confirm additional licensing if the design uses premium connectors.

Sources: [Microsoft Purview service description](https://learn.microsoft.com/office365/servicedescriptions/microsoft-365-service-descriptions/microsoft-365-tenantlevel-services-licensing-guidance/microsoft-purview-service-description#microsoft-purview-data-loss-prevention-dlp-for-microsoft-copilot) and [Power Automate approvals](https://learn.microsoft.com/power-automate/get-started-approvals).

## Roles

Accounts that create or edit DLP policies to safeguard Microsoft 365 Copilot and Copilot Chat should use one of the current Microsoft Learn roles or role groups:

- Entra AI Admin
- Purview Data Security AI Admin
- Purview Data Security AI Admins
- Purview Compliance Administrator
- Purview Compliance Data Administrator
- Purview Information Protection
- Purview Information Protection Admin
- Purview Security Administrator
- Entra Global Admin

For least-privilege operations, keep Security Reader-style access limited to read-only review and confirm tenant-tested read permissions before using it for evidence review.

Power Automate deployment can also require a Power Platform environment admin or flow owner depending on tenant design.

Approvals require a Dataverse database. In a non-default environment, the first approval flow's runner needs an environment administrator role for automatic database provisioning; later approval-flow authors do not need that elevated role. See [approvals prerequisites](https://learn.microsoft.com/power-automate/get-started-approvals#prerequisites).

## Dependency

- `03-sensitivity-label-auditor` must be completed before DLP baseline approval so the Copilot label inventory is current.

## PowerShell modules

The repository scripts run locally in PowerShell 7 without service connections. For optional tenant-bound collection, install the modules:

```powershell
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module Microsoft.Graph -Scope CurrentUser
```

## Graph API permissions

Connect to Microsoft Graph with delegated permissions that allow sensitivity-label metadata review:

- `InformationProtectionPolicy.Read` — returns sensitivity-label policy metadata
- `Policy.Read.All` — returns Entra ID policy metadata

> **Note:** These Graph scopes do not return Purview DLP policy metadata. DLP policies for the Copilot location are read via Security & Compliance PowerShell (`Get-DlpCompliancePolicy` / `Get-DlpComplianceRule`). `InformationProtectionPolicy.Read` is delegated access on behalf of the signed-in user, not an organization-wide application permission. See the [Graph permissions reference](https://learn.microsoft.com/graph/permissions-reference#informationprotectionpolicyread).

## Service connections

Optional tenant-bound collection uses read-only access to:

- Security & Compliance PowerShell for Purview DLP policy metadata (`Get-DlpCompliancePolicy`, `Get-DlpComplianceRule`), connected with `Connect-IPPSSession` and appropriate RBAC permissions; a separate Exchange Online session is not required
- Microsoft Graph for sensitivity-label and Entra ID policy metadata
- Power Automate connections for the exception approval workflow when deployed

See [Connect to Security & Compliance PowerShell](https://learn.microsoft.com/powershell/exchange/connect-to-scc-powershell) and the [Copilot DLP permissions](https://learn.microsoft.com/purview/dlp-microsoft365-copilot-location-learn-about#permissions). Prefer the least-privileged supported role for the operation.

## Operational prerequisites

- A selected governance tier: `baseline`, `recommended`, or `regulated`
- A defined evidence retention location for exported JSON and hash files
- A documented approver list for exception routing
- A notification destination for drift alerts and summary reporting
