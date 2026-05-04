# Deployment Guide

## Deployment Sequence

Follow this sequence to deploy solution 18 in a controlled manner.

## 1. Verify Upstream Output

Before deploying, confirm that solution 02-oversharing-risk-assessment has produced risk-scored site output under its artifact path. The deployment script checks for upstream JSON evidence so access review creation can be prioritized against groups or access packages mapped to sites with documented oversharing risk.

## 2. Run the Prerequisites Check

Review [prerequisites.md](prerequisites.md) and confirm:

- Microsoft Entra ID Governance or Microsoft Entra Suite subscriptions are available or formally documented as a gap; Microsoft Entra ID P2 applies only where Microsoft Learn documents support for the planned access review scenario
- Required admin roles are assigned (User Administrator or Identity Governance Administrator for group or application reviews; Global Administrator only for break-glass)
- Microsoft Graph API access with AccessReview.ReadWrite.All permissions is available
- Network access to Microsoft Graph API endpoints is available

## 3. Review and Adjust Configuration

Inspect the JSON files under `config\`:

- `default-config.json` for common defaults, controls, and evidence output settings
- `review-schedule.json` for risk-tier review frequency and duration
- `reviewer-mapping.json` for reviewer assignment rules and escalation chain
- `baseline.json` for minimal rollout posture
- `recommended.json` for multi-tier reviews with escalation
- `regulated.json` for extended evidence retention and required attestation

Tune review cadence and reviewer assignments before the first execution window.

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
- Upstream dependency status from solution 02 is captured
- Microsoft Entra ID Governance or Microsoft Entra Suite licensing check is recorded
- A deployment manifest is written to the output path

## 5. Create Access Reviews for HIGH-Risk Site-Associated Resources

Start with a focused pilot:

```powershell
.\scripts\New-AccessReview.ps1 `
  -TenantId 00000000-0000-0000-0000-000000000000 `
  -RiskScoreInputPath .\artifacts\02-oversharing-risk-assessment\oversharing-findings.json `
  -ConfigPath .\config\review-schedule.json `
  -OutputPath .\artifacts\reviews
```

Why HIGH-risk first:

- Validates review workflow with the Microsoft Entra resources mapped to the most critical sites
- Helps identify reviewer assignment issues before expanding scope
- Reduces the chance of overwhelming reviewers with bulk review assignments

## 6. Monitor Review Progress

Monitor active reviews for pending decisions and approaching deadlines:

```powershell
.\scripts\Get-ReviewResults.ps1 `
  -TenantId 00000000-0000-0000-0000-000000000000 `
  -OutputPath .\artifacts\reviews
```

Review the output for:

- Pending decisions that need reviewer attention
- Reviews within 48 hours of expiry that need escalation
- Completed decisions ready for application

## 7. Apply Review Decisions

After stakeholder approval, apply completed deny decisions:

```powershell
.\scripts\Apply-ReviewDecisions.ps1 `
  -TenantId 00000000-0000-0000-0000-000000000000 `
  -ReviewDefinitionId <review-definition-id> `
  -OutputPath .\artifacts\reviews
```

Do not enable auto-apply until the decision review and escalation workflow has been validated with compliance stakeholders.

## 8. Expand to MEDIUM and LOW Risk Tiers

After validating the HIGH-risk review cycle:

- Enable MEDIUM-risk reviews (90-day cadence)
- Enable LOW-risk reviews (180-day cadence)
- Adjust reviewer assignments based on lessons learned

## 9. Export Evidence

Run the evidence export after each review cycle:

```powershell
.\scripts\Export-Evidence.ps1 `
  -ConfigurationTier recommended `
  -TenantId 00000000-0000-0000-0000-000000000000 `
  -OutputPath .\artifacts\evidence
```

The export writes:

- `access-review-definitions.json`
- `review-decisions.json`
- `applied-actions.json`
- A schema-aligned evidence package and `.sha256` checksum files

## 10. Rollback Guidance

If deployment settings need to be reversed:

1. Disable or delete access review definitions in Microsoft Entra ID
2. Revert to the previous tier JSON or disable auto-apply in configuration
3. Archive the evidence from the rolled-back window for audit traceability
4. Re-run `Monitor-Compliance.ps1` to confirm the tenant is back to the intended state
5. Document the rollback decision and rationale for compliance records

Rollback decisions should be documented whenever access review scope, reviewer assignments, or auto-apply behavior changes after approval.
