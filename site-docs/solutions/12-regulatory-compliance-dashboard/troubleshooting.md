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
- The dashboard semantic model cannot read the Dataverse tables.

Common causes:

- Missing or broken connection references after solution import.
- Target environment URL does not match the configured Dataverse URL.
- Deployment identity lacks Dataverse permissions.

Resolution steps:

1. Open the target environment and repair Dataverse, Power BI, and storage connection references.
2. Confirm the `DataverseUrl` value matches the environment configuration.
3. Validate that the operator has Dataverse System Administrator or equivalent rights.
4. Re-run the flow connection test and refresh the semantic model credentials.

## Power BI semantic model refresh failures

Symptoms:

- Scheduled refresh fails in the service.
- Report visuals show missing data or credential errors.

Common causes:

- Semantic model credentials are not bound after report publication.
- Table names in the semantic model do not match `fsi_cg_rcd_baseline`, `fsi_cg_rcd_finding`, and `fsi_cg_rcd_evidence`.
- Row-level security roles were changed without republishing the semantic model.

Resolution steps:

1. Confirm the semantic model points to the expected Dataverse tables.
2. Refresh credentials and test the connection in the Power BI service.
3. Re-apply RLS roles and confirm membership is correct.
4. Trigger a manual refresh and confirm the refresh history is clean before enabling schedules.

## Read-only workspace inventory is blocked by missing scope or consent

Symptoms:

- `GET /v1.0/myorg/groups` returns unauthorized or forbidden.
- The first-cycle lab cannot attest workspace accessibility.

Common causes:

- Delegated `Workspace.Read.All` is not preauthorized for the reviewer.
- Consent evidence for the delegated read scope is missing.

Resolution steps:

1. Record an evidence-backed `BLOCKED` disposition for the lab step.
2. Capture only aggregate failure context (for example, API status and timestamp), not raw workspace identifiers.
3. Do not request consent during the read-only cycle and do not switch to `Workspace.ReadWrite.All`.
4. Resume validation only after preauthorized delegated `Workspace.Read.All` is available.

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
3. Confirm upstream evidence packages include both JSON and `.sha256` files.
4. Re-run the package flow with a smaller scope to isolate the missing artifact.

## Referenced evidence shows unknown freshness or a data-quality gap

Symptoms:

- `Monitor-Compliance.ps1` reports `DataQualityGap = true` or a non-zero `TimestampGapControlCount`.
- `dashboard-export` shows `dataQuality.overall = gap`, and referenced packages show `freshnessStatus = unknown` with `hashState = unresolved`.

Common causes:

- The solution is running in the documentation-first repository state, where no upstream evidence timestamps or hashes are resolved yet.
- Upstream solutions have not exported current evidence packages, so no `sourceLastModified` value is available.

Resolution steps:

1. Treat `unknown` freshness as an explicit gap, not as current evidence.
2. Run each upstream solution's `Export-Evidence.ps1` so the aggregation flow can resolve `sourceLastModified` and SHA-256 hashes at runtime.
3. Re-run monitoring and confirm `timestampProvenance` moves from `missing` to `source-provided` for resolved controls.

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
4. Refresh the Power BI semantic model and verify the matrix updates.
