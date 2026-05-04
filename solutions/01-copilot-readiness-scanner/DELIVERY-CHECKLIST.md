# Copilot Readiness Assessment Scanner Delivery Checklist

## Delivery Summary

- Solution: Copilot Readiness Assessment Scanner
- Solution Code: CRS
- Version: v0.2.1
- Track: A
- Priority: P0
- Evidence Outputs: readiness-scorecard, data-hygiene-findings, remediation-plan

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
- scripts\CRS-Common.psm1
- config\default-config.json
- config\baseline.json
- config\recommended.json
- config\regulated.json
- tests\01-copilot-readiness-scanner.Tests.ps1

## Pre-Deployment Checks

- [ ] Confirm the target tenant is in scope for controls 1.1, 1.5, 1.6, 1.7, and 1.9.
- [ ] Confirm the selected governance tier matches customer supervisory expectations and record retention requirements.
- [ ] Confirm PowerShell 7.x is installed on the operator workstation.
- [ ] Confirm `Microsoft.Graph`, `ExchangeOnlineManagement`, `PnP.PowerShell`, and `MicrosoftTeams` modules are installed.
- [ ] Confirm the operator has Global Administrator rights or the documented combination of workload-specific roles.
- [ ] Confirm outbound access to Microsoft Graph, Purview, SharePoint Online, Teams, and Power Platform admin endpoints.
- [ ] Confirm the output location for evidence artifacts is approved for regulated data handling.
- [ ] Confirm the customer understands that the solution supports compliance with regulations but does not replace legal or control-owner review.

## Solution Validation Before Handover

- [ ] `pwsh -Command "Invoke-Pester tests/ -Passthru"` — Pester tests pass
- [ ] PowerShell syntax validation completed for all three scripts and `CRS-Common.psm1`
- [ ] Pester test file executed successfully
- [ ] Tier configuration values reviewed for retention, threshold, notification, and scan scope
- [ ] Evidence export verified to create JSON artifacts and matching `.sha256` files
- [ ] Power BI consumers have confirmed the expected JSON artifact naming and folder structure

## Customer Validation Steps

- [ ] Review [docs/prerequisites.md](./docs/prerequisites.md) with the customer platform owner.
- [ ] Review [docs/deployment-guide.md](./docs/deployment-guide.md) and confirm the deployment sequence for the selected tier.
- [ ] Run `scripts\Deploy-Solution.ps1` in a non-production tenant and review the generated deployment manifest.
- [ ] Run `scripts\Monitor-Compliance.ps1` across all six domains to create a baseline readiness snapshot.
- [ ] Validate that the readiness scorecard reflects known tenant conditions for licensing, identity, Defender, Purview, Power Platform, and Copilot configuration.
- [ ] Run `scripts\Export-Evidence.ps1` for a defined reporting period and verify the package metadata, control statuses, and artifact hashes.
- [ ] Review exception handling expectations for manual sensitivity label review, guest access validation, and immutable storage controls.

## Sign-Off Items

- [ ] Solution owner sign-off completed
- [ ] Customer security lead sign-off completed
- [ ] Customer compliance or records management sign-off completed
- [ ] Customer collaboration platform owner sign-off completed
- [ ] Evidence storage location approved for the selected tier
- [ ] Monitoring cadence and escalation path approved
- [ ] Production execution date agreed

## Handover Notes

- Provide the customer with the README, deployment guide, prerequisites, troubleshooting guide, and evidence export documentation.
- Record the selected governance tier, output path, and tenant identifier used for the initial baseline.
- Document any manual remediation actions that remain outside the current automation scope.
