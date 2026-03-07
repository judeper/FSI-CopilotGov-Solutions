# Troubleshooting

## Readiness scanner dependency not met

**Symptoms**

- `Deploy-Solution.ps1` stops before a manifest is written
- Error indicates the readiness evidence file is missing or stale

**Likely causes**

- `01-copilot-readiness-scanner` has not been deployed in the target tenant
- The readiness evidence file path in configuration is incorrect
- The scanner ran, but the evidence package is older than the freshness threshold

**Remediation**

1. Re-run the readiness scanner in the target tenant.
2. Confirm the configured artifact path points to the latest scanner evidence file.
3. Verify the exported timestamp is within the configured freshness window.
4. Re-run `Deploy-Solution.ps1` only after the dependency status is current.

## License assignment failures or seat limit reached

**Symptoms**

- Wave manifest is generated but assignments remain pending
- Graph or admin logs show license-assignment failures
- Operations reports insufficient Copilot seats

**Likely causes**

- Reserved license pool is smaller than the selected wave
- Assignment groups include more users than the approved cohort
- Manual revocation from a prior rollback did not release all seats

**Remediation**

1. Compare configured wave size to the available Copilot seat count.
2. Reduce the wave size or acquire additional seats before retrying.
3. Validate the assignment group contains only approved users from the manifest.
4. Reconcile any previously revoked or failed assignments before the next run.

## Gate approval flow not triggering

**Symptoms**

- `Gate-Approval-Request` does not create an approval task
- No new entry appears in approval history
- Wave remains blocked even though readiness checks passed

**Likely causes**

- Flow trigger conditions do not match the generated manifest
- Connection references or service-account permissions are missing
- Approval recipients were not configured for the selected governance tier

**Remediation**

1. Confirm the wave manifest contains the fields the flow expects.
2. Review the Power Automate trigger history and connection references.
3. Validate approver group identifiers and email recipients in configuration.
4. Resubmit the approval request after correcting the trigger condition.

## Risk tier misclassification

**Symptoms**

- Tier 2 or Tier 3 users appear in a Tier 1 wave
- Privileged users remain untagged
- Too many users are blocked by the wrong prerequisite set

**Likely causes**

- Department or role metadata is incomplete or inconsistent
- Risk tier criteria in configuration do not match the customer role taxonomy
- Sample classification logic has not yet been replaced with live HR or Entra attributes

**Remediation**

1. Review `riskTierCriteria` in the selected configuration file.
2. Confirm department names and role titles match the source system values.
3. Add or refine keywords for privileged, regulated, and executive roles.
4. Regenerate the wave manifest after updating the classification rules.

## Wave rollback procedure

**Symptoms**

- A wave must be paused due to incident volume, data leakage concern, or approval withdrawal
- Users need to be removed from the active Copilot cohort

**Remediation**

1. Disable or pause `License-Assignment-Trigger`.
2. Export evidence immediately to preserve the state before rollback.
3. Remove affected users from the wave-based assignment group or revoke licenses through the approved admin method.
4. Log rollback findings in `fsi_cg_rtr_finding` and capture the decision in approval history.
5. Re-run `Monitor-Compliance.ps1` to verify the wave shows as blocked or pending remediation.

## Stale readiness data from solution 01

**Symptoms**

- Wave health declines unexpectedly after a long pause
- Deployment validation fails even though the last rollout was approved
- Readiness log references an outdated exported timestamp

**Likely causes**

- Solution 01 has not been rerun after major tenant changes
- The artifact path still points to an older evidence package
- Operational teams advanced to a new wave without refreshing readiness data

**Remediation**

1. Run `01-copilot-readiness-scanner` again after major licensing, identity, or Purview changes.
2. Update the artifact path if a new evidence package was written to a different location.
3. Rebuild the wave manifest so readiness percentages and blockers are recalculated from current data.
