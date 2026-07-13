# Delivery Checklist

Use this checklist to move solution 02 from documentation review into controlled deployment.

## 1. Scope and Dependency Readiness

- [ ] Confirm the target tenant and business units that will be included in the oversharing assessment wave.
- [ ] Verify solution 01-copilot-readiness-scanner has completed a baseline scan and exported usable output.
- [ ] Review upstream readiness results to identify high-volume or high-risk collaboration areas that should be scanned first.
- [ ] Confirm the selected governance tier (`baseline`, `recommended`, or `regulated`) matches rollout expectations.

## 2. Licensing and Platform Prerequisites

- [ ] Validate SharePoint Advanced Management feature entitlement by confirming the required base license and one documented entitlement path (Microsoft 365 Copilot, standalone SharePoint Advanced Management Plan 1, or Microsoft 365 E7 where available), or document the approved alternative control path.
- [ ] Validate Microsoft Purview Data Security Posture Management (DSPM) prerequisites for the target scenarios, including permissions, audit, Microsoft 365 Copilot user licensing, and any Edge, device, browser extension, or pay-as-you-go billing requirements that apply.
- [ ] Confirm SharePoint REST API and Microsoft Graph access from the execution environment.
- [ ] Confirm the required PowerShell modules are installed and approved for use in the administration workstation or automation host.

## 3. Administrative Access

- [ ] Confirm the operator has SharePoint Administrator and SharePoint Advanced Management Administrator rights for SharePoint/SAM tasks; use Compliance Administrator for Purview/DSPM tasks.
- [ ] Confirm guest access and external sharing visibility has been delegated where needed.
- [ ] Confirm security operations and compliance reviewers are identified for HIGH-risk findings.

## 4. Configuration Review

- [ ] Review `config\default-config.json` for evidence path, classifier weights, and default notification settings.
- [ ] Review the selected tier JSON for workload coverage, remediation mode, and evidence retention.
- [ ] Set an initial `maxSitesPerRun` value appropriate for pilot execution.
- [ ] Confirm Restricted SharePoint Search is treated as legacy transition guidance only (retiring, with new enablement blocked starting 2026-07-31) and that existing-tenant caveats remain explicit (temporary, up to 100 allowed sites, not a security boundary, no permission changes).
- [ ] Confirm Restricted Content Discovery planning is tracked separately as the go-forward per-site discoverability control for SharePoint (not OneDrive), including Purview audit expectations and delegated site-admin management approvals where needed.

## 5. Site Owner Communication Planning

- [ ] Identify the owner population that will receive remediation notices or attestation requests.
- [ ] Approve communication templates for HIGH, MEDIUM, and LOW findings.
- [ ] Define the escalation path for unresponsive site owners and business exceptions.
- [ ] Confirm how attestations will be captured, retained, and linked to remediation tickets.

## 6. Initial Scan Planning

- [ ] Start with detect-only mode before considering notify or auto-remediate behavior.
- [ ] Decide whether the first run will be SharePoint-only or include OneDrive and Teams.
- [ ] Plan for throttling management, run windows, and operational monitoring during large scans.
- [ ] Confirm how false positives will be sampled and reviewed after the first run.

## 7. Remediation Wave Planning

- [ ] Create Wave 1 for HIGH-risk findings that include customer PII, trading data, or regulated records.
- [ ] Create Wave 2 for MEDIUM-risk all-employee exposure that should be narrowed before Copilot expansion.
- [ ] Create Wave 3 for LOW-risk anomalies that can be handled during routine permission hygiene.
- [ ] Assign approval owners for guest access cleanup, Restricted Content Discovery changes, and site-level remediation.

## 8. Power Automate and Notification Readiness

- [ ] Confirm the Power Automate environment exists and is approved for governance workflows.
- [ ] Document connector availability for Teams, Outlook, SharePoint, and Approvals.
- [ ] Decide when to activate `SiteOwnerNotification` and `RemediationApproval` flows.
- [ ] Confirm notification channel ownership for `ORA-governance-alerts` or the tenant-equivalent channel.

## 9. Evidence and Audit Readiness

- [ ] Confirm evidence output storage is available and protected from tampering.
- [ ] Confirm each exported JSON file will have a companion `.sha256` file.
- [ ] Confirm regulated deployments retain evidence for the required duration and examiner review window.
- [ ] Validate that oversharing-findings, remediation-queue, and site-owner-attestations are all included in the final package.

## 10. Go-Live Decision

- [ ] Run `scripts\Deploy-Solution.ps1` with the selected tier and record the deployment manifest.
- [ ] Run the initial `Monitor-Compliance.ps1` scan and review findings with stakeholders.
- [ ] Approve remediation wave sequencing and notification timing.
- [ ] Run `Export-Evidence.ps1` and archive the resulting package and checksums.

## 11. Lab Contract Handoff

- [ ] Confirm `lab\02-oversharing-risk-assessment.lab.json` is attached to the handoff package for lab execution.
- [ ] Confirm handoff instructions preserve read-only/detect-only execution (`mutations: []`, all `mutationRef: null`).
- [ ] Confirm accepted dispositions are constrained to PASS, BLOCKED, or NOT-APPLICABLE with source evidence capture.

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Solution Owner | | | |
| Security Lead | | | |
| Compliance Lead | | | |
| Customer Understanding | ☐ Customer confirms they understand this solution uses representative sample data and requires tenant binding for production use. | | |
