# Prerequisites

## Administrative Roles

The deployment team should have access to the following roles or equivalent delegated permissions:

- Microsoft 365 Global Administrator, or a delegated model that includes `Policy.ReadWrite.FeatureRollout`
- Teams Administrator for Teams feature and policy review
- Power Platform Administrator for Power Apps and Power Automate Copilot settings
- Dataverse environment administration or maker rights in the target environment used for evidence storage

## Microsoft Graph Permissions

The solution expects access to Microsoft Graph scopes that support rollout policy and directory inspection. At minimum, validate:

- `Policy.Read.All`
- `Policy.ReadWrite.FeatureRollout`
- `Directory.Read.All`
- `Reports.Read.All`

If a delegated access model is used, confirm that tenant consent has been granted where required.

## Supported Administrative Surfaces

FMC assumes access to the following sources:

- Microsoft 365 Admin Center feature and app policy settings
- Microsoft Graph beta endpoint `/policies/featureRolloutPolicies`
- Teams Admin Center policy views or exports for Copilot-related settings
- Power Platform Admin API or administrative exports for Copilot in Power Apps and Power Automate

## Platform and Tooling Requirements

- PowerShell 7 or later
- Access to the shared modules in `..\..\scripts\common\`
- Access to repository contract files under `..\..\data\`
- Network access to Microsoft Graph and the administrative portals referenced by the operating model

## Dataverse Capacity

Minimum guidance for the Dataverse environment:

- baseline or recommended tier: at least 256 MB available for baseline, findings, and evidence metadata
- regulated tier: plan for 512 MB or more if 365-day retention, hourly monitoring, and historical evidence storage are enabled

Dataverse tables used by FMC:

- `fsi_cg_fmc_baseline`
- `fsi_cg_fmc_finding`
- `fsi_cg_fmc_evidence`

## Operational Prerequisites

- Approved rollout ring definitions for Preview Ring, Early Adopters, General Availability, and Restricted
- Named operations owner for drift monitoring
- Named compliance or supervisory approver for regulated ring promotions
- Documented escalation path for unexpected Copilot feature activation

## Recommended Readiness Checks

- Confirm the tenant is licensed for the Copilot workloads being tracked.
- Confirm a non-production tenant or pilot cohort is available for first deployment.
- Confirm Teams and Power Platform policy exports can be generated on demand if direct API writes are not approved.
- Confirm evidence retention and archival destination before the first export.
