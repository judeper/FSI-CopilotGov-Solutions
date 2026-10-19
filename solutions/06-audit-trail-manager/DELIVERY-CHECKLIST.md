# Delivery Checklist

Use this checklist before handing the Copilot Interaction Audit Trail Manager solution to deployment or examination support teams.

## Audit readiness

- [ ] Unified Audit Log is enabled in the Microsoft 365 tenant.
- [ ] `CopilotInteraction` events are confirmed in the validation window; `ConnectedAIAppInteraction` or `AIAppInteraction` are included only when custom or third-party AI apps are in scope.
- [ ] Required supporting events such as `FileAccessed` are included in the monitoring scope.
- [ ] Audit tier for the selected tier is documented as Audit (Standard) or Audit (Premium) as required.
- [ ] Copilot audit capture is distinguished from Premium-only capabilities, and effective audit log retention is verified independently from content retention.
- [ ] Manual audit validation uses Purview Audit or Exchange Online PowerShell, not the unimplemented `Check-AuditLogCompleteness` placeholder.

## Retention readiness

- [ ] Purview retention policies are applied for Copilot interaction artifacts.
- [ ] New prompt/response policies use **Microsoft Copilot experiences** and the `AppRetentionCompliance*` cmdlet family when using PowerShell; existing combined-location policies are identified separately.
- [ ] Retention labels target supported files/exported records, not prompt/response messages; cloud-attachment coverage is verified separately where used.
- [ ] Retention schedule is documented for SEC 17a-4, FINRA 4511, CFTC 1.31, and SOX 404.
- [ ] WORM or immutable storage documentation is attached for regulated deployments.

## Microsoft Purview eDiscovery readiness

- [ ] Microsoft Purview eDiscovery cases are created or referenced for the selected tier.
- [ ] Holds are configured for required custodians or record locations.
- [ ] Preservation status, hold counts, and custodian counts are documented.
- [ ] Legal hold owners and examination response contacts are recorded.
- [ ] Tier case templates/modes and sample counts are not mistaken for native product features or tenant observations; actual case access and mailbox/site coverage are verified.

## Reporting and alerting readiness

- [ ] Power BI dashboard is operational and refresh ownership is assigned.
- [ ] Power Automate retention exception alerts are configured and tested.
- [ ] Compliance findings are reviewed and open exceptions are documented.

## Evidence readiness

- [ ] `audit-log-completeness.json` is generated and reviewed.
- [ ] `retention-policy-state.json` is generated and reviewed.
- [ ] `ediscovery-readiness-package.json` is generated and reviewed.
- [ ] SHA-256 companion files validate successfully.
- [ ] The full evidence package is archived with the deployment record.
- [ ] Sample JSON and zero/pending audit counts are kept distinct from sanitized tenant observations; hashes are not treated as proof of control operation.
- [ ] Generated guidance is reviewed as illustrative content-location instructions; placeholders are not treated as executable commands and local samples are not accepted as tenant evidence.

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Solution Owner | | | |
| Security Lead | | | |
| Compliance Lead | | | |
| Customer Understanding | ☐ Customer confirms they understand this solution uses representative sample data and requires tenant binding for production use. | | |
