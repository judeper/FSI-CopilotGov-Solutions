# Delivery Checklist

## Delivery Summary

| Item | Value |
|------|-------|
| Solution | Pages and Notebooks Retention Tracker |
| Solution Code | PNRT |
| Version | v0.1.1 |
| Track | D |
| Priority | P1 |
| Primary Controls | 3.14, 3.2 |
| Supporting Controls | 3.3, 3.11, 2.11 |
| Regulations | SEC Rule 17a-4 (where applicable), FINRA Rule 4511(a), Sarbanes-Oxley §§302/404 (where applicable to ICFR) |
| Evidence Outputs | pages-retention-inventory, notebook-retention-log, loop-component-lineage, branching-event-log |
| Dependencies | None |

## Pre-Deployment

- [ ] Customer confirms which Copilot Pages, OneNote Notebooks, and Loop workspaces are in scope.
- [ ] Records-management team confirms retention period requirements for collaborative Copilot artifacts.
- [ ] Microsoft 365 and Purview prerequisites from `docs/prerequisites.md` are verified.
- [ ] Governance tier is selected: baseline, recommended, or regulated.
- [ ] Evidence output path and retention requirements are agreed with the customer records team.

## Configuration Review

- [ ] `config/default-config.json` reviewed for default evidence path, monitored container types, and Loop workspace seeds.
- [ ] `config/baseline.json` reviewed for Purview audit summary, internal sample lineage mode, and 365-day retention defaults.
- [ ] `config/recommended.json` reviewed for Purview audit/version-history evidence, internal sample lineage mode, and 7-year retention defaults.
- [ ] `config/regulated.json` reviewed for preservation-lock expectations and signed lineage settings for repository sample lineage.
- [ ] Required environment variables are documented for tenant ID, client ID, and any Purview workspace references.

## Deployment Steps

1. [ ] Open PowerShell 7.2 or later in `solutions/22-pages-notebooks-retention-tracker`.
2. [ ] Run `scripts\Deploy-Solution.ps1 -ConfigurationTier <tier> -WhatIf -Verbose` and review the planned manifest.
3. [ ] Run `scripts\Deploy-Solution.ps1 -ConfigurationTier <tier> -TenantId <tenant-guid> -OutputPath .\artifacts -Verbose`.
4. [ ] Run `scripts\Monitor-Compliance.ps1 -ConfigurationTier <tier> -OutputPath .\artifacts -Verbose` to capture the initial sample inventory.
5. [ ] Run `scripts\Export-Evidence.ps1 -ConfigurationTier <tier> -OutputPath .\artifacts -Verbose` to generate evidence artifacts.

## Post-Deployment Validation

- [ ] Deployment manifest is present in `artifacts/` and reflects the selected tier.
- [ ] Pages-retention-inventory artifact is present and lists representative Page records.
- [ ] Notebook-retention-log artifact is present and lists representative OneNote section/folder coverage grouped by Notebook metadata.
- [ ] Loop-component-lineage artifact is present and links each component to a parent container.
- [ ] Branching-event-log artifact is present, clearly labels repository-only internal sample lineage, and documents Purview audit/version-history context.
- [ ] Each JSON evidence file has a matching `.sha256` companion file.
- [ ] Control status entries are populated for 3.14, 3.2, 3.3, 3.11, and 2.11.

## Customer Handover

- [ ] README reviewed with the customer records-management, compliance, and supervision stakeholders.
- [ ] Documented SharePoint Embedded, Microsoft Graph DriveItem/export where supported, Purview audit/retention, and Cloud Policy/SharePoint admin insertion points are documented for future development.
- [ ] Evidence retention and storage responsibilities are confirmed.
- [ ] Customer acknowledges that PNRT does not on its own satisfy SEC Rule 17a-4 or FINRA Rule 4511(a).

## Sign-Off

- [ ] Delivery engineer sign-off completed.
- [ ] Customer technical owner sign-off completed.
- [ ] Customer compliance owner sign-off completed.
- [ ] Production handover date recorded.
