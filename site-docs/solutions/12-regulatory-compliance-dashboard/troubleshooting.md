# Troubleshooting

## Evidence freshness appears stale

Symptoms:

- Power BI shows stale evidence warnings for multiple controls.
- `Monitor-Compliance.ps1` returns a large `StaleEvidence` list.

Common causes:

- Upstream solutions are not exporting evidence on schedule.
- Freshness thresholds are stricter than the configured export cadence.
- The `RCD-EvidenceAggregator` flow is failing before it writes updated timestamps.

Resolution steps:

1. Confirm upstream evidence packages exist and have current timestamps.
2. Verify the configured freshness threshold for the selected tier.
3. Review the last successful run of `RCD-EvidenceAggregator` and `RCD-FreshnessMonitor`.
4. Re-run `scripts\Deploy-Solution.ps1` or the aggregation flow if seed data needs to be refreshed.

## Dataverse connection reference errors

Symptoms:

- Flow import fails or connections show as unhealthy.
- The dashboard dataset cannot read the Dataverse tables.

Common causes:

- Missing or broken connection references after solution import.
- Target environment URL does not match the configured Dataverse URL.
- Deployment identity lacks Dataverse permissions.

Resolution steps:

1. Open the target environment and repair Dataverse, Power BI, and storage connection references.
2. Confirm the `DataverseUrl` value matches the environment configuration.
3. Validate that the operator has Dataverse System Administrator or equivalent rights.
4. Re-run the flow connection test and refresh the dataset credentials.

## Power BI dataset refresh failures

Symptoms:

- Scheduled refresh fails in the service.
- Report visuals show missing data or credential errors.

Common causes:

- Dataset credentials are not bound after report publication.
- Table names in the dataset do not match `fsi_cg_rcd_baseline`, `fsi_cg_rcd_finding`, and `fsi_cg_rcd_evidence`.
- Row-level security roles were changed without republishing the dataset.

Resolution steps:

1. Confirm the dataset points to the expected Dataverse tables.
2. Refresh credentials and test the connection in the Power BI service.
3. Re-apply RLS roles and confirm membership is correct.
4. Trigger a manual refresh and confirm the refresh history is clean before enabling schedules.

## Control status shows not-applicable unexpectedly

Symptoms:

- A control tile drops to `not-applicable` even though evidence exists.

Common causes:

- Source control mappings were removed from the framework matrix.
- An upstream solution failed to publish the expected control identifier.
- A filter in Power BI excludes the relevant solution or business unit.

Resolution steps:

1. Confirm the control exists in the coverage mapping and Dataverse baseline data.
2. Validate that upstream evidence exports use the expected control IDs.
3. Clear report filters and confirm the status still appears.
4. Re-run the aggregation flow after fixing the mapping.

## Examination package generation fails

Symptoms:

- `RCD-ExaminationPackager` completes with missing attachments or empty package manifests.

Common causes:

- Required upstream evidence packages were never exported.
- The package destination path is invalid or inaccessible.
- The selected regulation is not enabled for the current tier.

Resolution steps:

1. Confirm the selected regulation is enabled in the chosen configuration file.
2. Validate the package output location and flow permissions.
3. Ensure upstream evidence packages include both JSON and `.sha256` files.
4. Re-run the package flow with a smaller scope to isolate the missing artifact.

## Missing solutions in the coverage matrix

Symptoms:

- One or more deployed solutions are absent from the Power BI heatmap or matrix.

Common causes:

- The evidence source list does not include the missing solution.
- The solution has no export history yet.
- The aggregator flow filters out solutions with invalid or missing package metadata.

Resolution steps:

1. Update the evidence source configuration to include the missing solution.
2. Run the missing solution's `Export-Evidence.ps1` script and confirm the package is current.
3. Re-run `RCD-EvidenceAggregator` and confirm the rows are written to `fsi_cg_rcd_evidence`.
4. Refresh the Power BI dataset and verify the matrix updates.
