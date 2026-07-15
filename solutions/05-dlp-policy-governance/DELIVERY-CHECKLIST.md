# Delivery Checklist

- Version: v0.2.3

Use this checklist before declaring DLP Policy Governance for Copilot ready for production operations.

## Dependency readiness

- [ ] Confirm `03-sensitivity-label-auditor` completed successfully and the latest label inventory is available for review.
- [ ] Verify the Copilot label set includes the NPI and PII labels referenced by this solution.

## Policy readiness

- [ ] Complete the DLP policy inventory for all intended Copilot workloads.
- [ ] Confirm the selected governance tier matches the target operating model.
- [ ] Validate included and excluded user group scope for Copilot DLP policies.

## Baseline readiness

- [ ] Run `scripts\Deploy-Solution.ps1` and capture the first approved `dlp-policy-baseline.json` snapshot.
- [ ] Store the approved baseline in the designated evidence retention location.
- [ ] Review the generated deployment manifest and connection stubs with the compliance team.

## Exception workflow readiness

- [ ] Deploy the documented Power Automate exception approval flow.
- [ ] Confirm approver routing matches the selected tier.
- [ ] Validate the exception attestation log captures attestor, approval date, justification, and expiry.

## Monitoring readiness

- [ ] Configure the drift monitoring schedule using `scripts\Monitor-Compliance.ps1`.
- [ ] Confirm notifications route to the expected operations and compliance contacts.
- [ ] Review drift thresholds and escalation expectations for the selected tier.

## Evidence readiness

- [ ] Run `scripts\Export-Evidence.ps1` for a test reporting window.
- [ ] Validate `dlp-policy-baseline`, `policy-drift-findings`, and `exception-attestations` outputs.
- [ ] Confirm `.sha256` companion files are present and match the exported artifacts.

## Lab validation readiness

- [ ] Review the read-only lab contract `lab\05-dlp-policy-governance.lab.json` and confirm the first validation cycle is detect-only (`mutations: []`).
- [ ] Confirm the lab operator has View-Only DLP Compliance Management and that policy evidence retains `EnforcementPlanes` and `Locations` to prove Copilot scope.
- [ ] Verify the Microsoft source claims (external web-search restriction and sensitivity-label blocking generally available; sensitive-information-type prompt blocking and external-email exclusion preview) still match current Microsoft Learn guidance.
- [ ] Record honest `BLOCKED` or `NOT-APPLICABLE` dispositions when a preview feature, license, role, policy, or rollout is not present in the target tenant.

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Solution Owner | | | |
| Security Lead | | | |
| Compliance Lead | | | |
| Customer Understanding | ☐ Customer confirms they understand this solution uses representative sample data and requires tenant binding for production use. | | |
