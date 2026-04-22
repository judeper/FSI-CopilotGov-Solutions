# Troubleshooting

## Configuration Issues

### Tier configuration file not found

If `Monitor-Compliance.ps1` or `Export-Evidence.ps1` reports a missing tier file:

- Confirm that `config/<tier>.json` exists where `<tier>` is one of `baseline`, `recommended`, or `regulated`.
- Confirm the working directory and `-OutputPath` are correct.

### Missing required fields

If the configuration validator reports missing fields:

- Compare the file with the repository baseline and restore missing keys.
- Do not edit JSON files by hand without preserving required keys such as `publishingApprovalRequired`, `versioningRetentionDays`, `deprecationNoticeDays`, and `lifecycleReviewCadenceDays`.

## Approval Workflow Issues

### Approval evidence missing for regulated tier

If publishing-approval-log entries do not show two approvers when running the regulated tier:

- Confirm the approval payload supplied to the monitoring stub includes both reviewer identities.
- Confirm the operating model assigns at least two approvers, including the supervisory reviewer where required.

### Reviewer identity not captured

If `submittedBy` or `approvers` fields are empty:

- Confirm the input payload includes the reviewer identity field.
- Check that downstream Power Automate or manual approval handoff is populating identity values.

## Lifecycle Review Issues

### Agent flagged as overdue unexpectedly

- Confirm the `lastReviewedAt` field is present and ISO-8601 formatted in the input payload.
- Confirm the tier review cadence aligns with the operating model.

## Evidence Export Failures

### SHA-256 mismatch

- Re-run `scripts\Export-Evidence.ps1` to regenerate the artifact and its hash.
- Do not edit exported JSON files by hand after the hash is created.

### Output path issues

- Confirm that the deployment account can create directories and files in the target path.
- Use a local or approved network path with stable write access.

## Common Error Messages

| Error Message | Likely Cause | Resolution |
|---------------|--------------|------------|
| `Configuration file not found` | Tier JSON file path is wrong or missing | Confirm the selected tier file exists under `config/` and rerun the script |
| `CSLT configuration is missing required fields` | JSON was edited without preserving mandatory keys | Compare the file with the repository baseline and restore missing properties |
| `Hash file not found` | Evidence package was moved or edited after export | Re-export the evidence package and keep JSON and `.sha256` files together |

## Escalation Path

Escalate to the Copilot Studio admin and the platform governance team when inventory data is missing across multiple monitoring runs. Capture tenant ID, environment names, agent identifiers, and UTC timestamps when opening the case.
