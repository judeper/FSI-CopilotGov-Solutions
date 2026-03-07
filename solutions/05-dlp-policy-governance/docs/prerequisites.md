# Prerequisites

## Licensing

- Microsoft 365 E5 or E5 Compliance for Purview DLP capabilities used to monitor Copilot workloads
- Microsoft 365 Copilot licensing for the users and workloads being reviewed
- Power Automate Premium if the exception approval workflow is deployed in production

## Roles

At least one of the following roles should be assigned to the operators managing this solution:

- Compliance Administrator
- Security Reader
- DLP Compliance Management

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

Connect to Microsoft Graph with delegated permissions that allow policy review:

- `InformationProtectionPolicy.Read`
- `Policy.Read.All`

## Service connections

The solution expects read-only access to:

- Exchange Online and Security and Compliance PowerShell for Purview DLP policy metadata
- Microsoft Graph for policy and label metadata
- Power Automate connections for the exception approval workflow when deployed

## Operational prerequisites

- A selected governance tier: `baseline`, `recommended`, or `regulated`
- A defined evidence retention location for exported JSON and hash files
- A documented approver list for exception routing
- A notification destination for drift alerts and summary reporting
