# Troubleshooting

## Common Scenarios

| Symptom | Likely cause | Remediation |
|---------|--------------|-------------|
| Feature inventory includes Entra staged authentication rollout records. | An unrelated Microsoft Graph feature rollout policy source was included in the Copilot feature baseline. | Remove those records from FMC, keep Entra staged rollout documentation separate, and use documented Copilot admin surfaces for the baseline. |
| Teams Copilot settings are missing from the inventory. | Teams Administrator rights are missing, or the Teams policy export was not refreshed before the run. | Refresh the Teams policy export, confirm Teams Administrator access, and rerun inventory collection. |
| Power Platform Copilot settings show as unmanaged. | The target environment in Power Platform admin center does not match the environment referenced during deployment. | Verify the environment name passed to `-Environment`, update the tier configuration if necessary, and rerun baseline capture. |
| Drift alerts keep firing after an approved feature change. | The baseline was not refreshed after the approved ring promotion or restriction. | Capture a new baseline with `Deploy-Solution.ps1`, store the approval reference, and rerun `Monitor-Compliance.ps1`. |
| Regulated tier shows connector exposure findings for third-party plugins. | Connector and plugin inventory is broader than the approved feature scope. | Review plugin and connector approvals, move the feature to `Restricted` if necessary, and coordinate with the connector governance solution for deeper assessment. |
| Evidence export writes JSON but no `.sha256` file is present. | The output path is not writable or the export process was interrupted after payload creation. | Re-run `Export-Evidence.ps1` with a writable output path and verify the hash file immediately after export. |

## Script-Level Checks

1. Confirm the tier file exists under `config\`.
2. Confirm the baseline path passed to `Monitor-Compliance.ps1` points to a JSON file that contains feature definitions.
3. Confirm the output directory exists or can be created by the current user.
4. Confirm shared modules under `..\..\scripts\common\` are available.

## Drift Review Tips

- Ring mismatch usually indicates an unapproved promotion or rollback.
- Enablement mismatch usually indicates a feature toggle was changed outside the approved workflow.
- Missing feature records usually indicate a collection gap or a new Copilot capability that needs to be added to the baseline.

## Escalation Guidance

- Escalate SEC Reg FD-related feature exposure risks to compliance and business supervision teams immediately if a feature widens access to research or issuer-sensitive content.
- Escalate FINRA 3110-related supervision gaps when ring promotion occurs without documented approval or when alerting is disabled in a regulated deployment.
