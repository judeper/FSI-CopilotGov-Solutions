# Prerequisites

## Microsoft 365 Requirements

- OneDrive license and an active OneDrive site for Copilot Pages; Microsoft 365 Copilot license for Copilot Notebooks
- SharePoint Online and Microsoft Teams enabled for the workloads under review
- Microsoft Purview retention and Microsoft Purview eDiscovery capabilities, typically E5 Compliance or an equivalent licensing bundle
- Microsoft Loop and Copilot Pages enabled in the tenant if those workloads are being assessed
- A governed repository for storing exported evidence and supporting review records

## Required Roles

- Compliance Administrator for control review and evidence oversight
- SharePoint Administrator to assess site configuration, sharing controls, and storage locations
- Microsoft Purview eDiscovery Administrator to evaluate search scope and hold procedures
- Records Management or Information Governance lead to review preservation expectations
- Power Platform administrator if Power Automate review workflows will be enabled

## API Permissions

The monitoring approach assumes future access to supporting inventory and policy metadata. Required permissions and administrative access include:

- `Sites.Read.All` for SharePoint site, SharePoint Embedded container, and notebook location inventory
- `InformationProtectionPolicy.Read` for delegated Microsoft Graph beta sensitivity-label lookup, or `InformationProtectionPolicy.Read.All` for application permissions if app-only sensitivity-label lookup is implemented
- Microsoft Purview portal or supported Purview PowerShell access for retention policy inventory and Microsoft Purview eDiscovery validation
- Message Center or release-note access for platform update monitoring

> **Note:** The current scripts use stub authentication logic and representative sample data. The permissions listed above are reserved for future authenticated monitoring functionality. Until that functionality is implemented, operators do not need to provision these permissions or configure a client secret. When authenticated monitoring is enabled, store the client secret in an approved secret store and rotate it according to enterprise policy.

## Microsoft Purview eDiscovery Assessment Access

- Microsoft Purview eDiscovery Admin access is required to assess discovery coverage for Pages, Loop, and notebook content.
- Investigation teams should validate correct SharePoint Embedded container URLs, site scopes, and the documented full-text search limitations for `.page` and `.loop` files in review sets.
- Where case scope, legal hold, or review-set limitations require manual procedures, the team must document the export or collection process used instead.

## Dependencies

- `06-audit-trail-manager` must be deployed before this solution is considered ready for production use.
- Baseline retention and audit evidence should already be assessed through the dependency solution.
- If the dependency solution identifies unresolved audit capture issues, address those before relying on this gap register for examiner-facing evidence.

## Governance and Approval Requirements

- Legal and compliance sign-off is required before registering formal preservation exceptions.
- The organization should identify a named owner for each gap, compensating control, and quarterly review task.
- Human review is mandatory before any documented gap is marked mitigated or closed.
