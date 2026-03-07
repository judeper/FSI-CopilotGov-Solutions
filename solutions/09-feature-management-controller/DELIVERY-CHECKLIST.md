# Copilot Feature Management Controller Delivery Checklist

## Delivery Summary

- Solution: Copilot Feature Management Controller
- Solution Code: FMC
- Version: v0.1.0
- Track: C
- Domain: operations-analytics
- Priority: P1

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
- tests\09-feature-management-controller.Tests.ps1

## Pre-Delivery Validation

- [ ] Confirm `config\default-config.json` and the tier file align on rollout rings, feature categories, and drift thresholds.
- [ ] Validate that Dataverse table names follow the `fsi_cg_{solution}_{purpose}` contract and resolve to `fsi_cg_fmc_baseline`, `fsi_cg_fmc_finding`, and `fsi_cg_fmc_evidence`.
- [ ] Run `powershell -NoProfile -File .\solutions\09-feature-management-controller\scripts\Deploy-Solution.ps1 -ConfigurationTier baseline -TenantId <tenant> -Environment Sandbox -BaselineOnly -WhatIf`.
- [ ] Run `powershell -NoProfile -File .\solutions\09-feature-management-controller\scripts\Monitor-Compliance.ps1 -ConfigurationTier baseline -BaselinePath .\solutions\09-feature-management-controller\config\baseline.json`.
- [ ] Run `powershell -NoProfile -File .\solutions\09-feature-management-controller\scripts\Export-Evidence.ps1 -ConfigurationTier baseline -OutputPath .\solutions\09-feature-management-controller\artifacts\validation`.
- [ ] PowerShell syntax validation completed for all updated scripts.
- [ ] Evidence export verified with a companion `.sha256` file.
- [ ] Pester tests pass for `tests\09-feature-management-controller.Tests.ps1`.

## Feature Management Validation

- [ ] Confirm Microsoft Graph beta rollout policy access to `/policies/featureRolloutPolicies`.
- [ ] Confirm Teams Admin Center policy ownership and export path for Teams Copilot settings.
- [ ] Confirm Power Platform Admin coverage for Copilot in Power Apps and Power Automate.
- [ ] Validate Preview Ring is limited to 5 percent of approved users.
- [ ] Validate Early Adopters ring is limited to 15 percent of approved users.
- [ ] Validate General Availability and Restricted ring logic matches the selected tier.
- [ ] Verify drift alert threshold is set to 3 unless approved otherwise.
- [ ] Verify documented approval references are present before ring promotion in regulated deployments.

## Evidence and Records

- [ ] `feature-state-baseline` captures feature ID, source system, expected ring, enablement state, and capture timestamp.
- [ ] `rollout-ring-history` records source ring, target ring, requester, approver, and change ticket reference.
- [ ] `drift-findings` records drift type, severity, baseline value, observed value, and remediation status.
- [ ] Evidence retention aligns to tier requirements, including 365 days for regulated deployments.
- [ ] Operations and compliance teams agree on evidence storage and review cadence.

## Customer Validation

- [ ] Review prerequisites and related controls with Microsoft 365, Teams, Power Platform, and compliance stakeholders.
- [ ] Confirm the chosen governance tier and target environment.
- [ ] Run baseline capture in a non-production or restricted pilot tenant first.
- [ ] Review drift findings and confirm remediation ownership for each supported workload.
- [ ] Review documented Power Automate flow definitions before production import.
- [ ] Review evidence export output and downstream dashboard or archive requirements.

## Communication Template

Share the README, architecture, deployment guide, prerequisites, and evidence expectations with the implementation team. Include the selected governance tier, approved rollout rings, drift threshold, and supervisory escalation path in the handoff package.
