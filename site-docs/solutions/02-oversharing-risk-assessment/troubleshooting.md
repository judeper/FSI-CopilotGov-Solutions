# Troubleshooting

## Error: PnP PowerShell connection failures (project-documented runtime pattern)

**Symptoms**

- `Connect-PnPOnline` fails or prompts unexpectedly
- Interactive login works for one admin but not for automation

**Actions**

- Confirm the correct tenant admin URL and authentication method are being used
- Confirm the operator has SharePoint Administrator, SharePoint Advanced Management Administrator, or Global Administrator rights for the current task, and reserve Compliance Administrator for Purview/DSPM steps
- Validate the documented PnP runtime/app-registration pattern in a tenant lab before rollout
- Reinstall or update `PnP.PowerShell` if the module version is outdated
- Validate that conditional access does not block the execution host

## Error: Restricted SharePoint Search is expected but cannot be newly enabled

**Symptoms**

- Legacy documentation references Restricted SharePoint Search (RSS)
- Teams request new RSS enablement after July 2026 planning windows

**Actions**

- Treat RSS as legacy transition guidance only: Microsoft Learn states RSS is retiring and new enablement is blocked starting 2026-07-31
- For existing RSS tenants, keep caveats explicit (temporary, up to 100 allowed sites, not a security boundary, no permission changes)
- Move discoverability planning to Restricted Content Discovery (RCD)

## Error: Restricted Content Discovery scope does not match expected behavior

**Symptoms**

- Stakeholders expect RCD changes to alter permissions
- OneDrive discoverability is expected to follow SharePoint RCD settings

**Actions**

- Confirm RCD is modeled as a per-SharePoint-site discoverability control
- Confirm RCD does not change permissions and is SharePoint-only (not OneDrive)
- Confirm SharePoint Administrator ownership, delegated site-admin management approvals, and Microsoft Purview audit requirements before rollout

## Error: SharePoint throttling during bulk scans

**Symptoms**

- Requests slow down sharply during large scans
- API calls return throttling or transient service errors

**Actions**

- Reduce scope with `-MaxSites`
- Start with SharePoint-only coverage before adding OneDrive and Teams
- Run the first large scan during a lower-usage window
- Add retry and backoff logic when replacing the current implementation stubs with live API calls

## Error: Insufficient permissions to read site sharing settings

**Symptoms**

- Findings are incomplete
- Sharing scope or guest details are missing from scan results

**Actions**

- Verify the operator has the required admin role
- Confirm the service principal or user context has consent for the required Graph scopes
- Review tenant settings that restrict visibility into external sharing or site permissions

## Error: Power Automate connector not available in environment

**Symptoms**

- Documented notification flow cannot be created in the target environment
- Teams, Outlook, SharePoint, or Approvals connectors are blocked by policy

**Actions**

- Confirm the environment type and Power Platform data policies in the Power Platform admin center; treat Microsoft Purview DLP as a separate sensitive-data control
- Use the documentation-first design to map an approved replacement connector or routing method
- Delay notification enablement until the environment is approved

## Error: Guest access enumeration requires additional consent

**Symptoms**

- Guest exposure counts appear lower than expected
- External user details are partially returned or omitted

**Actions**

- Review Microsoft Graph consent for guest and directory reads
- Confirm guest access reporting is approved by identity governance stakeholders
- Treat guest-access findings as incomplete until consent is corrected

## Tip: Use -MaxSites parameter to scope initial scans

Run the first execution with a constrained value such as `-MaxSites 100` or `-MaxSites 200` so classifier tuning and owner review can occur before large-volume scans.

## Tip: Run in detect-only mode before enabling auto-remediation

Use `DetectOnly` during pilot rollout to validate findings, adjust communications, and confirm remediation ownership. Auto-remediation should only be considered after governance approval, tested rollback steps, and clear business exception handling are in place.
