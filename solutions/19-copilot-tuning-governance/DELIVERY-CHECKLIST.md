# Delivery Checklist

Use this checklist to move solution 19 from documentation review into controlled deployment.

## Delivery Summary

- Solution: Copilot Tuning Governance
- Solution Code: CTG
- Governance Tier:
- Deployment Wave:
- Environment or Tenant:
- Delivery Owner:
- Evidence Outputs: tuning-requests, model-inventory, risk-assessments

## Files to Include

- README.md
- CHANGELOG.md
- DELIVERY-CHECKLIST.md
- docs\architecture.md
- docs\deployment-guide.md
- docs\evidence-export.md
- docs\prerequisites.md
- docs\troubleshooting.md
- scripts\Deploy-Solution.ps1
- scripts\Monitor-Compliance.ps1
- scripts\Export-Evidence.ps1
- config\default-config.json
- config\baseline.json
- config\recommended.json
- config\regulated.json
- tests\*.Tests.ps1
- Latest deployment manifest, WhatIf output, or change record
- Latest validation results and evidence package location

## Pre-Delivery Validation

- [ ] `python scripts/build-docs.py`
- [ ] `python scripts/validate-contracts.py`
- [ ] `python scripts/validate-solutions.py`
- [ ] `python scripts/validate-documentation.py`
- [ ] `pwsh -File scripts\deployment\Validate-Prerequisites.ps1`
- [ ] PowerShell syntax validation completed
- [ ] Solution-specific tests or scripted validations completed
- [ ] Evidence export reviewed for expected artifact names and matching `.sha256` files

## 1. Scope and Tuning Readiness

- [ ] Confirm the target tenant and business units that will be governed by tuning controls.
- [ ] Verify the organization has 5,000 or more Copilot licenses, meeting the Copilot Tuning eligibility threshold.
- [ ] Confirm model risk management stakeholders are identified and available for tuning approval workflows.
- [ ] Confirm the selected governance tier (`baseline`, `recommended`, or `regulated`) matches rollout expectations.

## 2. Licensing and Platform Prerequisites

- [ ] Validate Microsoft 365 Copilot licensing for the tenant (minimum 5,000 seats for Tuning eligibility).
- [ ] Confirm M365 Admin Center access is available for Copilot Tuning configuration review.
- [ ] Confirm the required PowerShell modules are installed and approved for use in the administration workstation or automation host.

## 3. Administrative Access

- [ ] Confirm the operator has Global Admin or Copilot Admin rights as required for tuning governance management.
- [ ] Confirm model risk management officer is identified for tuning request approval.
- [ ] Confirm compliance reviewers are identified for post-tuning risk assessment review.

## 4. Configuration Review

- [ ] Review `config\default-config.json` for evidence path, controls, and default settings.
- [ ] Review the selected tier JSON for tuning enablement, approval gates, and evidence requirements.
- [ ] Confirm tuning approval workflow settings match institutional model risk management policy.

## 5. Tuning Governance Planning

- [ ] Identify business units that may submit tuning requests in the first governance wave.
- [ ] Define the approval chain for tuning requests (data owner, model risk officer, compliance officer).
- [ ] Define the risk assessment criteria for pre-tuning data review and post-tuning validation.
- [ ] Confirm how tuned model lifecycle events will be tracked and reported.

## Identity and Secrets Prep

- [ ] Operator identities and required workload-specific roles are documented.
- [ ] Secret, certificate, and connection-reference storage locations are approved and named.
- [ ] Expiration, rotation, and break-glass owners are documented.
- [ ] Notification endpoints and shared mailboxes are documented without storing secrets in the repository.
- [ ] The customer understands that tenant-specific runtime assets remain outside source control.

## Ownership and RACI

- [ ] Platform owner is named and accountable for production execution.
- [ ] Solution operator is named for non-production and production runs.
- [ ] Identity administrator is named for app registration, certificate, and role assignments.
- [ ] Security and compliance approver is named for control-impact review.
- [ ] Model risk management officer is named for tuning approval decisions.
- [ ] Service desk or operations contact is named for steady-state support.
- [ ] Change-management approver is named for rollout windows and rollback decisions.

## Deployment Sequencing and Change Control

- [ ] Deployment wave order is approved using `DEPLOYMENT-GUIDE.md`.
- [ ] Non-production validation completed before production execution.
- [ ] Rollback or hold criteria are documented for each deployment wave.
- [ ] Evidence storage and reporting window are approved for the selected tier.

## Customer Validation

- [ ] Review `docs\getting-started\prerequisites.md` with the customer platform owner.
- [ ] Review `docs\getting-started\identity-and-secrets-prep.md` with the identity or security owner.
- [ ] Review `docs\operational-handbook.md`, `docs\operational-raci.md`, and `docs\operational-cadence.md` with the steady-state operations team.
- [ ] Review `docs\escalation-procedures.md` with support and compliance stakeholders.
- [ ] Run the deployment and monitoring scripts in a non-production tenant and review the outputs.
- [ ] Confirm the evidence package metadata, control statuses, and artifact hashes.
- [ ] Customer has reviewed `docs\documentation-vs-runnable-assets-guide.md` and confirmed understanding of what is and is not deployed by the repository.

## Sign-Off Items

- [ ] Platform owner sign-off completed
- [ ] Solution operator sign-off completed
- [ ] Identity administrator sign-off completed
- [ ] Security and compliance sign-off completed
- [ ] Model risk management officer sign-off completed
- [ ] Service desk or operations sign-off completed
- [ ] Change-management sign-off completed
- [ ] Production execution date agreed

## Evidence and Audit Readiness

- [ ] Confirm evidence output storage is available and protected from tampering.
- [ ] Confirm each exported JSON file will have a companion `.sha256` file.
- [ ] Confirm regulated deployments retain evidence for the required duration and examiner review window.
- [ ] Validate that tuning-requests, model-inventory, and risk-assessments are all included in the final package.

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
