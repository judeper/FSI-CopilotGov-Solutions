# Delivery Checklist

## Delivery Summary

- Solution: Copilot Pages and Notebooks Compliance Gap Monitor
- Solution code: PNGM
- Version: v0.1.0
- Track: D
- Priority: P2
- Dependency: 06-audit-trail-manager
- Evidence outputs: gap-findings, compensating-control-log, preservation-exception-register
- Delivery objective: establish a documentation-led gap monitor for Copilot Pages, Loop-based content, and notebook preservation risks

## Pre-Deployment

- [ ] Compliance team briefed on current Copilot Pages and Notebooks retention, sharing, and Microsoft Purview eDiscovery gaps
- [ ] Legal team reviewed the preservation exception approach for SEC 17a-4 and FINRA 4511 scenarios
- [ ] Dependency solution 06-audit-trail-manager deployed and validated
- [ ] Tenant decision recorded for baseline, recommended, or regulated tier
- [ ] Named owners assigned for records management, Microsoft Purview eDiscovery operations, and collaboration governance

## Configuration Review

- [ ] Gap registry categories reviewed against current Microsoft 365 tenant configuration
- [ ] Compensating controls assessed for feasibility, staffing, and review cadence
- [ ] Preservation exception register approvers identified
- [ ] Platform update review cadence confirmed with Microsoft 365 operations team
- [ ] Sharing restriction procedures verified for Pages, Loop workspaces, and SharePoint-backed notebooks

## Deployment Steps

1. [ ] Run baseline monitoring to inventory current gap conditions.
2. [ ] Review discovered gaps and confirm severity, owner, and regulatory mappings.
3. [ ] Assign compensating controls for each open gap.
4. [ ] Obtain legal and compliance review for any preservation exceptions.
5. [ ] Run `scripts/Deploy-Solution.ps1` to initialize the gap register and deployment manifest.
6. [ ] Configure the Power Automate flow or equivalent review workflow for ongoing gap monitoring.
7. [ ] Run `scripts/Export-Evidence.ps1` to publish the initial evidence package.
8. [ ] Store exported evidence in the agreed governed repository.

## Post-Deployment Validation

- [ ] Gap register populated with the initial known gaps
- [ ] Compensating control entries documented with owners, approvers, and review dates
- [ ] Preservation exception register signed or left in draft pending formal approval
- [ ] Output artifacts written to the expected output path
- [ ] Quarterly review cycle entered into the compliance calendar
- [ ] Microsoft Message Center monitoring assigned to an accountable owner

## Evidence Review

- [ ] `gap-findings` present and current
- [ ] `compensating-control-log` present and linked to open gaps
- [ ] `preservation-exception-register` present with rationale and review history
- [ ] Evidence package JSON and SHA-256 hash file generated
- [ ] Control status entries reviewed for 2.11, 3.2, 3.3, and 3.11
- [ ] Evidence stored with the same retention and access controls used for other compliance documentation

## Customer Handover

- [ ] Compliance team understands this solution is a gap register, not an automated fix
- [ ] Operations team understands manual export and review expectations
- [ ] Legal reviewers understand the preservation exception register workflow
- [ ] Audit stakeholders know how to locate the evidence package and supporting records
- [ ] Support contacts recorded for quarterly review and escalation

## Sign-off

### Compliance Officer
- Name: ______________________________
- Signature: _________________________
- Date: ______________________________
- [ ] Approved for production use

### Legal Reviewer
- Name: ______________________________
- Signature: _________________________
- Date: ______________________________
- [ ] Preservation exception approach approved

### Project Delivery Lead
- Name: ______________________________
- Signature: _________________________
- Date: ______________________________
- [ ] Customer handover completed
