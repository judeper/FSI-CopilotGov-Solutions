# Delivery Checklist — SharePoint Permissions Drift Detection

> Use this checklist to track readiness before deploying Solution 17 in a customer environment.

---

## 1. Scope and Dependency Readiness

- [ ] Solution 02 (Oversharing Risk Assessment) has been deployed or reviewed
- [ ] Target SharePoint site scope has been agreed with the customer
- [ ] Exclusion list for sites not subject to drift monitoring has been documented
- [ ] Baseline capture window has been scheduled during a known-good permissions state
- [ ] Drift scan frequency has been agreed (default: every 24 hours)

## 2. Licensing and Platform Prerequisites

- [ ] Microsoft 365 E5 or E5 Compliance licenses are confirmed for target users
- [ ] SharePoint Advanced Management license is available (if required for scope)
- [ ] PnP.PowerShell module is installed and updated to the minimum required version
- [ ] Microsoft.Graph PowerShell SDK is installed with required scopes
- [ ] Power Automate environment is provisioned for approval-gate workflows

## 3. Administrative Access

- [ ] SharePoint Administrator role is assigned for baseline capture and drift scan
- [ ] Global Reader or Security Reader role is confirmed for read-only operations
- [ ] Application registration is created with Sites.FullControl.All (or Sites.Read.All for read-only mode)
- [ ] Mail.Send permission is granted for drift alert notifications
- [ ] Conditional Access policies allow the service account to authenticate

## 4. Configuration Review

- [ ] `config/default-config.json` has been reviewed and customized
- [ ] `config/baseline-config.json` scope settings match the agreed site inventory
- [ ] `config/auto-revert-policy.json` reversion mode is set appropriately (approval-gate vs. auto-revert)
- [ ] Configuration tier (baseline / recommended / regulated) has been selected
- [ ] Approver list in `auto-revert-policy.json` has been updated with actual email addresses

## 5. Baseline Capture Planning

- [ ] Initial baseline capture has been scheduled during a maintenance window
- [ ] Site owners have been notified that current permissions will be recorded as the approved state
- [ ] Baseline retention policy (default: 90 days) has been confirmed
- [ ] Baseline output directory has been created and access-restricted

## 6. Drift Scan Planning

- [ ] Drift scan schedule has been configured (e.g., Azure Automation runbook or Task Scheduler)
- [ ] Alert recipient for HIGH-risk drift has been confirmed
- [ ] Risk classification thresholds have been reviewed against institution risk appetite
- [ ] Maximum sites per run has been validated against tenant size

## 7. Reversion and Approval Workflow

- [ ] Approval-gate workflow has been tested with a sample drift report
- [ ] Approvers have been notified of their role in the drift reversion process
- [ ] Escalation path for timed-out approvals has been documented
- [ ] Auto-revert scope (if enabled) has been restricted to appropriate risk tiers
- [ ] Reversion rollback procedure has been documented and tested

## 8. Power Automate and Notification Readiness

- [ ] Power Automate approval flow has been created per deployment guide
- [ ] Email notification templates have been reviewed and customized
- [ ] Teams channel for drift alerts has been created (if applicable)
- [ ] Notification throttling settings have been configured to prevent alert fatigue

## 9. Evidence and Audit Readiness

- [ ] Evidence output directory has been created with appropriate access controls
- [ ] SHA-256 integrity verification process has been documented
- [ ] Evidence retention period aligns with regulatory requirements (regulated: 7 years)
- [ ] Export-DriftEvidence.ps1 has been tested with sample drift data
- [ ] Evidence package format has been reviewed with compliance team

## 10. Go-Live Decision

- [ ] All prerequisite checks pass via Deploy-Solution.ps1
- [ ] Initial baseline has been captured and validated
- [ ] First drift scan has been run and results reviewed
- [ ] Stakeholder sign-off has been obtained (IT Security, Compliance, SharePoint Admin)
- [ ] Runbook for ongoing operations has been documented
- [ ] Escalation contacts for production issues have been confirmed
