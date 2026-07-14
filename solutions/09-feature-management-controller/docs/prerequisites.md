# Prerequisites

## Administrative Roles

The deployment team should have access to the following roles or equivalent delegated permissions:

- Microsoft 365 Global Administrator, AI Administrator, or equivalent delegated model for Microsoft 365 admin center Copilot settings. The **AI Administrator** role is the least-privilege option for managing Copilot Control System settings and reports without Global Administrator rights; it is a privileged role, so scope it with Microsoft Entra Privileged Identity Management (PIM) where possible.
- Teams Administrator for documented Teams meeting/event and calling policy review
- Power Platform Administrator for Power Apps Copilot settings and Power Automate tenant-level Copilot settings
- Dataverse environment administration or maker rights in the target environment used for evidence storage

## Microsoft Graph Permissions

FMC does not require Microsoft Graph feature-rollout permissions for Copilot feature management. The Microsoft Graph feature rollout policy resource is scoped to Microsoft Entra staged authentication rollout and is not used as a Copilot feature inventory source.

As of the last verification, Microsoft does not publish a Microsoft Graph API for managing Copilot feature or admin settings. Those controls are managed through the Microsoft 365 admin center (Copilot Control System), the Cloud Policy service (Microsoft 365 Apps admin center), Microsoft Teams PowerShell, the Microsoft Purview portal, and the Power Platform admin center. FMC does not call or document any Copilot feature-management Graph endpoint, and its default configuration leaves the Graph endpoint unset.

If the implementation team separately documents Entra staged authentication rollout, keep that activity out of FMC Copilot feature governance and align its delegated permissions to current Microsoft Learn guidance.

## Supported Administrative Surfaces

FMC assumes access to the following sources:

- Microsoft 365 admin center feature and app policy settings (Copilot Control System)
- Cloud Policy service `Allow web search in Copilot` policy state and group scope (Microsoft 365 Apps admin center)
- Teams admin center policy views or exports for documented Teams meeting/event and calling controls. Read the state with supported cmdlets — `Get-CsTeamsMeetingPolicy` (`-Copilot` values `Enabled`, `EnabledWithTranscript`, `EnabledWithTranscriptDefaultOn`, `Disabled`) and `Get-CsTeamsCallingPolicy` (`-Copilot` values `Enabled`, `EnabledWithTranscript`, `Disabled`). This solution inspects and documents policy state; it does not run the `Set-Cs*` cmdlets.
- Microsoft 365 Copilot app inventory or documentation-first review for Teams chat/channel Copilot exposure (there is no dedicated Teams-chat Copilot on/off policy; it follows the Microsoft 365 Copilot license and app availability)
- Power Platform admin center Copilot settings and administrative exports, with Power Automate interpreted through the documented tenant-level limitation

## Platform and Tooling Requirements

- PowerShell 7 or later
- Access to the shared modules in `..\..\scripts\common\`
- Access to repository contract files under `..\..\data\`
- Network access to the administrative portals referenced by the operating model

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
- Confirm Teams and Power Platform policy exports can be generated on demand where documented exports are available.
- Confirm evidence retention and archival destination before the first export.
