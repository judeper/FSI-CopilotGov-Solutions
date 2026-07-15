# Changelog

## Unreleased — Microsoft currency review (Solution 12)

### Fixed

- `Export-Evidence.ps1` no longer derives evidence freshness from the configured `freshnessThresholdHours` constant. The framework coverage matrix and referenced evidence packages now report `evidenceFreshnessState`/`freshnessStatus` of `unknown` with an explicit timestamp gap instead of appearing `current` when no upstream source timestamp or hash is resolved.
- Seeded `control-status-snapshot` rows set `lastEvidenceDate` to `null`, record `collectedAt` for the seed generation time, and mark `timestampProvenance` as `synthetic-seed` with `freshnessState` of `not-applicable`, so synthetic seed data does not appear current.
- `Validate-LabEvidence.ps1` now enforces only canonical dashboard coverage states (`implemented`, `partial`, `monitor-only`, `playbook-only`, `not-applicable`) and rejects `not-implemented` plus disposition values such as `PASS`/`BLOCKED` in control snapshots.
- `templates/dashboard/control-feed-schema.json` now includes `not-applicable` in `allowedStatuses` to match the explicit dashboard status contract.

### Added

- Evidence provenance and freshness lineage across the scripts: `collectedAt`, `sourceLastModified`, `timestampProvenance`, `freshnessState`/`freshnessStatus`, `hashState`, and a `dataQuality` rollup (`overall = gap`) on `dashboard-export`.
- `Monitor-Compliance.ps1` returns `DataQualityGap` and `TimestampGapControlCount` and emits a warning when any control lacks a source evidence timestamp.
- `lab/12-regulatory-compliance-dashboard.lab.json` — a read-only, detect-only first cycle (`mutations: []`) covering tenant/workspace-identity proof without raw-ID retention, Viewer-only Power BI/Fabric workspace/report/semantic-model inspection, capacity/license/admin prerequisite checks, representative feed/evidence script execution, and schema/hash/lineage/freshness verification, with evidence-backed `BLOCKED`/`NOT-APPLICABLE` paths.
- Regression tests for the honest freshness/provenance behavior, canonical dashboard status enforcement, template status contract coverage, and a lab-contract validation test.

### Changed

- Clarified in the deployment guide and architecture doc that row-level security applies only to workspace **Viewer** consumers and does not restrict workspace Admin/Member/Contributor roles, per current Microsoft guidance.
- Documented freshness and provenance semantics and a data-quality-gap troubleshooting path in the evidence-export and troubleshooting docs.
- Updated the Solution 12 lab contract and deployment guidance to cite `Groups - Get Groups` (`GET /v1.0/myorg/groups`) directly, require preauthorized delegated `Workspace.Read.All` for the first cycle, prohibit `Workspace.ReadWrite.All`/consent changes, remove Fabric administrator as a first-cycle prerequisite, and constrain retained workspace evidence to aggregate counts plus boolean match only.

## v0.1.3 — 2026-06-05 — Accuracy fix (semantic model terminology)

### Changed

- Added clarifying comment in `Deploy-Solution.ps1` noting that the `powerBI.datasetTables` config key retains legacy naming for backward compatibility; Power BI renamed "datasets" to "semantic models" (Nov 2023). Key not renamed because script code depends on it.
- Renamed output property in deployment manifest from `datasetTables` to `semanticModelTables` (human-readable output only; config key unchanged).

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
