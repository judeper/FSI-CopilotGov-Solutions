# Troubleshooting

## Common issues

| Symptom | Likely cause | Recommended action |
|---------|--------------|--------------------|
| Conditional Access policy is not applying to Copilot | The Copilot app ID is incorrect, or the tenant does not expose app-specific targeting for the workload | Verify the app ID, confirm Copilot licensing, and if necessary target `All cloud apps` while excluding unrelated workloads until direct targeting is available |
| Drift alert appears to be a false positive | A system process or approved service account updated the policy outside the baseline window | Review sign-in and audit logs, document the change, and exclude approved service accounts from drift review rules where appropriate |
| Exception register write fails | The output path is missing, read-only, or not approved for the automation account | Validate the output path, permissions, and file-locking state before rerunning the script |
| Graph API returns 403 | The operator is missing `Policy.Read.All`, `Policy.ReadWrite.ConditionalAccess`, or the required administrator role | Reconnect with the correct scopes and verify role assignment in Entra ID |
| MFA is not enforced | Grant controls are incomplete, policy precedence is wrong, or report-only mode is still enabled | Confirm the policy state, review grant controls order, and ensure the production policy is enabled |
| Baseline does not match on the first run | The baseline was captured before policy review was complete | Re-export or recapture the baseline after the approved policy state is finalized |

## Additional guidance

- Recheck named locations whenever network boundaries or branch routing changes.
- Validate break-glass exclusions separately from the standard Copilot user policies.
- Wait for Conditional Access propagation before repeating sign-in tests after a policy change.
