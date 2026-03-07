# Prerequisites

## Microsoft 365 Requirements

- Microsoft 365 Copilot licenses for users whose Pages or Notebooks content is in scope
- SharePoint Online and Microsoft Teams enabled for the workloads under review
- Microsoft Purview retention and eDiscovery capabilities, typically E5 Compliance or an equivalent licensing bundle
- Microsoft Loop and Copilot Pages enabled in the tenant if those workloads are being assessed
- A governed repository for storing exported evidence and supporting review records

## Required Roles

- Compliance Administrator for control review and evidence oversight
- SharePoint Administrator to assess site configuration, sharing controls, and storage locations
- eDiscovery Administrator to evaluate search scope and hold procedures
- Records Management or Information Governance lead to review preservation expectations
- Power Platform administrator if Power Automate review workflows will be enabled

## API Permissions

The monitoring approach assumes access to supporting inventory and policy metadata. Required permissions include:

- `Sites.Read.All` for SharePoint site and notebook location inventory
- `InformationProtectionPolicy.Read` for retention and label policy inspection
- Message Center or release-note access for platform update monitoring

If application authentication is used, store the client secret in an approved secret store and rotate it according to enterprise policy.

## eDiscovery Assessment Access

- eDiscovery Admin access is required to assess discovery coverage for Pages, Loop, and notebook content.
- Investigations teams should be able to validate whether Loop-backed Pages content appears in case searches and legal hold workflows.
- Where discovery coverage is incomplete, the team must document the manual export or collection process used instead.

## Dependencies

- `06-audit-trail-manager` must be deployed before this solution is considered ready for production use.
- Baseline retention and audit evidence should already be assessed through the dependency solution.
- If the dependency solution identifies unresolved audit capture issues, address those before relying on this gap register for examiner-facing evidence.

## Governance and Approval Requirements

- Legal and compliance sign-off is required before registering formal preservation exceptions.
- The organization should identify a named owner for each gap, compensating control, and quarterly review task.
- Human review is mandatory before any documented gap is marked mitigated or closed.
