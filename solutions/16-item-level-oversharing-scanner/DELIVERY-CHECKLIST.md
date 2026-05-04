# Delivery Checklist

Use this checklist to move solution 16 from documentation review into controlled deployment.

## Delivery Summary

- Solution: 16-item-level-oversharing-scanner
- Solution Code: IOS
- Governance Tier:
- Deployment Wave:
- Environment or Tenant:
- Delivery Owner:
- Evidence Outputs: item-oversharing-findings, risk-scored-report, remediation-actions

## Files to Include

- README.md
- CHANGELOG.md
- DELIVERY-CHECKLIST.md
- docs\architecture.md
- docs\deployment-guide.md
- docs\evidence-export.md
- docs\prerequisites.md
- docs\troubleshooting.md
- scripts\Get-ItemLevelPermissions.ps1
- scripts\Export-OversharedItems.ps1
- scripts\Invoke-BulkRemediation.ps1
- scripts\Deploy-Solution.ps1
- scripts\Monitor-Compliance.ps1
- scripts\Export-Evidence.ps1
- config\default-config.json
- config\risk-thresholds.json
- config\remediation-policy.json
- config\baseline.json
- config\recommended.json
- config\regulated.json
- tests\16-item-level-oversharing-scanner.Tests.ps1
- Latest deployment manifest, WhatIf output, or change record
- Latest validation results and evidence package location

## 1. Scope and Dependency Readiness

- [ ] Confirm the target tenant and sites that will be included in the item-level scanning wave.
- [ ] Verify solution 02-oversharing-risk-assessment has completed a site-level assessment and identified high-risk sites.
- [ ] Review upstream site-level findings to identify document libraries that should be scanned first.
- [ ] Confirm the selected governance tier (`baseline`, `recommended`, or `regulated`) matches rollout expectations.

## 2. Licensing and Platform Prerequisites

- [ ] Validate SharePoint Advanced Management licensing for the tenant or document the approved alternative control path.
- [ ] Validate licensing and permissions for Microsoft Purview Data Security Posture Management (DSPM). If using DSPM for AI, identify it as DSPM for AI (classic).
- [ ] Confirm PnP PowerShell connectivity from the execution environment to the target SharePoint tenant.
- [ ] Confirm the required PowerShell modules are installed and approved for use in the administration workstation or automation host.

## 3. Administrative Access

- [ ] Confirm target-site site collection administrator access for delegated item-level permission enumeration, or document how a SharePoint Administrator/Global Administrator grants that access.
- [ ] Confirm Purview or Compliance Administrator roles are used only for DSPM/Purview review tasks, not as substitutes for target-site content access.
- [ ] For Microsoft Graph read-only permission listing, confirm documented permissions such as `Files.Read.All` or `Sites.Read.All` where applicable; reserve write/full-control permissions for approved remediation and document the specific API surface.
- [ ] Confirm security operations and compliance reviewers are identified for HIGH-risk findings.

## 4. Configuration Review

- [ ] Review `config\default-config.json` for evidence path, controls, and default settings.
- [ ] Review `config\risk-thresholds.json` for content-type weights and base risk scores.
- [ ] Review `config\remediation-policy.json` for remediation mode per risk tier.
- [ ] Review the selected tier JSON for scanning scope, retention, and evidence requirements.

## 5. Pre-Delivery Validation

- [ ] `python scripts/build-docs.py`
- [ ] `python scripts/validate-contracts.py`
- [ ] `python scripts/validate-solutions.py`
- [ ] `python scripts/validate-documentation.py`
- [ ] `pwsh -File scripts\deployment\Validate-Prerequisites.ps1`
- [ ] PowerShell syntax validation completed
- [ ] Solution-specific tests or scripted validations completed
- [ ] Evidence export reviewed for expected artifact names and matching `.sha256` files

## 6. Identity and Secrets Prep

- [ ] Operator identities and required workload-specific roles are documented.
- [ ] Secret, certificate, and connection-reference storage locations are approved and named.
- [ ] Expiration, rotation, and break-glass owners are documented.
- [ ] Notification endpoints and shared mailboxes are documented without storing secrets in the repository.
- [ ] The customer understands that tenant-specific runtime assets remain outside source control.

