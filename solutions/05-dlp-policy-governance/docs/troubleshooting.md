# Troubleshooting

## Common issues

| Symptom | Likely cause | Resolution |
|---------|--------------|------------|
| DLP policy read returns empty results | The session is not connected to Exchange Online and Security and Compliance PowerShell | Run `Connect-ExchangeOnline` and `Connect-IPPSSession`, then rerun the collection step |
| Drift is reported on the first monitoring run | No approved baseline has been captured yet | Run `Deploy-Solution.ps1` to create `dlp-policy-baseline.json` and approve the initial snapshot before monitoring |
| Exception flow does not trigger | The Power Automate connection, trigger, or approval connector is not configured correctly | Review the flow owner account, connection references, and trigger filters in Power Automate |
| Sensitivity label checks do not match Solution 03 | The label audit is stale or the tier references labels that changed after the last audit | Re-run `03-sensitivity-label-auditor`, update the label mapping, and refresh the baseline |
| Graph reads fail with permission errors | Microsoft Graph scopes were not granted during connection | Reconnect with `InformationProtectionPolicy.Read` and `Policy.Read.All` scopes |
| Exchange workload is missing from policy scope | Licensing or workload enablement is incomplete | Confirm Microsoft 365 E5 or E5 Compliance and the required Copilot workload enablement |

## Diagnostic tips

- Review `deployment-manifest.json` to confirm the intended tier and output paths.
- Compare `dlp-policy-baseline.json` and `policy-drift-findings.json` when investigating unexpected drift.
- Confirm the exception attestation log exists before enabling required approvals in the recommended or regulated tiers.
- Validate hash companions if evidence files are copied to another location for review.
