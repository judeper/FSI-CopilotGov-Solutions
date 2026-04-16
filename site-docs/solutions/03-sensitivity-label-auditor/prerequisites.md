# Prerequisites

## Licensing

- Microsoft Purview Information Protection P2 license for auto-labeling scenarios
- Microsoft Purview Suite (formerly Microsoft 365 E5 Compliance) or equivalent for the broader compliance and evidence workflow

Baseline monitoring can begin before enforcement use cases are approved, but bulk labeling and advanced policy scenarios should not proceed until licensing is confirmed.

## Required Roles

Deployment and evidence operators should hold one of the following roles, or an approved combination that grants equivalent access:

- Compliance Administrator
- Security Administrator
- Global Administrator

Organizations may split duties between deployment, records, and audit teams, but at least one approved operator must be able to read label policy data and workload metadata.

## Graph API Permissions

The monitoring design assumes approved access to the following Microsoft Graph permissions:

- `InformationProtectionPolicy.Read`
- `Sites.Read.All`
- `Files.Read.All`
- `Mail.Read`

Additional permissions may be needed if the organization extends the solution to bulk label application or workflow automation.

## PowerShell and Modules

- PowerShell 7.x
- `Microsoft.Graph`
- `ExchangeOnlineManagement`
- `PnP.PowerShell`

The scripts are written as implementation-ready stubs and can be extended with tenant-approved authentication and Graph request logic.

## Upstream Solution Dependencies

The following solutions must be complete before solution 03 is considered ready for production monitoring:

- `01-copilot-readiness-scanner` completed
- `02-oversharing-risk-assessment` initial scan completed

Solution 01 provides rollout and workload context. Solution 02 provides oversharing findings that help prioritize unlabeled content in regulated stores.

## Governance and Taxonomy

- The sensitivity label taxonomy must be configured in the Microsoft Purview portal before the audit runs.
- The organization should confirm the FSI label hierarchy and expected business mappings before scanning begins.
- Priority sites, supervisory mailboxes, and regulated repositories should be identified before the first production scan.