## 7. Ownership and RACI

- [ ] Platform owner is named and accountable for production execution.
- [ ] Solution operator is named for non-production and production runs.
- [ ] Identity administrator is named for app registration, certificate, and role assignments.
- [ ] Security and compliance approver is named for control-impact review.
- [ ] Service desk or operations contact is named for steady-state support.
- [ ] Change-management approver is named for rollout windows and rollback decisions.

## 8. Initial Scan Planning

- [ ] Start with a small set of high-risk sites identified by solution 02 before expanding scope.
- [ ] Decide whether to scan all document libraries or only those containing regulated content.
- [ ] Plan for PnP throttling management, run windows, and operational monitoring during large scans.
- [ ] Confirm how false positives will be sampled and reviewed after the first run.

## 9. Remediation Wave Planning

- [ ] Create Wave 1 for HIGH-risk items with anyone links or external sharing of sensitive content.
- [ ] Create Wave 2 for MEDIUM-risk items with organization-wide edit access or external sharing without sensitive labels.
- [ ] Create Wave 3 for LOW-risk items with broad group access that can be narrowed during routine governance.
- [ ] Assign approval owners for each remediation wave.

## 10. Deployment Sequencing and Change Control

- [ ] Deployment wave order is approved using `DEPLOYMENT-GUIDE.md`.
- [ ] Non-production validation completed before production execution.
- [ ] Dependencies on solution 02 site-level assessment are documented.
- [ ] Rollback or hold criteria are documented for each deployment wave.
- [ ] Evidence storage and reporting window are approved for the selected tier.

## 11. Evidence and Audit Readiness

- [ ] Confirm evidence output storage is available and protected from tampering.
- [ ] Confirm each exported JSON file will have a companion `.sha256` file.
- [ ] Confirm regulated deployments retain evidence for the required duration and examiner review window.
- [ ] Validate that item-oversharing-findings, risk-scored-report, and remediation-actions are all included in the final package.

## 12. Customer Validation

- [ ] Review `docs\prerequisites.md` with the customer platform owner.
- [ ] Run the scan, score, and remediation scripts in a non-production tenant and review the outputs.
- [ ] Confirm the evidence package metadata, control statuses, and artifact hashes.
- [ ] Customer has reviewed `docs\documentation-vs-runnable-assets-guide.md` and confirmed understanding of what is and is not deployed by the repository.

## 13. Go-Live Decision

- [ ] Run `scripts\Deploy-Solution.ps1` with the selected tier and record the deployment manifest.
- [ ] Run the initial scan → score → remediate pipeline and review findings with stakeholders.
- [ ] Approve remediation wave sequencing and approval routing.
- [ ] Run `Export-Evidence.ps1` and archive the resulting package and checksums.

## Sign-Off Items

- [ ] Platform owner sign-off completed
- [ ] Solution operator sign-off completed
- [ ] Identity administrator sign-off completed
- [ ] Security and compliance sign-off completed
- [ ] Service desk or operations sign-off completed
- [ ] Change-management sign-off completed
- [ ] Production execution date agreed

## Operational Cadence and Escalation

- [ ] Monitoring cadence is defined.
- [ ] Evidence export cadence is defined.
- [ ] Runbook review cadence is defined.
- [ ] Escalation severity model and response targets are documented.
- [ ] Service desk handoff or support-transition notes are complete.

## Documentation vs Runnable Assets Review

- [ ] The authoritative documentation set for the handoff is identified.
- [ ] Directly runnable scripts are identified and linked to the approved change window.
- [ ] Templates that require tenant-specific adaptation are identified.
- [ ] Runtime assets, secrets, and certificates that remain external to the repository are documented.
- [ ] Remaining manual tasks or operator decisions are recorded.

## Communication Template

- Summary of the delivered solution or wave:
- Approved deployment window:
- Primary operator:
- Escalation contact:
- Evidence location:
- Open decisions, exceptions, or manual follow-up items:
