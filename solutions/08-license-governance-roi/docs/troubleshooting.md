# Troubleshooting

## Graph API throttling or rate limiting

**Symptoms**

- Monitoring runs take longer than expected.
- Graph report calls return HTTP 429 or retry-after guidance.

**Likely cause**

- Too many concurrent report requests or repeated polling of the Copilot usage detail endpoint.

**Remediation**

- Reduce monitoring frequency or stagger runs by business unit.
- Cache unchanged inventory responses from `/v1.0/subscribedSkus`.
- Honor `Retry-After` guidance in the customer implementation.
- Export the last successful report and document the delayed refresh in the evidence notes.

## Insufficient permissions for usage reports

**Symptoms**

- `Monitor-Compliance.ps1` or a tenant implementation cannot retrieve Copilot usage detail.
- Graph returns authorization failures for reports or directory queries.

**Likely cause**

- The automation identity does not have tenant-admin consent for `Reports.Read.All`, `LicenseAssignment.Read.All`, or `User.Read.All`, or it relies on `Directory.Read.All` without higher-privilege approval.

**Remediation**

- Reconfirm the app registration or service principal permissions.
- Ensure tenant admin consent has been granted after permission changes.
- Validate that the correct tenant identifier and automation identity are being used.

## Viva Insights data not available

**Symptoms**

- The ROI scorecard contains low coverage or only Microsoft 365 usage metrics.
- Business-unit ROI values cannot be populated.

**Likely cause**

- Viva Insights licensing is missing, the curated export is delayed, or the selected tier disables Viva enrichment.

**Remediation**

- Confirm whether the selected tier should enable Viva Insights.
- Validate the customer-provided extract path and refresh timing.
- If Viva data is intentionally unavailable, document the limitation in the evidence package and retain a `monitor-only` or `partial` control note for 4.6.

## Power BI dataset refresh failures

**Symptoms**

- Dataset refresh fails after deploying the documented model.
- Visuals show stale or partial utilization data.

**Likely cause**

- Missing credentials, a gateway configuration problem, or schema mismatch between the expected tables and the loaded data.

**Remediation**

- Revalidate workspace credentials and gateway bindings.
- Confirm the dataset table names match the documented logical design.
- Check whether Graph extract files, Viva exports, or Dataverse tables changed shape without updating the semantic model.

## Evidence export SHA-256 mismatch

**Symptoms**

- `Test-EvidencePackageHash` returns `IsValid = False`.
- The `.sha256` file does not match the current evidence package.

**Likely cause**

- The evidence JSON was modified after export, the hash file was overwritten, or the package was copied through a process that changed encoding.

**Remediation**

- Regenerate the evidence package from the source script.
- Verify that `08-license-governance-roi-evidence.json` and its `.sha256` file are from the same export run.
- Re-run `Get-FileHash -Algorithm SHA256` and compare the lower-case hash to the stored value before distribution.
