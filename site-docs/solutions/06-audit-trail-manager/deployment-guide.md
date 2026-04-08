# Deployment Guide

## 1. Review prerequisites

Confirm licensing, roles, PowerShell modules, and Graph permissions described in [prerequisites.md](./prerequisites.md).

## 2. Verify Unified Audit Log and Copilot event capture

- Confirm that Microsoft 365 Unified Audit Log is enabled in the tenant.
- Run the operational validation workflow aligned to `Check-AuditLogCompleteness`.
- Confirm that `CopilotInteraction`, `AIInteraction`, and supporting workload events such as `SharePointFileAccess` appear in scope.
- Allow up to 24 hours for newly enabled audit events to appear in UAL.

## 3. Generate solution manifests

```powershell
.\scripts\Deploy-Solution.ps1 -ConfigurationTier baseline -OutputPath .\artifacts\deployment -TenantId <tenant-id>
```

The deployment script creates the following files:

- `retention-policy-manifest.json`
- `audit-requirements.json`
- `deployment-manifest.json`

## 4. Apply retention policies

- Use `Set-RetentionPolicy` or the Microsoft Purview portal to create or update the retention policies defined in `retention-policy-manifest.json`.
- Validate that the selected tier aligns to the target preservation objective:
  - baseline: 1095 days
  - recommended: 1825 days
  - regulated: 2555 days
- Confirm that retention labels are scoped to Copilot interaction artifacts, related files, and exported evidence where firm policy requires coverage.

## 5. Configure Microsoft Purview eDiscovery holds

- Create or update Microsoft Purview eDiscovery cases for the selected tier.
- Confirm hold count, custodian list, preservation status, and legal hold ownership.
- Document export permissions and examination response contacts.
- Align case naming to the readiness templates in the tier configuration.

## 6. Deploy the Power BI monitoring dashboard

- Build the dashboard from the documented JSON outputs and metrics described in the README and [evidence-export.md](./evidence-export.md).
- Include pages for audit completeness, retention coverage, and Microsoft Purview eDiscovery readiness.
- Configure scheduled refresh using approved Graph or data gateway credentials.
- Record the dashboard owner, workspace name, and refresh schedule.

## 7. Configure Power Automate exception alerts

- Create a flow that monitors compliance findings or exported JSON changes.
- Send summary alerts for baseline, targeted alerts for recommended, and strict alerts for regulated.
- Record the flow owner, connection references, and escalation mailbox.
- Test alert delivery before promoting the solution to production use.

## 8. Run baseline evidence export

```powershell
.\scripts\Export-Evidence.ps1 -ConfigurationTier baseline -OutputPath .\artifacts\evidence -PeriodStart 2026-01-01 -PeriodEnd 2026-01-31 -TenantId <tenant-id>
```

Review the generated SHA-256 companions and archive the evidence package with the deployment record.

## 9. Validate ongoing posture

```powershell
.\scripts\Monitor-Compliance.ps1 -ConfigurationTier baseline -OutputPath .\artifacts\monitor -TenantId <tenant-id> -CheckRetention $true -CheckAuditLevel $true
```

Address any retention gaps, missing event types, or Microsoft Purview eDiscovery readiness findings before regulatory review.
