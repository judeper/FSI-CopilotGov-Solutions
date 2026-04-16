# Sensitivity Label Coverage Auditor Delivery Checklist

## Delivery Summary

- Solution: Sensitivity Label Coverage Auditor
- Version: v0.2.0
- Solution code: SLA
- Track: A
- Priority: P1
- Phase: 2

## Governance Preparation

- [ ] Verify the sensitivity label taxonomy is finalized before the audit starts.
- [ ] Confirm the organization has approved the Public, Internal, Confidential, Highly Confidential, and Restricted label hierarchy for Copilot use.
- [ ] Confirm Microsoft Purview Information Protection licensing is available for the target tenant.
- [ ] Confirm Microsoft Purview Suite (formerly Microsoft 365 E5 Compliance) or equivalent licensing is approved for the solution scope.
- [ ] Confirm required admin roles are assigned to the deployment and evidence export operators.

## Dependency Readiness

- [ ] Confirm `01-copilot-readiness-scanner` baseline execution is complete.
- [ ] Confirm `02-oversharing-risk-assessment` initial scan is complete.
- [ ] Collect readiness outputs that define the in-scope workloads and regulated business units.
- [ ] Identify regulated data store sites for priority scanning.
- [ ] Confirm oversharing findings are available to cross-reference with unlabeled content locations.

## Deployment Configuration

- [ ] Review `config\default-config.json` for workload scope, taxonomy, thresholds, and remediation manifest limits.
- [ ] Review the selected tier file in `config\` for retention, alert thresholds, and alerting mode.
- [ ] Confirm `prioritySites` is populated for regulated SharePoint or OneDrive containers when applicable.
- [ ] Review auto-labeling policy coverage and identify any gaps that must be handled by remediation waves.
- [ ] Confirm Graph permissions are approved for label policy, files, sites, and mail coverage collection.

## Operational Planning

- [ ] Run `scripts\Deploy-Solution.ps1` in a non-production tenant or approved change window first.
- [ ] Run the initial label coverage scan with `scripts\Monitor-Compliance.ps1`.
- [ ] Review the `label-gap-findings` output with records management and data owners.
- [ ] Plan the remediation wave with data owners before any bulk labeling activity.
- [ ] Respect the auto-labeling cap of 100,000 files per day per tenant when scheduling remediation.
- [ ] Confirm Exchange mailboxes that require enhanced coverage are identified before production rollout.

## Evidence and Audit Readiness

- [ ] Run `scripts\Export-Evidence.ps1` and confirm all JSON artifacts have companion `.sha256` files.
- [ ] Verify the evidence package includes `label-coverage-report`, `label-gap-findings`, and `remediation-manifest`.
- [ ] Confirm the control status mapping matches 1.5, 2.2, 3.11, and 3.12.
- [ ] Confirm regulated tier evidence retention is configured for seven years where required.
- [ ] Confirm examiner-ready evidence storage assumptions are documented for regulated deployments.

## Final Validation

- [ ] PowerShell syntax validation completed for all three scripts.
- [ ] Targeted Pester validation completed for the solution folder.
- [ ] README, deployment guide, evidence guide, and troubleshooting content reviewed by the solution owner.
- [ ] Delivery handoff includes remediation assumptions, limitations, and Power Automate documentation-first notes.

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Solution Owner | | | |
| Security Lead | | | |
| Compliance Lead | | | |
| Customer Understanding | ☐ Customer confirms they understand this solution uses representative sample data and requires tenant binding for production use. | | |
