# Agent Lifecycle and Deployment Governance Delivery Checklist

## Delivery Summary

- Solution: Agent Lifecycle and Deployment Governance
- Solution Code: ALG
- Version: v0.1.0
- Track: C
- Domain: operations-analytics
- Priority: P0
- Dependencies: 09-feature-management-controller, 10-connector-plugin-governance

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
- tests\19-agent-lifecycle-governance.Tests.ps1

## Pre-Delivery Validation

- [ ] `python .\scripts\validate-contracts.py`
- [ ] `python .\scripts\validate-solutions.py`
- [ ] PowerShell syntax validation completed for all solution `.ps1` files
- [ ] Pester tests passed for `tests\19-agent-lifecycle-governance.Tests.ps1`
- [ ] Evidence export produced both JSON and `.sha256` files

## Agent Lifecycle Governance Validation

- [ ] Confirm solution `09-feature-management-controller` is deployed and available for rollout gating.
- [ ] Confirm solution `10-connector-plugin-governance` is deployed for coordinated extensibility governance.
- [ ] Validate M365 Admin Center access for agent request and approval workflow management.
- [ ] Validate Copilot Studio admin access for agent catalog and sharing restriction configuration.
- [ ] Review `config\default-config.json` agent risk categories against current agent deployment policy decisions.
- [ ] Review risk classification outcomes for Microsoft-published, IT-developed, user-created, and blocked agent categories.
- [ ] Confirm the approval workflow path includes security review, business owner attestation, and CISO sign-off outcomes.
- [ ] Validate Dataverse tables `fsi_cg_alg_baseline`, `fsi_cg_alg_finding`, and `fsi_cg_alg_evidence`.
- [ ] Run an initial agent inventory and confirm that unapproved agents are recorded as findings.
- [ ] Confirm that user-created agents cannot move to production enablement without an approval record.
- [ ] Confirm that sharing policy audit records reflect org-wide sharing restrictions and external sharing settings.

## Operational Validation

- [ ] Verify that `ALG-AgentRegistry` executes on schedule and updates the agent inventory register.
- [ ] Verify that `ALG-ApprovalRouter` sends tasks to the configured reviewer mailbox.
- [ ] Verify that `ALG-SharingPolicyAudit` flags sharing policy drift and overdue approvals.
- [ ] Validate Teams or mailbox notification routing for new or unapproved agents.
- [ ] Confirm blocked agents remain blocked in regulated scenarios.
- [ ] Confirm overdue approval SLA exceptions appear in the monitoring output.

## Evidence and Audit Readiness

- [ ] Export `agent-registry` and confirm required fields are populated.
- [ ] Export `approval-register` and confirm review stages, approvers, and decisions are captured.
- [ ] Export `sharing-policy-audit` and confirm org-wide sharing restrictions and catalog visibility settings are documented.
- [ ] Confirm evidence retention aligns to the selected tier.
- [ ] Confirm DORA third-party register reconciliation steps are documented for manual follow-up where needed.

## Customer Validation

- [ ] Review mapped controls, regulations, and implementation assumptions with security, compliance, and operations stakeholders.
- [ ] Confirm the selected governance tier matches the target Copilot deployment ring.
- [ ] Review the agent risk categories and approval SLA commitments with the security operations team.
- [ ] Run the deployment and monitoring scripts in a non-production tenant before production rollout.
- [ ] Review evidence export outputs with internal audit or supervisory control owners.

## Communication Template

Share the README, deployment guide, prerequisites, agent registry results, approval workflow expectations, sharing policy audit outcomes, and evidence output definitions with the implementation team before production enablement begins.
