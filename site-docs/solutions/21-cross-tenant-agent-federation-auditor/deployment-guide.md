# Deployment Guide

> ⚠️ **Documentation-first.** All scripts use representative sample data. No live tenant calls are made.

## Prerequisites

Confirm the items in [prerequisites.md](prerequisites.md) before deploying.

## Steps

1. Open PowerShell 7.2 or later in `solutions/21-cross-tenant-agent-federation-auditor`.
2. Choose a governance tier:
   - `baseline` — 90-day federation review cadence, optional MCP connection/authentication review.
   - `recommended` — 30-day cadence, required MCP connection/authentication review and Agent ID identity-governance review.
   - `regulated` — 7-day cadence, MCP connection revalidation, customer-defined Agent ID credential review, 1825-day retention.
3. Run a deployment preview:

   ```powershell
   .\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended -WhatIf -Verbose
   ```

4. Generate the deployment manifest:

   ```powershell
   .\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended -OutputPath .\artifacts -Verbose
   ```

5. Capture a sample monitoring snapshot:

   ```powershell
   .\scripts\Monitor-Compliance.ps1 -ConfigurationTier recommended -OutputPath .\artifacts -Verbose
   ```

6. Generate the evidence package:

   ```powershell
   .\scripts\Export-Evidence.ps1 -ConfigurationTier recommended -OutputPath .\artifacts -Verbose
   ```

## Validation

- The `artifacts/` directory contains a deployment manifest, monitoring snapshot, and four evidence JSON files plus matching `.sha256` companions.
- The Pester smoke tests in `tests/` pass.

## Lab Validation Handoff

A read-only lab validation contract is provided at `lab/21-cross-tenant-agent-federation-auditor.lab.json` for tenant-bound verification against current Microsoft guidance. It is a template-binding, read-only contract (`mutations: []`) that:

1. Runs `Deploy-Solution.ps1`, `Monitor-Compliance.ps1`, and `Export-Evidence.ps1` in `-WhatIf` mode so no tenant state and no local artifacts are written.
2. Requires two sanctioned disposable tenants with independent identity proof before any cross-tenant check. Runtime `CTAF_PARTNER_TENANT_ID` scopes the read to one partner (`GET /policies/crossTenantAccessPolicy/partners/{tenantId}`), and retained evidence omits tenant/object target identifiers.
3. Reads aggregate Agent 365 registry inventory through the Package Management API, which Microsoft currently describes as preview (`GET /v1.0/copilot/admin/catalog/packages`, `CopilotPackages.Read.All`, Agent 365 license), without retaining package IDs, names, app IDs, owners, or assignments.
4. Confirms the cited Microsoft Learn and Microsoft Graph sources remain aligned with the documented cross-tenant access, Microsoft Entra Agent ID (preview), Agent 365 registry/API, Copilot Studio multitenant mode (preview), and MCP transport behavior.
5. Writes sanitized summaries only to ignored `lab-evidence/21-cross-tenant-agent-federation-auditor` staging and removes it fail-closed after result packaging.

Validate the contract locally with:

```powershell
python scripts/validate-lab-contracts.py solutions/21-cross-tenant-agent-federation-auditor/lab/21-cross-tenant-agent-federation-auditor.lab.json
```

Classify any capability that is unavailable, unlicensed, or still in preview in the validation tenants as `NOT-APPLICABLE` or `BLOCKED` with source evidence — never `PASS`. Primary control 2.17 (Microsoft Entra Agent ID Lifecycle Governance) is not yet represented in `data/controls-master.json`, so it is tracked outside the contract's machine-checked controls until the canonical metadata includes it; the same read-only evidence still substantiates Entra Agent ID governance review.

## Live Integration (Future)

Live tenant integration is intentionally out of scope for v0.1.3. Future versions will add:

- Repository-script Microsoft Graph integration for cross-tenant access policy partner enumeration (the external lab contract already specifies a read-only runtime query).
- Copilot Studio channel, authentication, and organization sharing telemetry hooks.
- MCP connection/authentication review patterns using approved server URLs and tool approvals.
