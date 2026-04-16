# Regulatory Compliance Dashboard Delivery Checklist

## Delivery Summary

- Solution: Regulatory Compliance Dashboard
- Version: v0.1.0
- Track: C
- Priority: P0

## Files to Include

- README.md
- CHANGELOG.md
- DELIVERY-CHECKLIST.md
- docs/*.md
- scripts/*.ps1
- config/*.json
- tests/12-regulatory-compliance-dashboard.Tests.ps1

## Dependency Readiness

- [ ] Solution `06-audit-trail-manager` is deployed and exporting evidence in the target environment.
- [ ] Solution `11-risk-tiered-rollout` is deployed and exporting evidence in the target environment.
- [ ] Any additional upstream solutions required for the coverage matrix have exported at least one current evidence package.

## Platform Configuration

- [ ] Dataverse solution imported with tables `fsi_cg_rcd_baseline`, `fsi_cg_rcd_finding`, and `fsi_cg_rcd_evidence`.
- [ ] Connection references for Dataverse, Power BI, and Power Automate are healthy.
- [ ] Environment variables for evidence aggregation sources, freshness thresholds, workspace name, and package destinations are configured.
- [ ] Power BI workspace for the Regulatory Compliance Dashboard is created and accessible to deployment operators.
- [ ] Row-level security roles are defined for executive, control owner, and regulatory readiness audiences.

## Pre-Delivery Validation

- [ ] `pwsh scripts/Deploy-Solution.ps1 -ConfigurationTier baseline -WhatIf`
- [ ] `pwsh scripts/Monitor-Compliance.ps1 -ConfigurationTier baseline`
- [ ] PowerShell syntax validation completed for `Deploy-Solution.ps1`, `Monitor-Compliance.ps1`, and `Export-Evidence.ps1`.
- [ ] `Invoke-Pester tests\12-regulatory-compliance-dashboard.Tests.ps1`
- [ ] `Deploy-Solution.ps1` executed successfully in a non-production environment or with `-WhatIf`.
- [ ] `Monitor-Compliance.ps1` returns maturity score, stale evidence list, and controls-at-risk data.
- [ ] `Export-Evidence.ps1` generated the JSON payload and matching `.sha256` file.

## Dashboard Validation

- [ ] Power BI dataset is bound to the Dataverse tables and refreshes without credential errors.
- [ ] Control status RAG visuals show the expected implemented, partial, and monitor-only scoring.
- [ ] Evidence freshness thresholds are set for the selected tier and produce the expected stale evidence alerts.
- [ ] Framework coverage matrix includes the enabled regulatory frameworks for the selected tier.
- [ ] Examination readiness package generation has been tested for at least one regulation in the target environment.

## Customer Validation

- [ ] Review prerequisites, mapped controls, and regulatory alignment with the governance team.
- [ ] Confirm the selected governance tier and freshness threshold with compliance stakeholders.
- [ ] Validate that the dashboard supports compliance with current reporting needs without replacing source-system retention controls.
- [ ] Review known limitations around documentation-led Power BI assets and upstream solution dependencies.

## Communication Template

Share the README, architecture guide, delivery checklist, mapped controls, evidence export expectations, and row-level security plan with the implementation team before go-live.

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Solution Owner | | | |
| Security Lead | | | |
| Compliance Lead | | | |
| Customer Understanding | ☐ Customer confirms they understand this solution uses representative sample data and requires tenant binding for production use. | | |
