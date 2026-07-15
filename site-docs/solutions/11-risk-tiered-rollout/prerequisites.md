# Prerequisites

## Required Dependency

- `01-copilot-readiness-scanner` must be deployed and must have run successfully before this solution is used.
- The readiness evidence package from solution 01 must be current enough to satisfy the configured freshness threshold.
- If the readiness artifact is stale or missing, rollout preparation should stop until the dependency is rerun.

## Licensing

- A qualifying Microsoft 365 base license (E3/E5, Business Standard/Premium, or Office 365 E3/E5) for the targeted users
- Microsoft 365 Copilot licenses sized for the intended wave plus rollback reserve
- The Microsoft Entra **Usage location** property is populated for targeted users before they are added to wave-based license-assignment groups
- Power Automate Premium licenses for approvers or service accounts that run approval workflows

## Microsoft 365 Copilot SKU Discovery

The Microsoft 365 Copilot SKU must be discovered per tenant rather than hardcoded:

- Read the tenant catalog with `GET /subscribedSkus` and match on `skuPartNumber` (`Microsoft_365_Copilot`; some tenants provisioned earlier may present the legacy `M365_Copilot` string ID).
- Use the tenant-specific `skuId` **GUID** returned by that call for `assignLicense`/`removeLicenses`. Do not hardcode a SKU GUID — the product **display name** ("Microsoft 365 Copilot"), the `skuPartNumber`, and the `skuId` are distinct values, and only the tenant lists the authoritative `skuId`.
- Confirm seat availability from the same response: available seats are `prepaidUnits.enabled` minus `consumedUnits`. This repository does not verify live seat counts; treat seat availability as a manual prerequisite.

## Permissions

The rollout automation design assumes the following least-privileged Microsoft Graph permissions and role assignments are approved for the service principal or admin context used during implementation:

- `LicenseAssignment.ReadWrite.All` for license assignment. Use group-based assignment (`POST /groups/{id}/assignLicense`) for wave groups or direct user assignment (`POST /users/{id | userPrincipalName}/assignLicense`) only when the implementation selects direct assignment.
- `LicenseAssignment.Read.All` for read-only tenant SKU and license discovery (`GET /subscribedSkus`, and reading a user's or group's current `assignedLicenses`) so the tenant `skuId` and current assignment state can be captured before any change.
- Higher-privileged permissions such as `Directory.ReadWrite.All`, `Group.ReadWrite.All`, or `User.ReadWrite.All` are reserved for implementations that explicitly require them.
- Delegated group-assignment operators hold Directory Writers, Groups Administrator, License Administrator, User Administrator, or a custom role with `microsoft.directory/groups/assignLicense`.
- Delegated direct user-assignment operators hold Directory Writers, License Administrator, User Administrator, or a custom role with `microsoft.directory/users/assignLicense`.
- `Directory.Read.All` for broader read-only directory lookups when implementation needs additional inventory or reference data.

## Platform Requirements

- PowerShell 7 for local script execution and syntax validation
- Dataverse capacity for rollout, findings, and evidence tables
- Power BI workspace access for the rollout-health dashboard model
- Power Platform environment access for deploying documentation-first flows and tables

## Local Script Module Dependencies

- `scripts\common\IntegrationConfig.psm1` from the repository shared module folder
- `scripts\common\EvidenceExport.psm1` from the repository shared module folder
- `solutions\11-risk-tiered-rollout\scripts\RolloutConfig.psm1` for local tier-configuration loading

## Governance and Operating Model Requirements

- Change Advisory Board process for gate approvals, especially for regulated Wave 3 activity
- Named business owner for Wave 0 and Wave 1 approval decisions
- Compliance, legal, HR, and IT operations contacts for Tier 2 and Tier 3 validation
- Approved issue-management process for rollout blockers and rollback events

## Recommended Supporting Inputs

- Current user inventory with department and role metadata
- Help-desk support roster for pilot and expansion windows
- Change ticket or CAB identifiers for the target rollout period
