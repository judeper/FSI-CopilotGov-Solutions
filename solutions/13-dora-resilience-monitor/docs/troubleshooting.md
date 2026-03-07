# Troubleshooting

## Service Health API Errors

### Authentication failures

If `Monitor-Compliance.ps1` cannot authenticate to Microsoft Graph:

1. Confirm that the tenant ID and client ID are correct.
2. Re-enter the client secret or validate the certificate binding.
3. Verify that admin consent has been granted for `ServiceHealth.Read.All`.
4. Confirm that the executing identity has Global Reader or Service Support Admin visibility where required.

### Throttling

If the Microsoft Graph service communications endpoint responds with throttling behavior:

- Increase the polling interval temporarily.
- Respect retry-after guidance from Microsoft Graph.
- Avoid running parallel ad hoc monitoring jobs during an active outage.

### Missing data

If health records are incomplete:

- Check whether the workload is represented in the tenant's service communications feed.
- Compare script output with the Microsoft 365 admin center.
- Record the gap in the incident register if an outage is known but not yet visible through Graph.

## Incident Classification Issues

### Severity thresholds appear too strict or too lenient

Review the selected tier configuration and verify the values under `incidentClassification.severityThresholds`. Regulated tier uses lower user-impact thresholds than baseline or recommended.

### Unknown service names

If Microsoft Graph returns a workload name that is not recognized by local reporting:

- Add the alias to the monitored service mapping process.
- Record the original Microsoft workload name in the incident register notes.
- Confirm whether the workload is truly Copilot-dependent before classifying it as a reportable finding.

## Evidence Export Failures

### SHA-256 mismatch

A SHA-256 mismatch usually means the JSON file changed after the companion hash was written.

- Re-run `scripts\Export-Evidence.ps1` to regenerate the artifact and its hash.
- Do not edit exported JSON files by hand after the hash is created.
- Store the evidence package in a controlled folder to reduce accidental modification.

### Output path issues

If export fails because the output path is invalid:

- Confirm that the deployment account can create directories and files in the target path.
- Use a local or approved network path with stable write access.
- Avoid output paths that are redirected or automatically synchronized during active export.

## DORA Reporting Gaps

### Missing incident fields

If `incident-register` is missing `reportedAt`, `rtoActual`, or `rpoActual` values:

- Review the incident-management workflow and confirm when those fields should be populated.
- Add manual enrichment after the operational review if the data is not available at the time of export.
- Keep a note explaining why the field is pending so compliance reviewers understand the gap.

### Incomplete RTO or RPO data

If resilience-test evidence does not contain actual recovery values:

- Confirm whether the test was scheduled but not executed.
- Capture the approved target values from the tier configuration.
- Update the operational record after the exercise is completed and regenerate the evidence package.

## Power Automate Flow Issues

The Power Automate implementation is documentation-first in this version. If the expected flow does not exist or does not trigger:

- Confirm that the flow was manually created from `docs/deployment-guide.md`.
- Validate the recurrence schedule against the selected tier.
- Check connector credentials and target notification channels.
- Review run history in Power Automate for failed actions.

## Common Error Messages

| Error Message | Likely Cause | Resolution |
|---------------|--------------|------------|
| `Configuration file not found` | Tier JSON file path is wrong or missing | Confirm the selected tier file exists under `config/` and rerun the script |
| `DRM configuration is missing required fields` | JSON was edited without preserving mandatory keys | Compare the file with the repository baseline and restore missing properties |
| `Authentication failed for Microsoft Graph service health` | Invalid secret, missing consent, or wrong tenant | Revalidate app credentials and Graph permissions |
| `Hash file not found` | Evidence package was moved or edited after export | Re-export the evidence package and keep JSON and `.sha256` files together |
| `No service health entries were returned` | Graph endpoint did not return workload data | Compare with admin center status and escalate if the gap persists |

## Escalation Path to Microsoft Support

Escalate to Microsoft Support when service-health data gaps persist across multiple polling intervals or when the admin center and Graph results do not align during an active incident.

Collect the following before opening the case:

- Tenant ID and impacted workload names
- UTC timestamps for the missing or inconsistent health records
- Incident identifiers shown in the Microsoft 365 admin center, if any
- Screenshots or exports demonstrating the discrepancy
- Correlation IDs from Graph requests when available

Use the Microsoft 365 admin center support workflow or the customer's unified support channel, then record the case number in the incident register.
