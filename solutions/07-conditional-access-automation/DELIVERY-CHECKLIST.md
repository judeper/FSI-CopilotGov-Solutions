# Delivery Checklist

Use this checklist before promoting the solution into an operational tenant.

## Dependency and readiness

- [ ] `05-dlp-policy-governance` is complete and validated for the target tenant.
- [ ] Microsoft Entra ID P1 or P2 licensing is confirmed for all scoped Copilot users.
- [ ] Required administrator roles are assigned and time-bounded.
- [ ] Copilot app IDs are verified for Microsoft 365 Copilot and Copilot Studio.

## Policy deployment

- [ ] Conditional Access policies are created for the selected governance tier.
- [ ] MFA requirements align with the selected baseline, recommended, or regulated tier.
- [ ] Compliant-device requirements are configured where the tier requires them.
- [ ] Named-location restrictions are configured for the required risk tiers.
- [ ] Break-glass and emergency access exclusions are reviewed and approved.

## Monitoring and exception handling

- [ ] Baseline snapshot is taken and stored in the approved repository or artifact path.
- [ ] Drift monitor is scheduled using the required cadence for the selected tier.
- [ ] Exception register is initialized and protected against unauthorized edits.
- [ ] Power Automate or ticket-based approval workflow is mapped to exception handling.

## Validation and evidence

- [ ] `scripts\Monitor-Compliance.ps1` completes without unresolved high-severity findings.
- [ ] `scripts\Export-Evidence.ps1` exports `ca-policy-state.json`, `drift-alert-summary.json`, and `access-exception-register.json`.
- [ ] Evidence files include SHA-256 companions and align to `data\evidence-schema.json`.
- [ ] Regulatory notes and control mappings are reviewed for OCC 2011-12, FINRA 3110, and DORA.

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Solution Owner | | | |
| Security Lead | | | |
| Compliance Lead | | | |
| Customer Understanding | ☐ Customer confirms they understand this solution uses representative sample data and requires tenant binding for production use. | | |
