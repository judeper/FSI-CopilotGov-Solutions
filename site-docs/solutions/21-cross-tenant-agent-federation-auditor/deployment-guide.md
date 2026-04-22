# Deployment Guide

> ⚠️ **Documentation-first.** All scripts use representative sample data. No live tenant calls are made.

## Prerequisites

Confirm the items in [prerequisites.md](prerequisites.md) before deploying.

## Steps

1. Open PowerShell 7.2 or later in `solutions/21-cross-tenant-agent-federation-auditor`.
2. Choose a governance tier:
   - `baseline` — 90-day federation review cadence, optional MCP attestation.
   - `recommended` — 30-day cadence, required MCP attestation and Entra Agent ID signing.
   - `regulated` — 7-day cadence, MCP attestation revalidation, Agent ID key rotation tracking, 1825-day retention.
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

Live tenant integration is intentionally out of scope for v0.1.0. Future versions will add:

- Microsoft Graph integration for cross-tenant access policy enumeration.
- Copilot Studio publishing telemetry hooks.
- MCP signing-key verification.
