# Deployment Guide

## 1. Review prerequisites

Confirm licensing, roles, PowerShell modules, and Graph permissions described in [prerequisites.md](./prerequisites.md).

The script examples below write local sample artifacts only. They neither collect tenant evidence nor apply policies. Perform tenant checks separately under the customer's authorization; this source review did not execute them.

## 2. Verify Unified Audit Log and Copilot event capture

- Confirm ingestion using `Get-AdminAuditLogConfig` and its `UnifiedAuditLogIngestionEnabled` property in **Exchange Online PowerShell**, not Security & Compliance PowerShell, where that property reports false. See [audit search prerequisites](https://learn.microsoft.com/purview/audit-search).
- `Check-AuditLogCompleteness` in generated metadata is a workflow placeholder, not an implemented command. Use Microsoft Purview **Audit > Search** with the operation name filter, or Exchange Online PowerShell `Search-UnifiedAuditLog`, for separately authorized validation.
- Confirm that `CopilotInteraction` (interactions with a Microsoft-developed Copilot application) and supporting workload events such as `FileAccessed` appear in scope; include `ConnectedAIAppInteraction` (a custom-built Copilot or third-party AI application deployed and registered within your organization) or `AIAppInteraction` (a third-party AI application that isn't deployed within your organization) only when those AI applications are in scope.
- Allow for audit record availability to vary; Microsoft doesn't guarantee a specific return time, core services typically appear within 60-90 minutes, and other services can take longer.
- Record the audit tier and effective audit log retention policy separately from content retention. Audit (Standard) includes Microsoft-developed Copilot interactions and 180-day log retention. Premium's one-year default is workload-specific, not automatic one-year Copilot retention; longer retention needs the appropriate policy and licensing. See [audit capabilities](https://learn.microsoft.com/purview/audit-solutions-overview) and [AI app scope/billing](https://learn.microsoft.com/purview/audit-copilot).

## 3. Generate solution manifests

```powershell
.\scripts\Deploy-Solution.ps1 -ConfigurationTier baseline -OutputPath .\artifacts\deployment -TenantId <tenant-id>
```

The deployment script creates the following files:

- `retention-policy-manifest.json`
- `audit-requirements.json`
- `deployment-manifest.json`

## 4. Apply retention policies

- Treat `retention-policy-manifest.json` as retention intent, not an importable policy or an executable command plan. Its `targetArtifacts` are audit event names, not content-retention locations.
- In the Microsoft Purview portal, new prompt/response policies use **Microsoft Copilot experiences**, separate from **Teams chats**. Use Security & Compliance PowerShell `New-AppRetentionCompliancePolicy`/`Set-AppRetentionCompliancePolicy` with `New-AppRetentionComplianceRule`/`Set-AppRetentionComplianceRule` for this location. Older `RetentionCompliance*` cmdlets still apply to existing **Teams chats and Copilot interactions** and other supported older locations. See [retention cmdlets](https://learn.microsoft.com/purview/retention-cmdlets).
- Validate that the selected tier aligns to the target preservation objective:
  - baseline: 1095 days
  - recommended: 1825 days
  - regulated: 2555 days
- Retain prompt/response messages with retention policies; these messages are stored in hidden user-mailbox folders. Retention labels apply separately to supported files and exported records, not directly to interaction messages. Auto-apply cloud-attachment labels can preserve supported file versions referenced in Copilot. See [Copilot retention](https://learn.microsoft.com/purview/retention-policies-copilot) and [supported capabilities](https://learn.microsoft.com/purview/ai-m365-copilot).
- Verify retention through eDiscovery, not chat visibility alone; retention processing typically runs over 1-7 days and holds can suspend permanent deletion. Do not remove holds or purge content as a verification test.

> **Pending code-owner correction:** Generated `policyApplication`, label-scope notes, and workflow-placeholder strings have not yet been corrected in the scripts. Do not follow their older cmdlet examples for new Copilot locations. See the [re-verification handoff](https://github.com/judeper/FSI-CopilotGov-Solutions/blob/main/artifacts-review/06-audit-trail-manager/reverification-2026-10-18.md) for exact paths and reproduction.

## 5. Configure Microsoft Purview eDiscovery holds

- Create or update Microsoft Purview eDiscovery cases for the selected tier.
- Confirm actual hold status, people/groups, mailbox/site data sources, and legal hold ownership in the [current eDiscovery experience](https://learn.microsoft.com/purview/edisc). Use mailbox data sources to search stored prompts/responses; audit metadata alone is not their content.
- Document export permissions and examination response contacts.
- Treat tier `caseTemplate` names and `basic`/`enhanced`/`full` modes as local readiness conventions, not native Microsoft case templates or editions. Sample counts from the export script do not demonstrate preservation.

## 6. Deploy the Power BI monitoring dashboard

- Build the dashboard from the documented JSON outputs and metrics described in the README and [evidence-export.md](./evidence-export.md).
- Include pages for audit completeness, retention coverage, and Microsoft Purview eDiscovery readiness.
- Configure scheduled refresh using credentials for the implemented data source and a gateway only where that source requires one; the scaffold does not provide a live Graph binding.
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

Review the generated SHA-256 companions and archive the evidence package with the deployment record. Keep separately sourced, sanitized tenant observations distinct from these samples; do not relabel zero/pending event counts or tier-derived case/hold counts as observed values.

## 9. Validate ongoing posture

```powershell
.\scripts\Monitor-Compliance.ps1 -ConfigurationTier baseline -OutputPath .\artifacts\monitor -TenantId <tenant-id> -CheckRetention $true -CheckAuditLevel $true
```

Address any retention gaps, missing event types, or Microsoft Purview eDiscovery readiness findings before regulatory review.
