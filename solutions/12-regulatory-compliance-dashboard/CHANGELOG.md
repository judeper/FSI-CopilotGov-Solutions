# Changelog

## Validation Sweep — 2026-05-25

### Verified

- All PowerShell scripts pass syntax validation.
- Power BI Pro/Premium Per User licensing requirements confirmed current.
- Dataverse capacity and table naming conventions confirmed accurate.
- Purview licensing requirements (Microsoft 365 E5/A5/G5 or Purview add-on) confirmed current.
- Regulatory citations (FINRA 4511, FINRA 3110, SEC 17a-4, OCC 2011-12, DORA, GLBA 501(b)) are accurate.
- DAX measure patterns and Power BI semantic model design confirmed accurate.
- Added `last_verified` to `config/default-config.json`.

## v0.1.2 — 2026-05-23 — Council review remediation

### Dead config

- Finding 2: Documented `freshnessCheckCadence` as illustrative cadence metadata for customer-implemented freshness monitoring flows.
- Finding 3: Documented `framework_ids` as the reference framework catalog while `regulatoryFrameworks` remains the current dashboard view list.

## [v0.1.1] - 2026-05-04

- Updated Power BI documentation terminology from dataset to semantic model across dashboard guidance.
- Refreshed administrator and Microsoft Purview licensing prerequisites to align with current Microsoft Learn guidance.

## v0.1.0

- Replaced scaffold content with solution-specific documentation for Dataverse, Power Automate, Power BI, evidence exports, deployment, prerequisites, and troubleshooting.
- Added structured deployment, monitoring, and evidence-export PowerShell scripts with dependency validation, Dataverse table contracts, maturity scoring, and freshness checks.
- Expanded configuration tiers and Pester coverage for baseline, recommended, and regulated operating models.
