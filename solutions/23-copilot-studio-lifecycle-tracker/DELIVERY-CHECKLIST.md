# Delivery Checklist

## Delivery Summary

| Item | Value |
|------|-------|
| Solution | Copilot Studio Agent Lifecycle Tracker |
| Solution Code | CSLT |
| Version | v0.1.0 |
| Track | C |
| Priority | P1 |
| Primary Controls | 4.14, 4.13 |
| Supporting Controls | 1.10, 1.16, 4.5, 4.12 |
| Regulations | FFIEC IT Handbook (Operations Booklet), FINRA Rule 3110, OCC Bulletin 2023-17, Sarbanes-Oxley §§302/404 |
| Evidence Outputs | agent-lifecycle-inventory, publishing-approval-log, version-history, deprecation-evidence |
| Dependencies | None |

## Pre-Deployment

- [ ] Customer confirms Copilot Studio adoption posture and the environments in scope (development, test, production).
- [ ] Power Platform, Entra ID, and PowerShell prerequisites from `docs/prerequisites.md` are verified.
- [ ] Governance tier is selected: baseline, recommended, or regulated.
- [ ] Reviewer roles and approver lists are documented for the publishing approval log.
- [ ] Evidence output path and retention requirements are agreed with the customer records team.

## Configuration Review

- [ ] `config/default-config.json` reviewed for solution metadata and default evidence path.
- [ ] `config/baseline.json` reviewed for daily inventory and informational approval recording.
- [ ] `config/recommended.json` reviewed for single-approver publishing and 90-day review cadence.
- [ ] `config/regulated.json` reviewed for dual-approver publishing, 30-day review cadence, and extended retention.

## Deployment Steps

1. [ ] Open PowerShell 7.2 or later in `solutions/23-copilot-studio-lifecycle-tracker`.
2. [ ] Run `scripts\Deploy-Solution.ps1 -ConfigurationTier <tier> -WhatIf -Verbose` and review the planned manifest output.
3. [ ] Run `scripts\Deploy-Solution.ps1 -ConfigurationTier <tier> -OutputPath .\artifacts -Verbose` to create the deployment manifest.
4. [ ] Run `scripts\Monitor-Compliance.ps1 -ConfigurationTier <tier> -OutputPath .\artifacts -Verbose` to capture the initial lifecycle snapshot.
5. [ ] Run `scripts\Export-Evidence.ps1 -ConfigurationTier <tier> -OutputPath .\artifacts -Verbose` to generate the evidence package.

## Post-Deployment Validation

- [ ] Deployment manifest is present in `artifacts/` and reflects the selected tier.
- [ ] Evidence export completes without script errors.
- [ ] Each JSON evidence file has a matching `.sha256` companion file.
- [ ] Control status entries are populated for 4.14, 4.13, 1.10, 1.16, 4.5, and 4.12.

## Customer Handover

- [ ] README reviewed with the customer Copilot Studio admin and compliance stakeholders.
- [ ] Approver roster and supervisory escalation path documented.
- [ ] Evidence retention and storage responsibilities confirmed.

## Sign-Off

- [ ] Delivery engineer sign-off completed.
- [ ] Customer technical owner sign-off completed.
- [ ] Customer compliance owner sign-off completed.
- [ ] Production handover date recorded.
