# License Governance and ROI Tracker Delivery Checklist

## Delivery Summary

- Solution: License Governance and ROI Tracker
- Version: v0.1.1
- Track: C
- Priority: P1
- Dependency: 11-risk-tiered-rollout
- Evidence outputs: license-utilization-report, roi-scorecard, reallocation-recommendations

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
- scripts\SolutionConfig.ps1
- config\default-config.json
- config\baseline.json
- config\recommended.json
- config\regulated.json
- tests\08-license-governance-roi.Tests.ps1

## Pre-Delivery Validation

- [ ] Review `README.md` for solution-specific financial-services language and confirm all text is ASCII.
- [ ] Parse all PowerShell files in `scripts\` and `tests\` with the PowerShell parser and confirm zero syntax errors.
- [ ] Run `Invoke-Pester -Path .\tests\08-license-governance-roi.Tests.ps1`.
- [ ] Run `.\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId '<tenant-guid>' -OutputPath '.\artifacts\validation\deploy'`.
- [ ] Confirm the deployment manifest includes Graph scope planning, Dataverse tables, Power BI dataset notes, and dependency `11-risk-tiered-rollout`.
- [ ] Run `.\scripts\Monitor-Compliance.ps1 -ConfigurationTier recommended -OutputPath '.\artifacts\validation\monitor'`.
- [ ] Confirm the monitoring output includes utilization rate, inactive-seat details, recommended actions, and threshold values.
- [ ] Run `.\scripts\Export-Evidence.ps1 -ConfigurationTier recommended -OutputPath '.\artifacts\validation\evidence'`.
- [ ] Verify that the evidence package and companion `.sha256` file are created and can be validated with `Test-EvidencePackageHash`.
- [ ] Review generated artifact names for `license-utilization-report`, `roi-scorecard`, and `reallocation-recommendations`.

## Customer Validation

- [ ] Confirm Microsoft 365 Copilot licenses exist for the intended population and that seat counts align to finance-approved budgets.
- [ ] Confirm Copilot Dashboard and Viva impact feature availability for the tenant license counts if the customer wants the ROI scorecard populated beyond Microsoft 365 usage signals.
- [ ] Confirm Graph permissions `Reports.Read.All`, `LicenseAssignment.Read.All`, and `User.Read.All` have tenant admin consent; document `Directory.Read.All` only as a higher-privileged alternative when already approved.
- [ ] Confirm the selected governance tier matches the customer operating model for inactivity thresholds and notification strictness.
- [ ] Confirm exception handling rules for high-risk or protected users inherited from solution `11-risk-tiered-rollout`.
- [ ] Confirm Power BI workspace ownership, dataset refresh ownership, and report consumer access model.
- [ ] Confirm Dataverse retention and reviewer-access expectations for `fsi_cg_lgr_baseline`, `fsi_cg_lgr_finding`, and `fsi_cg_lgr_evidence`.
- [ ] Confirm chargeback or showback assumptions used for reallocation recommendations and ROI reporting.

## Evidence Acceptance Criteria

- [ ] Evidence package contains all mapped controls: 1.9, 4.5, 4.6, 4.8.
- [ ] Summary section shows a realistic `recordCount`, `findingCount`, and `exceptionCount`.
- [ ] Artifact entries point to generated files and include SHA-256 hashes.
- [ ] Evidence notes describe whether Viva Insights signals were enabled for the chosen tier.
- [ ] Reviewers can trace inactive-seat findings to a recommended action and approval path.

## Handoff Notes

- [ ] Share the deployment guide, architecture guide, and evidence-export instructions with the platform owner.
- [ ] Record the selected tier, reporting cadence, and approval workflow in the customer delivery notes.
- [ ] Document any known tenant-specific gaps, such as unavailable Viva Insights data or delayed Graph reporting, before go-live.

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Solution Owner | | | |
| Security Lead | | | |
| Compliance Lead | | | |
| Customer Understanding | ☐ Customer confirms they understand this solution uses representative sample data and requires tenant binding for production use. | | |
