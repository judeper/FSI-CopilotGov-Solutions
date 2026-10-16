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
- [ ] Review the Custom-template Copilot location separately from workload policies; confirm no administrative-unit scope and separate SIT and sensitivity-label rules.
- [ ] Record tenant rollout for preview prompt blocking; distinguish it from web-search-only restriction and label-based content exclusion that can retain citations.
- [ ] Confirm supported file/email coverage, the January 1, 2025 email boundary, and exclusion of calendar invites and direct prompt-uploaded file contents.

## Baseline readiness

- [ ] Run `scripts\Deploy-Solution.ps1` and capture the first approved `dlp-policy-baseline.json` snapshot.
- [ ] Store the approved baseline in the designated evidence retention location.
- [ ] Review the generated deployment manifest and connection stubs with the compliance team.

## Exception workflow readiness

- [ ] Deploy the documented Power Automate exception approval flow.
- [ ] Confirm licensing for the full connector set and Dataverse provisioning; the standard Approvals connector alone does not require Premium.
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
- [ ] Retain the sanitized product-boundary review record described in `docs\evidence-export.md`; do not accept local scaffold output as tenant-enforcement evidence.
- [ ] For separately authorized enforcement tests, account for up to four hours of policy propagation and reopen Office files after mid-session label changes.

Product reference: [Microsoft Learn Copilot DLP guidance](https://learn.microsoft.com/purview/dlp-microsoft365-copilot-location-learn-about). Technical re-verification on 2026-10-15 does not mark these tenant readiness checks complete.

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Solution Owner | | | |
| Security Lead | | | |
| Compliance Lead | | | |
| Customer Understanding | ☐ Customer confirms they understand this solution uses representative sample data and requires tenant binding for production use. | | |
