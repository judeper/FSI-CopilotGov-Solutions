# Troubleshooting

## Common issues

| Symptom | Likely cause | Resolution |
|---------|--------------|------------|
| DLP policy read returns empty results | The Security & Compliance session, RBAC access, or policy scope needs review | For optional tenant-bound collection, use `Connect-IPPSSession`, confirm permissions and policy scope, then review `Get-DlpCompliancePolicy` / `Get-DlpComplianceRule`; a separate Exchange Online connection is not required |
| Drift is reported on the first monitoring run | No approved baseline has been captured yet | Run `Deploy-Solution.ps1` to create `dlp-policy-baseline.json` and approve the initial snapshot before monitoring |
| Exception flow does not trigger | The Power Automate connection, trigger, or approval connector is not configured correctly | Review the flow owner account, connection references, and trigger filters in Power Automate |
| Sensitivity label checks do not match Solution 03 | The label audit is stale or the tier references labels that changed after the last audit | Re-run `03-sensitivity-label-auditor`, update the label mapping, and refresh the baseline |
| Graph reads fail with permission errors | Microsoft Graph scopes were not granted during connection | Reconnect with `InformationProtectionPolicy.Read` and `Policy.Read.All` scopes |
| Exchange workload cannot be selected alongside the Copilot location | Copilot location exclusivity is expected | Review Exchange DLP as a separate complementary workload policy; selecting the Copilot location disables every other location in that policy |
| Copilot location is absent or administrative units cannot be assigned | The policy uses a non-Custom template, or an unsupported scope | Review the Custom template; the Copilot location does not support administrative units |
| A rule cannot combine prompt SITs and sensitivity labels | These conditions cannot share a rule | Review separate rules within the same Copilot-location policy |
| Sensitive prompt still receives an internally grounded response | Only external web search is restricted | Distinguish Performing Web Searches from Processing prompts; prompt processing restriction remains preview and needs tenant availability verification |
| A labeled item still appears in citations | Label-based blocking excludes content, not necessarily citations | Check that the content was excluded rather than treating a citation alone as a failed block |
| A label change does not immediately affect an open Office file | Policy propagation or file-open evaluation is pending | Allow up to four hours after policy changes; reopen the file after a mid-session label change before evaluating enforcement |
| Sensitive text in a directly uploaded prompt file is not blocked | This location evaluates typed prompt text, not uploaded file contents | Do not use uploaded-file content as a positive enforcement criterion for this location |
| Approval-flow licensing appears to require Premium for approvals alone | Approvals has been confused with additional premium connectors | The Approvals connector is standard; review the complete connector set and database prerequisites separately |

Sources: [Copilot DLP conditions, availability, and limitations](https://learn.microsoft.com/purview/dlp-microsoft365-copilot-location-learn-about), [Security & Compliance connection](https://learn.microsoft.com/powershell/exchange/connect-to-scc-powershell), and [approvals prerequisites](https://learn.microsoft.com/power-automate/get-started-approvals).

## Diagnostic tips

- Review `deployment-manifest.json` to confirm the intended tier and output paths.
- Compare `dlp-policy-baseline.json` and `policy-drift-findings.json` when investigating unexpected drift.
- Confirm the exception attestation log exists before enabling required approvals in the recommended or regulated tiers.
- Validate hash companions if evidence files are copied to another location for review.
