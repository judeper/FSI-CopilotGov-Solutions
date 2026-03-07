# Deployment Guide

## Deployment Sequence

Follow this sequence to deploy solution 02 in a controlled manner.

## 1. Verify Upstream Output

Before deploying, confirm that solution 01-copilot-readiness-scanner has already produced output under its artifact path. The deployment script checks for upstream JSON evidence so the oversharing scan can be anchored to an existing baseline rather than launched blindly.

## 2. Run the Prerequisites Check

Review [prerequisites.md](prerequisites.md) and confirm:

- SharePoint Advanced Management licensing is available or formally documented as a gap
- DSPM for AI prerequisites are understood
- Required admin roles are assigned
- Network access to SharePoint REST API and Graph API is available

## 3. Review and Adjust Configuration

Inspect the JSON files under `config\`:

- `default-config.json` for common defaults, risk thresholds, and classifier weights
- `baseline.json` for minimal rollout posture
- `recommended.json` for multi-workload scanning with owner notifications
- `regulated.json` for extended evidence retention and required attestation

Tune `maxSitesPerRun`, workload scope, and notification settings before the first execution window.

## 4. Run Deploy-Solution.ps1

Example detect-only deployment:

```powershell
.\scripts\Deploy-Solution.ps1 `
  -ConfigurationTier recommended `
  -TenantId 00000000-0000-0000-0000-000000000000 `
  -ScanMode DetectOnly `
  -OutputPath .\artifacts\deployment
```

Expected outcomes:

- Selected configuration is merged and validated
- A placeholder SharePoint Advanced Management license check is recorded
- Upstream dependency status is captured
- A deployment manifest is written to the output path
- Restricted SharePoint Search is marked for enablement when configured

## 5. Execute the Initial Scan in Detect-Only Mode

Start with a constrained pilot:

```powershell
.\scripts\Monitor-Compliance.ps1 `
  -ConfigurationTier recommended `
  -TenantId 00000000-0000-0000-0000-000000000000 `
  -WorkloadsToScan sharePoint `
  -MaxSites 200 `
  -ExportPath .\artifacts\monitor
```

Why detect-only first:

- Validates classifier tuning before owners are contacted
- Helps identify false positives
- Reduces the chance of disrupting business access during pilot rollout

## 6. Review Findings

Review the `oversharing-findings` output for:

- HIGH-risk sites that expose customer PII, trading data, or regulated documents
- MEDIUM-risk sites shared with all employees
- LOW-risk anomalies that can be remediated during routine governance

Cross-check a sample of findings with site owners or SharePoint administrators before expanding scope.

## 7. Plan Remediation Waves

Recommended sequence:

1. Wave 1: HIGH-risk sites and items with guest access or anyone links
2. Wave 2: MEDIUM-risk broad internal exposure
3. Wave 3: LOW-risk cleanup and exception handling

Document the owner, due date, approval path, and rollback expectation for each wave.

## 8. Enable Notifications

After stakeholders approve the findings model:

- Switch to a tier or configuration that enables site owner notifications
- Implement the documentation-first `SiteOwnerNotification` flow in Power Automate
- Implement `RemediationApproval` for HIGH-risk approval routing

Do not enable automated notifications until site owner communication templates and escalation paths are approved.

## 9. Export Evidence

Run the evidence export after each major scan or remediation cycle:

```powershell
.\scripts\Export-Evidence.ps1 `
  -ConfigurationTier recommended `
  -TenantId 00000000-0000-0000-0000-000000000000 `
  -OutputPath .\artifacts\evidence `
  -PeriodStart (Get-Date).AddDays(-7) `
  -PeriodEnd (Get-Date) `
  -IncludeAttestations
```

The export writes:

- `oversharing-findings.json`
- `remediation-queue.json`
- `site-owner-attestations.json`
- A schema-aligned evidence package and `.sha256` checksum files

## 10. Rollback Guidance

If deployment settings need to be reversed:

1. Revert to the previous tier JSON or set `remediationMode` back to `detectOnly`
2. Disable or pause Power Automate notification flows
3. Revert any planned Restricted SharePoint Search configuration changes
4. Archive the evidence from the failed or rolled-back window for audit traceability
5. Re-run `Monitor-Compliance.ps1` in detect-only mode to confirm the tenant is back to the intended state

Rollback decisions should be documented whenever permissions, search scope, or owner notification behavior changes after approval.
