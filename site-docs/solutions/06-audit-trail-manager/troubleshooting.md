# Troubleshooting

| Issue | Likely cause | Remediation |
|-------|--------------|-------------|
| UAL is not capturing Copilot events | Audit is not enabled, the tenant does not have the required audit tier, or recent activity has not propagated yet | Confirm Unified Audit Log is enabled, verify the tenant has Audit (Standard) or Audit (Premium) coverage as required, allow for variable audit record availability because Microsoft doesn't guarantee a specific return time and core services typically appear within 60-90 minutes while other services can take longer, and re-run the audit completeness check |
| Retention policy is not applying | The retention label or policy scope does not include the target Copilot artifact locations | Review Purview policy scope, label publishing targets, workload inclusion, and any exclusions that remove Copilot-related content |
| Microsoft Purview eDiscovery case creation fails | The operator lacks the required permissions or the case role group is incomplete | Confirm eDiscovery Manager access, case permissions, and hold management roles before retrying |
| Evidence export hash mismatch | File encoding or post-export edits changed the JSON after the hash file was created | Re-run `Export-Evidence.ps1`, avoid manual edits after export, and ensure UTF-8 output is preserved |
| Power BI fails to refresh | Graph token expiry, expired gateway credentials, or missing workspace permissions | Re-authenticate the data source, refresh the connection reference, and confirm the dashboard owner still has workspace access |
