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

## Live Integration (Future)

Live tenant integration is intentionally out of scope for v0.1.1. Future versions will add:

- Microsoft Graph v1.0 integration for cross-tenant access policy partner enumeration.
- Copilot Studio channel, authentication, and organization sharing telemetry hooks.
- MCP connection/authentication review patterns using approved server URLs and tool approvals.
