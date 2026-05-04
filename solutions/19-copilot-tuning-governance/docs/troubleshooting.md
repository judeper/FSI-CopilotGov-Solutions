# Troubleshooting

## Error: Copilot Tuning not available in tenant

**Symptoms**

- Copilot Tuning settings do not appear in the Microsoft 365 admin center Copilot control system
- Eligible users cannot see tuning options in Agent Builder after creating an agent from a tunable template
- Users cannot submit tuning access requests for admin review

**Actions**

- Confirm the tenant is included in an eligible early access, Frontier, or public preview rollout
- Confirm the organization has at least 5,000 Microsoft 365 Copilot licenses during public preview
- Verify Copilot Tuning availability settings in the Microsoft 365 admin center: enabled for all users, enabled for specific users or groups, or disabled
- If the tenant is using a limited rollout, confirm the user or Microsoft Entra security group is included in the allowed tuning audience
- Contact Microsoft support or the Microsoft account team if the license threshold and preview enrollment are met but Copilot Tuning settings are unavailable

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

Run the initial deployment with the baseline tier to validate governance controls, evidence export, and monitoring scripts before expanding tuning availability. In eligible preview tenants, use the Microsoft 365 admin center to disable tuning or limit it to approved pilot users or groups because the repository configuration does not change tenant availability settings.

## Tip: Validate approval workflow before expanding tuning access

Confirm that model risk management stakeholders have reviewed and approved the tuning approval workflow documented in [architecture.md](architecture.md) before switching from baseline to recommended or regulated tiers. The approval chain should be tested with a sample tuning request before approved preview users receive broader tuning access.

## Tip: Monitor risk reassessment cadence

Use `Monitor-Compliance.ps1` regularly to identify tuned models approaching their risk reassessment deadline. The default reassessment cadence is 90 days for the recommended tier and 30 days for the regulated tier.
