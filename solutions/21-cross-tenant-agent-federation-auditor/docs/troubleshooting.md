# Troubleshooting

## Configuration not found

**Symptom:** `Configuration file not found: ...\config\<tier>.json`.

**Resolution:** Verify that `config/baseline.json`, `config/recommended.json`, and `config/regulated.json` exist alongside `config/default-config.json`. Pass `-ConfigurationTier` with one of `baseline`, `recommended`, or `regulated`.

## Missing required field

**Symptom:** `CTAF configuration is missing required fields: ...`.

**Resolution:** Compare your tier file against the shipped template. Required fields include `tier`, `primaryControls`, `federationReviewCadenceDays`, `mcpTrustAttestationRequired`, `agentIdSigningRequired`, `crossTenantAuditLogRetentionDays`, `evidenceRetentionDays`, `notificationMode`, `copilotStudioPublishing`, and `mcpAttestation`.

## SHA-256 companion file missing

**Symptom:** Evidence JSON file is present but `.sha256` is missing.

**Resolution:** Re-run `scripts\Export-Evidence.ps1`. Confirm that the user account has write permission to the output path. The script writes a sidecar with the same base name and `.sha256` extension after each artifact.

## Pester tests fail to discover scripts

**Symptom:** Tests report missing files in `scripts/` or `docs/`.

**Resolution:** Confirm you are running Pester from the solution directory (`solutions/21-cross-tenant-agent-federation-auditor`) and that the working directory has not been redirected.

## Sample data appears in evidence

**Expected behavior:** v0.1.1 is documentation-first. All evidence records are representative sample data, clearly labeled with `runtimeMode = "sample"` in the JSON output. This is not a defect; live integration is roadmapped for later versions.
