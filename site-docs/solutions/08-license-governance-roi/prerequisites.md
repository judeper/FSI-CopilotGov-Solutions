# Prerequisites

## Microsoft 365 Licensing

- Copilot for Microsoft 365 licenses must be available for the users or cohorts included in the governance review.
- Viva Insights licenses are required if the customer expects the ROI scorecard to include Viva-based impact measurements.
- Power BI Pro or Power BI Premium Per User is required for report publishing, workspace collaboration, and scheduled refresh.

## Required Microsoft Graph Permissions

Grant tenant-admin consent for the following Graph application permissions:

- `Reports.Read.All`
- `Directory.Read.All`
- `User.Read.All`

These permissions support user inventory, Copilot usage reporting, and license inventory planning. They should be assigned only to approved automation identities.

## PowerShell and Module Requirements

- PowerShell 7.x
- `Microsoft.Graph.Authentication`
- `Microsoft.Graph.Users`
- `Microsoft.Graph.Reports`
- `Pester` 5.x for local validation
- Repository shared modules in `..\..\scripts\common\`

## Platform Dependencies

- Access to the repository root shared modules:
  - `EvidenceExport.psm1`
  - `IntegrationConfig.psm1`
  - `GraphAuth.psm1`
  - `DataverseHelpers.psm1`
- A customer-approved output path for deployment manifests, monitoring snapshots, and evidence exports
- Dependency data from solution `11-risk-tiered-rollout` if protected users must be handled differently

## Network Requirements

Allow outbound HTTPS connectivity to:

- `login.microsoftonline.com`
- `graph.microsoft.com`
- `api.powerbi.com`
- `*.analysis.windows.net`

If a curated Viva Insights extract or internal finance feed is used, confirm connectivity to the approved storage location or gateway.

## Operational Readiness

- Defined review owner for inactive-seat and cost-reallocation decisions
- Agreed reporting cadence for baseline, recommended, or regulated operation
- Approved retention policy for evidence packages and Dataverse records
- Documented cost-recovery assumptions if annualized recoverable spend will be shown in management reporting
