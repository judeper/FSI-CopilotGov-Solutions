# Delivery Checklist

Use this checklist to move solution 18 from documentation review into controlled deployment.

## 1. Scope and Dependency Readiness

- [ ] Confirm the target tenant and business units that will be included in access review automation.
- [ ] Verify solution 02-oversharing-risk-assessment has completed a risk-scored scan and exported usable output.
- [ ] Review upstream risk scores to identify HIGH-risk sites that should receive access reviews first.
- [ ] Confirm the selected governance tier (`baseline`, `recommended`, or `regulated`) matches rollout expectations.

## 2. Licensing and Platform Prerequisites

- [ ] Validate Entra ID Governance P2 licensing for the tenant or document the approved alternative control path.
- [ ] Validate Microsoft 365 E5 Compliance or equivalent capability for access review and governance features.
- [ ] Confirm Microsoft Graph API access from the execution environment with AccessReview.ReadWrite.All permissions.
- [ ] Confirm the required PowerShell modules are installed and approved for use in the administration workstation or automation host.

## 3. Administrative Access

- [ ] Confirm the operator has Global Admin, Identity Governance Admin, or User Admin rights as required for access review management.
- [ ] Confirm SharePoint Admin access is available for resolving site owner information.
- [ ] Confirm compliance reviewers are identified for HIGH-risk review escalation.

## 4. Configuration Review

- [ ] Review `config\default-config.json` for evidence path, controls, and default settings.
- [ ] Review `config\review-schedule.json` for review cadence and duration by risk tier.
- [ ] Review `config\reviewer-mapping.json` for reviewer assignment and escalation chain.
- [ ] Review the selected tier JSON for retention, auto-apply settings, and evidence requirements.

## 5. Access Review Planning

- [ ] Identify the SharePoint sites that will receive access reviews in the first wave.
- [ ] Confirm site owner information is accurate and current in SharePoint site properties.
- [ ] Define the escalation path for reviews that approach expiry without completed decisions.
- [ ] Confirm how deny decisions will be reviewed, approved, and applied.

## 6. Initial Deployment Planning

- [ ] Start with HIGH-risk sites only before expanding to MEDIUM and LOW tiers.
- [ ] Plan for Graph API throttling management during bulk review creation.
- [ ] Confirm how review results will be monitored and reported to compliance stakeholders.
- [ ] Decide when to enable auto-apply of deny decisions versus manual review application.

## 7. Reviewer and Escalation Readiness

- [ ] Confirm site owners understand their role as primary reviewers.
- [ ] Confirm compliance officers are identified as fallback reviewers.
- [ ] Define the CISO escalation path for unresponsive reviewers.
- [ ] Approve communication templates for review assignment notifications.

## 8. Integration with Upstream Solutions

- [ ] Confirm solution 02 risk score output is available and current.
- [ ] Verify risk tier classification aligns with review cadence expectations.
- [ ] Confirm the risk score input path is accessible from the execution environment.
- [ ] Document any manual overrides or exceptions to risk-based prioritization.

## 9. Evidence and Audit Readiness

- [ ] Confirm evidence output storage is available and protected from tampering.
- [ ] Confirm each exported JSON file will have a companion `.sha256` file.
- [ ] Confirm regulated deployments retain evidence for the required duration and examiner review window.
- [ ] Validate that access-review-definitions, review-decisions, and applied-actions are all included in the final package.

## 10. Go-Live Decision

- [ ] Run `scripts\Deploy-Solution.ps1` with the selected tier and record the deployment manifest.
- [ ] Run `scripts\New-AccessReview.ps1` to create initial review definitions for HIGH-risk sites.
- [ ] Run `scripts\Get-ReviewResults.ps1` and verify review monitoring is working as expected.
- [ ] Run `scripts\Export-Evidence.ps1` and archive the resulting package and checksums.

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Solution Owner | | | |
| Security Lead | | | |
| Compliance Lead | | | |
| Customer Understanding | ☐ Customer confirms they understand this solution uses representative sample data and requires tenant binding for production use. | | |
