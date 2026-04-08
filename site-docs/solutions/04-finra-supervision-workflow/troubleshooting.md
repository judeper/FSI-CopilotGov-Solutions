# Troubleshooting

## Power Automate flow not triggering

Symptoms:
- New flagged items do not appear in the review queue.
- No `ingested` rows are written to `fsi_cg_fsw_log`.

Checks:
- Confirm the Purview policy is enabled and includes Copilot prompts and responses.
- Confirm `fsi_cr_fsw_purview` resolves successfully in the target environment.
- Confirm the trigger account can read the policy scope and the environment variables are populated.

Resolution:
- Reauthenticate the connection reference.
- Re-save the flow after updating environment variables.
- Run a test ingestion with a known flagged sample item.

## SLA breach not alerting

Symptoms:
- Overdue items remain in `PendingReview` or `InReview` without a breach notification.

Checks:
- Confirm `escalationEnabled` is true for the active tier.
- Confirm the Escalation Flow schedule is shorter than the shortest SLA.
- Confirm `fsi_sladue` is populated in UTC and not local time.

Resolution:
- Update the tier configuration and redeploy the manifest.
- Recalculate existing SLA due dates if timezone conversion was incorrect.
- Confirm breach recipients exist in the notifications section of the tier file.

## Evidence export fails

Symptoms:
- `Export-Evidence.ps1` throws a file, token, or API error.

Checks:
- Confirm PowerShell 7 or later is in use.
- Confirm the output path is writable.
- For `-LiveExport`, confirm `DATAVERSE_ACCESS_TOKEN` is populated and the environment URL is not a placeholder.

Resolution:
- Run the script without `-LiveExport` to validate the documentation-first path.
- Refresh the Dataverse access token and retry.
- Confirm the target tables exist and the service identity has read access.

## Dataverse permission errors

Symptoms:
- Flow actions or live export requests return access denied or insufficient privileges.

Checks:
- Confirm the service account or principal has table permissions for queue, log, and config tables.
- Confirm column security is not blocking review notes or outcome fields.
- Confirm the user is in the correct Power Platform security role.

Resolution:
- Grant read or read-write access to the required tables.
- Review environment-level security role assignments.
- Reopen the connection reference after role changes.

## Microsoft Purview Communication Compliance API access issues

Symptoms:
- Purview policy data cannot be read or no flagged items are returned.

Checks:
- Confirm the account has Purview Compliance Admin rights.
- Confirm the policy ID in `fsi_ev_fsw_purviewpolicyid` matches the approved policy.
- Confirm the policy has produced cases or alerts for the requested period.

Resolution:
- Update the environment variable with the correct policy ID.
- Validate policy scope and signal sources in Purview.
- Coordinate with compliance operations if the policy was recently modified.

## Sampling rate misconfiguration

Symptoms:
- Monitor output reports partial status for control 3.4.
- Review volume is materially higher or lower than expected.

Checks:
- Zone1 should remain between 5 and 25 percent.
- Zone2 should remain between 25 and 50 percent.
- Zone3 should remain at 100 percent when enabled.

Resolution:
- Correct the tier JSON file and reseed `fsi_cg_fsw_config` rows.
- Re-run `Monitor-Compliance.ps1` to confirm the control status returns to implemented.
- Document the change in the firm's supervisory procedures if sampling policy changed.

## Dataverse API rate limiting and transient failures

Symptoms:
- Live export fails intermittently with HTTP 429 (Too Many Requests), 503 (Service Unavailable), or 504 (Gateway Timeout).
- Export completes on retry but not on the first attempt.
- Pagination appears to stall or time out mid-export.

Checks:
- Confirm the Dataverse environment is not under heavy concurrent load from other integrations.
- Verify the service account is not exceeding the per-user API request limits (default 6,000 requests per 5-minute window).
- Check the `Retry-After` header value in the error response for guidance on when to retry.

Resolution:
- `Invoke-DataverseTableQuery` includes automatic retry logic for HTTP 429, 503, and 504 responses with exponential backoff (2s, 4s, 8s) up to 3 retries. If the issue persists after retries, investigate Dataverse service health.
- Reduce concurrent API consumers or stagger export schedules to avoid hitting the per-user rate limit.
- For large result sets, confirm pagination completes within 1,000 pages. If exceeded, apply a narrower `$filter` to reduce the result set (for example, shorter date ranges).
- Monitor the Power Platform admin center for environment-level API capacity metrics and consider capacity add-ons if limits are consistently reached.

