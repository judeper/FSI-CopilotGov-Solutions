# Copilot Connector and Plugin Governance Delivery Checklist

## Delivery Summary

- Solution: Copilot Connector and Plugin Governance
- Solution Code: CPG
- Version: v0.1.0
- Track: C
- Domain: operations-analytics
- Priority: P1
- Dependency: 09-feature-management-controller

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
- tests\10-connector-plugin-governance.Tests.ps1

## Pre-Delivery Validation

- [ ] `python .\scripts\validate-contracts.py`
- [ ] `python .\scripts\validate-solutions.py`
- [ ] PowerShell syntax validation completed for all solution `.ps1` files
- [ ] Pester tests passed for `tests\10-connector-plugin-governance.Tests.ps1`
- [ ] Evidence export produced both JSON and `.sha256` files

## Connector Governance Validation

- [ ] Confirm solution `09-feature-management-controller` is deployed and available for rollout gating.
- [ ] Validate Power Platform Admin API access to enumerate connectors in the target environment.
- [ ] Validate Microsoft Graph inventory access for app registrations tied to Graph connectors or plugins.
- [ ] Review `config\default-config.json` blocked connector IDs against current DLP and AppSource policy decisions.
- [ ] Review risk classification outcomes for Microsoft-built, certified third-party, custom, and blocked connector categories.
- [ ] Confirm the approval workflow path includes security review, CISO or DLP review, and approval or denial outcomes.
- [ ] Validate Dataverse tables `fsi_cg_cpg_baseline`, `fsi_cg_cpg_finding`, and `fsi_cg_cpg_evidence`.
- [ ] Run an initial inventory and confirm that unapproved connectors are recorded as findings.
- [ ] Confirm that high-risk connectors cannot move to production enablement without an approval record.
- [ ] Confirm that data-flow boundary attestations are recorded for external or regulated financial system access.

## Operational Validation

- [ ] Verify that `CPG-ConnectorInventory` executes on schedule and updates the inventory register.
- [ ] Verify that `CPG-ApprovalRouter` sends tasks to the configured reviewer mailbox.
- [ ] Verify that `CPG-DataFlowAudit` flags overdue approvals and expiring attestations.
- [ ] Validate Teams or mailbox notification routing for new or unapproved connectors.
- [ ] Confirm blocked connectors remain blocked in regulated scenarios.
- [ ] Confirm overdue approval SLA exceptions appear in the monitoring output.

## Evidence and Audit Readiness

- [ ] Export `connector-inventory` and confirm required fields are populated.
- [ ] Export `approval-register` and confirm review stages, approvers, and decisions are captured.
- [ ] Export `data-flow-attestations` and confirm source and destination boundaries are documented.
- [ ] Confirm evidence retention aligns to the selected tier.
- [ ] Confirm DORA third-party register reconciliation steps are documented for manual follow-up where needed.

## Customer Validation

- [ ] Review mapped controls, regulations, and implementation assumptions with security, compliance, and operations stakeholders.
- [ ] Confirm the selected governance tier matches the target Copilot deployment ring.
- [ ] Review the blocked connector list and approval SLA commitments with the security operations team.
- [ ] Run the deployment and monitoring scripts in a non-production tenant before production rollout.
- [ ] Review evidence export outputs with internal audit or supervisory control owners.

## Communication Template

Share the README, deployment guide, prerequisites, connector inventory results, approval workflow expectations, and evidence output definitions with the implementation team before production enablement begins.

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Solution Owner | | | |
| Security Lead | | | |
| Compliance Lead | | | |
| Customer Understanding | ☐ Customer confirms they understand this solution uses representative sample data and requires tenant binding for production use. | | |
