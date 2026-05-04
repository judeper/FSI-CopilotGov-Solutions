# Delivery Checklist

## Delivery Summary

| Item | Value |
|------|-------|
| Solution | Cross-Tenant Agent Federation Auditor |
| Solution Code | CTAF |
| Version | v0.1.1 |
| Track | B |
| Priority | P1 |
| Primary Controls | 2.17, 2.16 |
| Supporting Controls | 1.10, 2.13, 2.14, 4.13 |
| Regulations | GLBA §501(b), FFIEC IT Handbook (Information Security Booklet), SEC Reg S-P, OCC Bulletin 2023-17, FINRA Rule 3110 |
| Evidence Outputs | agent-federation-inventory, cross-tenant-trust-assessment, mcp-trust-relationship-log, agent-id-attestation-evidence |
| Dependencies | (none) |

## Pre-Deployment

- [ ] Customer confirms which tenants, Copilot Studio environments, and MCP endpoints are in scope for cross-tenant review.
- [ ] Entra, Copilot Studio, and PowerShell prerequisites from `docs/prerequisites.md` are verified.
- [ ] Governance tier is selected: baseline, recommended, or regulated.
- [ ] Evidence output path and retention requirements are agreed with the customer records team.

## Configuration Review

- [ ] `config/default-config.json` reviewed for solution metadata and default evidence path.
- [ ] `config/baseline.json` reviewed for 90-day federation review cadence and optional MCP connection/authentication review.
- [ ] `config/recommended.json` reviewed for 30-day cadence, required MCP connection/authentication review, and required Agent ID identity-governance review.
- [ ] `config/regulated.json` reviewed for 7-day cadence, MCP connection revalidation, customer-defined Agent ID credential review, and 1825-day retention.

## Deployment Steps

1. [ ] Open PowerShell 7.2 or later in `solutions/21-cross-tenant-agent-federation-auditor`.
2. [ ] Run `scripts\Deploy-Solution.ps1 -ConfigurationTier <tier> -WhatIf -Verbose` and review the planned manifest.
3. [ ] Run `scripts\Deploy-Solution.ps1 -ConfigurationTier <tier> -OutputPath .\artifacts -Verbose` to create the deployment manifest.
4. [ ] Run `scripts\Monitor-Compliance.ps1 -ConfigurationTier <tier> -OutputPath .\artifacts -Verbose` to generate the sample federation inventory.
5. [ ] Run `scripts\Export-Evidence.ps1 -ConfigurationTier <tier> -OutputPath .\artifacts -Verbose` to generate the evidence package.

## Post-Deployment Validation

- [ ] Deployment manifest is present in `artifacts/` and reflects the selected tier.
- [ ] Monitoring output includes sample records for federation inventory, MCP connection review, and Entra Agent ID governance review.
- [ ] Evidence export completes without script errors.
- [ ] Each JSON evidence file has a matching `.sha256` companion file.
- [ ] Control status entries are populated for 2.17, 2.16, 1.10, 2.13, 2.14, and 4.13.

## Evidence Review

- [ ] `agent-federation-inventory` is present and includes agent name, source tenant, channel, authentication type, sharing scope, and approved audience information.
- [ ] `cross-tenant-trust-assessment` is present and includes trust direction, allowed audiences, and review status.
- [ ] `mcp-trust-relationship-log` is present and includes MCP server URL, Streamable transport type, authentication type, approval requirements, allowed tools/scopes, and connection review status.
- [ ] `agent-id-attestation-evidence` is present and includes Agent ID identity, blueprint, owner/sponsor, assigned permissions, Conditional Access posture, audit-log references, and review status.
- [ ] Evidence package overall status is reviewed as `partial` while live integrations remain pending.

## Customer Handover

- [ ] README reviewed with the customer security, identity, and third-party risk stakeholders.
- [ ] Escalation path for cross-tenant agent invocation anomalies is documented.
- [ ] Evidence retention and storage responsibilities are confirmed.

## Sign-Off

- [ ] Delivery engineer sign-off completed.
- [ ] Customer technical owner sign-off completed.
- [ ] Customer compliance owner sign-off completed.
- [ ] Production handover date recorded.
