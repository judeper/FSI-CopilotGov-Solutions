# Deployment Guide

## Deployment Sequence

Follow this sequence to deploy solution 19 in a controlled manner.

## 1. Confirm Copilot Tuning Eligibility

Before deploying, confirm the tenant is included in an eligible early access, Frontier, or public preview rollout, Copilot Tuning settings are visible in the Microsoft 365 admin center, and the organization has at least 5,000 Microsoft 365 Copilot licenses during public preview. Document licensing or preview availability gaps before proceeding.

## 2. Run the Prerequisites Check

Review [prerequisites.md](prerequisites.md) and confirm:

- Copilot licensing threshold and preview availability are met or formally documented as gaps
- Required admin roles are assigned (AI Administrator for Copilot and agent administration; Global Administrator only where broader tenant privileges are required)
- Model risk management stakeholders are identified
- Network access to the Microsoft 365 admin center is available from the execution environment

## 3. Review and Adjust Configuration

Inspect the JSON files under `config\`:

- `default-config.json` for common defaults, controls, and evidence output settings
- `baseline.json` for documenting a tuning-disabled or limited tenant posture
- `recommended.json` for approval-gated tuning with model inventory
- `regulated.json` for full model risk management controls and extended retention

Align tuning governance settings with institutional model risk management policy before the first execution window. The JSON tiers document the intended governance posture and do not enable, disable, or limit Copilot Tuning in the tenant.

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

## 5. Establish Baseline Governance (Tuning Disabled or Limited)

Start with the baseline tier to establish governance controls before expanding Copilot Tuning access. For eligible preview tenants, inspect the Copilot control system in the Microsoft 365 admin center because Copilot Tuning can be enabled by default when the eligibility threshold is met. If the baseline posture requires no new tuning activity, disable tuning or limit it to approved pilot users or groups in the admin center; repository scripts do not change tenant availability settings.

- Confirm model risk management policy is documented
- Confirm approval workflow stakeholders are identified
- Confirm evidence storage is available and approved
- Validate monitoring scripts produce expected output with sample data

## 6. Document Approval-Gated Tuning (Recommended Tier)

After validating baseline governance controls:

- Switch to the recommended tier configuration to document the approved governance posture
- In the Microsoft 365 admin center, enable tuning only for approved users or groups when the rollout decision is authorized
- Confirm the approval workflow routes through data owner and model risk officer
- Monitor the first tuning requests through the full approval lifecycle
- Validate that model inventory tracking includes all required metadata

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

1. Revert to the previous tier JSON to document the approved governance posture.
2. Disable or limit Copilot Tuning in the Microsoft 365 admin center when the rollback decision requires tenant-level availability changes.
3. Archive evidence from the rolled-back window for audit traceability.
4. Re-run `Monitor-Compliance.ps1` to confirm the documented governance posture matches the intended state.
5. Document the rollback decision and rationale for compliance records.

Rollback decisions should be documented whenever tuning availability, approval workflow, or model risk management settings change after approval.
