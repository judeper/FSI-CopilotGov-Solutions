# Troubleshooting — SharePoint Permissions Drift Detection

## PnP PowerShell Connection Failures

**Symptoms:** `Connect-PnPOnline` throws `Access Denied` or `Unable to authenticate` errors.

**Actions:**
1. Verify the service account has SharePoint Administrator role or equivalent
2. Confirm the Azure AD application registration has `Sites.Read.All` permission
3. Check that Conditional Access policies do not block the service account
4. Ensure `PnP.PowerShell` module is version 2.3.0 or later
5. Test connectivity manually: `Connect-PnPOnline -Url "https://contoso.sharepoint.com" -Interactive`

## SharePoint API Throttling

**Symptoms:** Scripts fail intermittently with HTTP 429 (Too Many Requests) or HTTP 503 errors during large-scale baseline capture or drift scans.

**Actions:**
1. Reduce `maxSitesPerRun` in `config/baseline-config.json` to process fewer sites per execution
2. Increase scan frequency to distribute load across more runs
3. Check SharePoint tenant throttling limits in the SharePoint Admin Center
4. Implement retry logic with exponential backoff (built into PnP PowerShell cmdlets)

## Baseline File Not Found

**Symptoms:** `Invoke-DriftScan.ps1` reports `Cannot find baseline file` or `latest-baseline.json not found`.

**Actions:**
1. Verify `New-PermissionsBaseline.ps1` has been run at least once
2. Check that the `baselines/` directory exists and contains `latest-baseline.json`
3. Confirm `latest-baseline.json` contains a valid `baselinePath` reference
4. Manually specify the baseline path using the `-BaselinePath` parameter

## Drift Report Shows Unexpected Results

**Symptoms:** Drift scan reports large numbers of ADDED or REMOVED entries that appear to be false positives.

**Actions:**
1. Verify the baseline was captured during a known-good permissions state
2. Check if a SharePoint migration or bulk permissions change occurred between baseline and scan
3. Review the drift report for patterns (e.g., all changes on a single site may indicate a legitimate restructuring)
4. Re-capture the baseline if the current permissions state has been reviewed and approved

## Auto-Reversion Not Executing

**Symptoms:** `Invoke-DriftReversion.ps1` logs drift items but does not revert permissions.

**Actions:**
1. Verify `autoRevertEnabled` is set to `true` in `config/auto-revert-policy.json`
2. Check that the appropriate risk tier is enabled in `autoRevertScopes` (HIGH, MEDIUM, LOW)
3. Confirm the `-AutoRevert` switch was passed on the command line
4. Verify the service account has `Sites.FullControl.All` permission for write operations
5. Review the reversion log for error entries

## Approval Email Not Received

**Symptoms:** Drift items are queued to `pending-approvals.json` but approvers do not receive notification emails.

**Actions:**
1. Verify `Mail.Send` permission is granted on the Azure AD application registration
2. Confirm the sender mailbox is licensed and not blocked
3. Check the `approvers` list in `config/auto-revert-policy.json` for valid email addresses
4. Review Exchange Online message trace for delivery issues
5. Check spam/junk folders for the notification email

## Insufficient Permissions for Evidence Export

**Symptoms:** `Export-DriftEvidence.ps1` fails with `Access Denied` when writing to the output directory.

**Actions:**
1. Verify the service account has write access to the evidence output directory
2. Check that the directory path exists and is not read-only
3. Run the script with an explicit `-OutputPath` parameter pointing to a writable directory

## High Memory Usage During Large Scans

**Symptoms:** PowerShell process consumes excessive memory when scanning tenants with thousands of sites.

**Actions:**
1. Reduce `maxSitesPerRun` in `config/baseline-config.json`
2. Use the `-SiteUrls` parameter to scope scans to specific sites
3. Schedule multiple smaller runs instead of a single large scan
4. Monitor memory usage and restart the PowerShell session between runs if needed

## Tips

- Run `Deploy-Solution.ps1` before any other script to validate configuration and prerequisites
- Use `-WhatIf` with `Deploy-Solution.ps1` to preview deployment actions without making changes
- Keep baseline retention at 90 days minimum to support trend analysis
- Archive drift reports and evidence packages to immutable storage for regulatory examination readiness
- Test the complete workflow (baseline → scan → revert → export) in a non-production tenant before deploying to production
