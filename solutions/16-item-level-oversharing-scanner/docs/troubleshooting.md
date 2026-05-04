# Troubleshooting

## Error: PnP PowerShell connection failures

**Symptoms**

- `Connect-PnPOnline` fails or prompts unexpectedly
- Interactive login works for one admin but not for automation
- Certificate-based authentication returns an access denied error

**Actions**

- Confirm the correct tenant admin URL and authentication method are being used
- Confirm the operator is a site collection administrator on each target site, or that a SharePoint Administrator/Global Administrator has granted that access
- Reinstall or update `PnP.PowerShell` if the module version is outdated
- Validate that conditional access does not block the execution host
- For app-only Graph read-only permission listing, validate the documented permissions for the selected endpoint; reserve broader SharePoint/PnP or write permissions for approved remediation scenarios

## Error: SharePoint throttling during item enumeration

**Symptoms**

- Requests slow down sharply during large library scans
- API calls return 429 (Too Many Requests) or transient service errors
- Scan output is incomplete for libraries with many items

**Actions**

- Reduce scope by targeting fewer sites per run with the `-SiteUrls` parameter
- Set a lower `maxItemsPerLibrary` value in the tier configuration
- Run the first large scan during a lower-usage window
- Add retry and backoff logic when replacing the current implementation stubs with live API calls
- Monitor PnP PowerShell retry headers for recommended wait times

## Error: Insufficient permissions to read item-level sharing

**Symptoms**

- Items are returned but permission entries are empty or incomplete
- Sensitivity label information is missing from scan results
- Guest user details are not resolved

**Actions**

- Verify the operator has site collection administrator access on target sites
- For Graph read-only permission listing, validate `Files.Read.All` or the applicable documented higher-privileged permission for the selected endpoint
- If identity enrichment uses a separate endpoint, document and consent only the least-privileged permission required for that endpoint
- Review tenant settings that restrict visibility into item-level sharing or sensitivity labels

## Error: Risk scoring produces unexpected results

**Symptoms**

- Items with sensitive labels are classified as LOW risk
- Content-type weighting does not appear to be applied
- Score thresholds do not match expected behavior

**Actions**

- Review `config/risk-thresholds.json` for correct base scores and content-type weights
- Confirm sensitivity label values in the scan output match the keywords in `risk-thresholds.json`
- Check that the `riskThresholds` section in `default-config.json` has the expected HIGH/MEDIUM/LOW boundaries
- Run the scoring script with a small input set and verify the calculation manually

## Error: Remediation script creates actions without approval

**Symptoms**

- Items are being remediated without appearing in `pending-approvals.json`
- HIGH-risk items are not routed to the approval gate

**Actions**

- Verify `config/remediation-policy.json` has `approval-gate` mode for all tiers
- Confirm `autoRemediationEnabled` is `false` in the configuration
- Check that the risk tier assignment in the scored report matches expected values
- Review the remediation log for any items that bypassed the policy check

## Tip: Use a small site set for initial validation

Run the first scan with 2-3 high-risk sites identified by solution 02 to validate PnP connectivity, permission enumeration, and risk scoring before expanding scope.

## Tip: Review pending approvals before running subsequent scans

Clear or act on `pending-approvals.json` entries before running additional remediation passes to avoid duplicate approval requests.
