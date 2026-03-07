# Troubleshooting

## Error: PnP PowerShell connection failures

**Symptoms**

- `Connect-PnPOnline` fails or prompts unexpectedly
- Interactive login works for one admin but not for automation

**Actions**

- Confirm the correct tenant admin URL and authentication method are being used
- Confirm the operator has SharePoint Admin, Compliance Admin, or Global Admin rights as needed
- Reinstall or update `PnP.PowerShell` if the module version is outdated
- Validate that conditional access does not block the execution host

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

- Confirm the environment type and data loss prevention policies
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
