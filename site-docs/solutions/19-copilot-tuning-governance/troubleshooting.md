# Troubleshooting

## Error: Copilot Tuning not available in tenant

**Symptoms**

- Copilot Tuning options do not appear in M365 Admin Center
- Tuning API endpoints return 404 or feature-not-enabled errors

**Actions**

- Confirm the organization has 5,000 or more Microsoft 365 Copilot licenses
- Verify the Copilot Tuning feature has been enabled for the tenant by Microsoft
- Check Microsoft 365 Admin Center for feature availability announcements
- Contact Microsoft support if the license threshold is met but the feature is unavailable

## Error: Configuration file not found

**Symptoms**

- `Deploy-Solution.ps1` fails with file-not-found errors
- Config path references default-config.json or tier JSON that cannot be located

**Actions**

- Confirm you are running the script from the solution root or providing the correct relative path
- Verify all config files exist under `config\`: `default-config.json`, `baseline.json`, `recommended.json`, `regulated.json`
- Check for file permissions that may prevent reading config files

## Error: Evidence export validation failures

**Symptoms**

- `Export-Evidence.ps1` reports evidence validation errors
- Evidence package is missing expected artifact types

**Actions**

- Confirm the expected evidence outputs match the configuration: tuning-requests, model-inventory, risk-assessments
- Verify the output directory exists and is writable
- Check that the `EvidenceExport.psm1` module is available at the expected path
- Review the validation error details for specific missing or malformed artifacts

## Error: Deployment manifest write failure

**Symptoms**

- `Deploy-Solution.ps1` completes configuration loading but fails to write the manifest
- Output directory cannot be created

**Actions**

- Confirm the output path is valid and the operator has write permissions
- Verify disk space is available for manifest and evidence files
- Check that antivirus or endpoint protection is not blocking file creation

## Tip: Start with baseline tier

Run the initial deployment with the baseline tier (tuning disabled) to validate governance controls, evidence export, and monitoring scripts before enabling tuning in any capacity. This allows stakeholders to review the governance framework without introducing model risk.

## Tip: Validate approval workflow before enabling tuning

Confirm that model risk management stakeholders have reviewed and approved the tuning approval workflow documented in [architecture.md](architecture.md) before switching from baseline to recommended or regulated tiers. The approval chain should be tested with a sample tuning request before production use.

## Tip: Monitor risk reassessment cadence

Use `Monitor-Compliance.ps1` regularly to identify tuned models approaching their risk reassessment deadline. The default reassessment cadence is 90 days for the recommended tier and 30 days for the regulated tier.
