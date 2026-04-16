# Deployment Guide

## Deployment Sequence

Follow this sequence to deploy solution 19 in a controlled manner.

## 1. Confirm Copilot Tuning Eligibility

Before deploying, confirm the organization meets the minimum threshold of 5,000 Microsoft 365 Copilot licenses required for Copilot Tuning eligibility. Document any licensing gaps before proceeding.

## 2. Run the Prerequisites Check

Review [prerequisites.md](prerequisites.md) and confirm:

- Copilot licensing threshold is met or formally documented as a gap
- Required admin roles are assigned (Global Admin or Copilot Admin)
- Model risk management stakeholders are identified
- Network access to M365 Admin Center is available from the execution environment

## 3. Review and Adjust Configuration

Inspect the JSON files under `config\`:

- `default-config.json` for common defaults, controls, and evidence output settings
- `baseline.json` for tuning-disabled posture
- `recommended.json` for approval-gated tuning with model inventory
- `regulated.json` for full model risk management controls and extended retention

Align tuning governance settings with institutional model risk management policy before the first execution window.

## 4. Run Deploy-Solution.ps1

Example deployment:

```powershell
.\scripts\Deploy-Solution.ps1 `
  -ConfigurationTier recommended `
  -TenantId 00000000-0000-0000-0000-000000000000 `
  -OutputPath .\artifacts\deployment
```

Expected outcomes:

- Selected configuration is merged and validated
- Tuning governance prerequisites are checked
- A deployment manifest is written to the output path

## 5. Establish Baseline Governance (Tuning Disabled)

Start with the baseline tier to establish governance controls before enabling tuning:

- Confirm model risk management policy is documented
- Confirm approval workflow stakeholders are identified
- Confirm evidence storage is available and approved
- Validate monitoring scripts produce expected output with sample data

## 6. Enable Approval-Gated Tuning (Recommended Tier)

After validating baseline governance controls:

- Switch to the recommended tier configuration
- Confirm the approval workflow routes through data owner and model risk officer
- Monitor the first tuning requests through the full approval lifecycle
- Validate that model inventory tracking captures all required metadata

## 7. Monitor Tuning Governance Compliance

Monitor active tuning governance for compliance status:

```powershell
.\scripts\Monitor-Compliance.ps1 `
  -ConfigurationTier recommended `
  -TenantId 00000000-0000-0000-0000-000000000000
```

Review the output for:

- Tuning requests without completed approvals
- Tuned models without assigned owners
- Models approaching risk reassessment deadlines
- Governance coverage gaps

## 8. Export Evidence

Run the evidence export after each governance review cycle:

```powershell
.\scripts\Export-Evidence.ps1 `
  -ConfigurationTier recommended `
  -TenantId 00000000-0000-0000-0000-000000000000 `
  -OutputPath .\artifacts\evidence
```

The export writes:

- `tuning-requests.json`
- `model-inventory.json`
- `risk-assessments.json`
- A schema-aligned evidence package and `.sha256` checksum files

## 9. Progress to Regulated Tier

For examination-ready posture:

- Enable full multi-level approval (data owner, model risk officer, compliance officer)
- Enable owner attestation for all tuned models
- Set risk reassessment cadence to 30 days
- Extend evidence retention to 2555 days
- Confirm examiner-ready evidence format meets regulatory expectations

## 10. Rollback Guidance

If deployment settings need to be reversed:

1. Revert to the previous tier JSON or disable tuning in configuration
2. Archive evidence from the rolled-back window for audit traceability
3. Re-run `Monitor-Compliance.ps1` to confirm the tenant is back to the intended state
4. Document the rollback decision and rationale for compliance records

Rollback decisions should be documented whenever tuning enablement, approval workflow, or model risk management settings change after approval.
