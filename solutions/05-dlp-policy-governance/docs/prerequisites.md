# Prerequisites

## Licensing

- The sensitivity-label file and email blocking capability for the Microsoft 365 Copilot and Copilot Chat policy location requires Microsoft 365 E5, the Microsoft Purview suite, Microsoft 365 E5/F5 Information Protection and Governance, or Office 365 E5.
- Sensitive-information-type prompt blocking and external web-search grounding restriction are available to all Microsoft 365 Copilot and Copilot Chat users.
- Microsoft 365 Copilot licensing for the users and Copilot experiences being reviewed.
- Power Automate Premium if the exception approval workflow is deployed in production.

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

For least-privilege lab inspection, use View-Only DLP Compliance Management for `Get-DlpCompliancePolicy` and `Get-DlpComplianceRule`, with Global Reader or Security Reader for read-only portal verification. These read-only roles are not sufficient for Copilot DLP policy create/edit.

Power Automate deployment can also require a Power Platform environment admin or flow owner depending on tenant design.

## Dependency

- `03-sensitivity-label-auditor` must be completed before DLP baseline approval so the Copilot label inventory is current.

## PowerShell modules

Install the required modules in PowerShell 7:

```powershell
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module Microsoft.Graph -Scope CurrentUser
```

## Graph API permissions

Connect to Microsoft Graph with delegated permissions that allow sensitivity-label metadata review:

- `InformationProtectionPolicy.Read` — returns sensitivity-label policy metadata
- `Policy.Read.All` — returns Entra ID policy metadata

> **Note:** Microsoft Graph does not expose Purview DLP policy metadata. DLP policies for the Copilot location are read via Security & Compliance PowerShell (`Get-DlpCompliancePolicy` / `Get-DlpComplianceRule`).

## Service connections

The solution expects read-only access to:

- Exchange Online and Security and Compliance PowerShell for Purview DLP policy metadata (`Get-DlpCompliancePolicy`, `Get-DlpComplianceRule`)
- Microsoft Graph for sensitivity-label and Entra ID policy metadata
- Power Automate connections for the exception approval workflow when deployed

## Operational prerequisites

- A selected governance tier: `baseline`, `recommended`, or `regulated`
- A defined evidence retention location for exported JSON and hash files
- A documented approver list for exception routing
- A notification destination for drift alerts and summary reporting
