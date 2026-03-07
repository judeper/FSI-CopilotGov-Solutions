# Delivery Checklist Template

## Delivery Summary

- Solution:
- Solution Code:
- Governance Tier:
- Deployment Wave:
- Environment or Tenant:
- Delivery Owner:
- Evidence Outputs:

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
- [ ] Service desk or operations contact is named for steady-state support.
- [ ] Change-management approver is named for rollout windows and rollback decisions.

## Deployment Sequencing and Change Control

- [ ] Deployment wave order is approved using `DEPLOYMENT-GUIDE.md`.
- [ ] Non-production validation completed before production execution.
- [ ] Dependencies on readiness, oversharing cleanup, or upstream controls are documented.
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
