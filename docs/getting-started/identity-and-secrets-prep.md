# Identity and Secrets Prep

Complete this guide before running tenant-specific deployment, monitoring, or evidence-export scripts.

## What Must Be Decided Up Front

| Area | Minimum decision | Record in handoff package |
| --- | --- | --- |
| Operator identity | Who can run non-production and production scripts | Named operator, approver, and backup owner |
| Workload-specific access | Which Microsoft Entra, Purview, Exchange, Teams, SharePoint, and Power Platform roles are required | Approved role list and assignment owner |
| Authentication pattern | Whether a script uses interactive sign-in, app registration with certificate, or other approved enterprise pattern | Authentication approach, renewal owner, and expiry date |
| Secret and certificate storage | Where secrets, certificates, webhook URLs, and connection references live outside the repository | Approved vault, key owner, rotation process |
| Evidence destination | Where manifests, evidence packages, and validation outputs are retained | Storage path and retention expectation |
| Break-glass path | Who can approve emergency access or rollout holds | Escalation contact and decision authority |

## Preflight Checklist

- [ ] Review [Common Prerequisites](./prerequisites.md).
- [ ] Run `pwsh -File scripts\deployment\Validate-Prerequisites.ps1`.
- [ ] Document the operator identities that can execute `Deploy-Solution.ps1`, `Monitor-Compliance.ps1`, and `Export-Evidence.ps1`.
- [ ] Confirm MFA, Conditional Access, and privileged-access approval expectations for those identities.
- [ ] Record where certificates, secrets, and connection references are stored without placing the values in source control.
- [ ] Confirm evidence storage, notification endpoints, and any shared mailbox or Teams channel owners.
- [ ] Capture the resulting decisions in `DELIVERY-CHECKLIST-TEMPLATE.md` or the solution-specific delivery checklist.

## Secret-Handling Rules

- Keep secrets, certificates, and connection-reference values in the approved enterprise vault or secret store.
- Store only identifiers, names, or retrieval instructions in documentation and deployment manifests.
- Assign a named owner for rotation, expiry review, and emergency replacement.
- Reconfirm expirations before each production wave and before any scheduled evidence-export cycle.

## Exit Criteria

You are ready to schedule deployment work when the operator identity, role assignments, secret-storage pattern, evidence destination, and escalation owner are all documented and approved.

See the [Documentation vs Runnable Assets Guide](../documentation-vs-runnable-assets-guide.md) for the repository boundary that keeps tenant-specific runtime material outside source control.
