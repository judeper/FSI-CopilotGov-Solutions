# Risk-Tiered Rollout Automation Delivery Checklist

## Delivery Summary

- Solution: Risk-Tiered Rollout Automation
- Solution code: RTR
- Version: v0.1.0
- Track: C
- Priority: P0
- Dependencies: 01-copilot-readiness-scanner

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
- tests\11-risk-tiered-rollout.Tests.ps1

## Pre-Delivery Validation

- [ ] `python scripts\validate-contracts.py`
- [ ] `python scripts\validate-solutions.py`
- [ ] PowerShell syntax validation completed for all scripts in `solutions\11-risk-tiered-rollout\scripts\`
- [ ] `Invoke-Pester` completed for `tests\11-risk-tiered-rollout.Tests.ps1`
- [ ] Exported evidence package verified with companion `.sha256` file

## Dependency Validation

- [ ] `01-copilot-readiness-scanner` is deployed in the target tenant
- [ ] Readiness scanner evidence package is no older than the configured freshness threshold
- [ ] Readiness evidence covers licensing, identity, and Purview signals for the intended cohort
- [ ] Stale or missing readiness evidence has a documented escalation path

## Rollout Configuration Validation

- [ ] Governance tier selected: `baseline`, `recommended`, or `regulated`
- [ ] Wave definitions match the approved rollout plan
- [ ] Tier 1, Tier 2, and Tier 3 classification rules were reviewed with HR, compliance, and IT operations stakeholders
- [ ] Copilot seat inventory covers the requested wave size plus rollback buffer
- [ ] Dataverse table names match the `fsi_cg_rtr_*` convention

## Wave 0 Pilot Validation

- [ ] Wave 0 cohort is limited to the approved Tier 1 pilot population
- [ ] `Deploy-Solution.ps1` previewed the Wave 0 manifest with `-WhatIf`
- [ ] Wave readiness checks identified blocked users and documented blockers
- [ ] Pilot support coverage and incident-routing contacts were validated
- [ ] Wave 0 success criteria were documented before licenses were assigned

## Expansion Gate Validation

- [ ] Gate criteria for the next wave were reviewed in `Monitor-Compliance.ps1`
- [ ] Approval workflow test completed for `Gate-Approval-Request`
- [ ] Tier 2 DLP and supervision controls were validated before any Tier 2 rollout
- [ ] Tier 3 CA policy, DLP, and audit trail prerequisites were validated before any Tier 3 rollout
- [ ] CAB approval was captured for regulated Wave 3 expansion

## Evidence and Reporting Validation

- [ ] `wave-readiness-log` was generated and reviewed by rollout operations
- [ ] `approval-history` includes approver name, role, decision, and timestamp
- [ ] `rollout-health-dashboard` reflects current blocked-user counts and wave health scores
- [ ] Evidence retention settings align to the selected governance tier
- [ ] Evidence notes use status values from the repository contract only

## Customer Handoff

- [ ] README and deployment guide shared with the implementation team
- [ ] Prerequisites and rollback procedures reviewed with tenant administrators
- [ ] Regulatory alignment reviewed with compliance stakeholders
- [ ] Known limitations and documentation-first assumptions explained to the rollout owner
