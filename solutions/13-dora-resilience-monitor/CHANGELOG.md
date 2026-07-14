# Changelog

## [Unreleased]

### Microsoft currency review (2026-07-14)

- Verified Microsoft Graph `serviceAnnouncement` `healthOverviews` (v1.0) and `ServiceHealth.Read.All` (delegated work/school and application) remain current on Microsoft Learn.
- Clarified that this solution monitors **Microsoft 365 Service Health** (Microsoft 365 admin center Service health page and Graph service communications), distinct from **Azure Service Health**, in the README and architecture docs.
- Corrected the control 4.11 Sentinel claim: removed the unsupported "data connector (currently preview)" wording. Microsoft publishes no native Sentinel data connector for Microsoft 365 service health or Copilot interaction events; documented the Microsoft 365 (Office 365) connector scope and the Office 365 Management API custom-ingestion path.
- Noted the Microsoft Sentinel transition to the Microsoft Defender portal and the 31 March 2027 retirement of the standalone Azure portal experience.
- Added the 31 August 2026 retirement note for the legacy Microsoft Graph `/security/alerts` API in prerequisites.

### DORA reporting-timeline accuracy

- Documented the DORA application date (17 January 2025) and the major-incident reporting time limits per Commission Delegated Regulation (EU) 2025/301 Art. 5 (initial ≤4h from classification / ≤24h from awareness; intermediate ≤72h from the initial notification; final ≤1 month from the intermediate report), with templates in Implementing Regulation (EU) 2025/302 and thresholds in Delegated Regulation (EU) 2024/1772.
- Corrected `Export-Evidence.ps1` due-date anchoring so the intermediate report chains from the initial notification and the final report chains from the intermediate report, instead of anchoring every stage to detection. Added the 24-hour-from-awareness bound (`initialNotificationLatestFromAwarenessHours`) to the regulated tier and recorded regulatory source, anchor semantics, and a not-legal-advice disclaimer in the incident register.

### Evidence freshness

- Added first-class freshness evaluation to `Monitor-Compliance.ps1` and `Export-Evidence.ps1`: records now distinguish collection time from source last-modified time, evaluate age/staleness against a threshold (default three polling cycles, minimum 60 minutes; override with `DRM_FRESHNESS_THRESHOLD_MINUTES`), and expose runtime mode and reporting period. All freshness timestamps use UTC ISO 8601.
- Missing or invalid source timestamps now surface an explicit gap (`status = unknown`, `hasTimestampGap = true`) and roll up to an overall `gap` status with a warning, instead of silently defaulting to the collection time. Synthetic local-stub records report `not-applicable` rather than appearing current.

### Lab validation

- Added `lab/13-dora-resilience-monitor.lab.json` — a read-only, detect-only first cycle (`mutations: []`) covering tenant-identity proof without raw-ID retention, Microsoft 365 admin center service-health inspection, optional least-privilege Graph read, read-only Sentinel/Defender portal inspection, sample-script execution, and freshness/evidence-hash verification, with evidence-backed `BLOCKED`/`NOT-APPLICABLE` paths.
- Registered the contract in `scripts/test_lab_validation_contracts.py` and added lab handoff notes to the deployment guide and delivery checklist.

### Tests

- Added regression tests for freshness (stale, gap, synthetic-stub, and UTC timestamp handling) and DORA reporting-timeline anchoring and citations.

## v0.1.3 — 2026-06-05 — Microsoft Learn accuracy fixes

### Fixed

- Corrected Entra role name "Service Support Admin" → "Service Support Administrator" (canonical display name per Microsoft Learn).
- Corrected monitored workload label "Microsoft Copilot" → "Microsoft 365 Copilot" (enterprise brand per Microsoft Learn).

### Validation sweep — 2026-05-25

- Verified Microsoft Graph `/admin/serviceAnnouncement/healthOverviews` v1.0 endpoint and `ServiceHealth.Read.All` permission are current.
- Verified optional security API permissions (`SecurityAlert.Read.All`, `SecurityIncident.Read.All`) remain current for their respective endpoints.
- Verified PowerShell module references (`Microsoft.Graph.Authentication`, `ExchangeOnlineManagement`) are current and not deprecated.
- Verified Entra ID role names (Global Reader, Service Support Admin, Compliance Admin) are current.
- Verified DORA regulation citation (Regulation (EU) 2022/2554) and article references (Art. 17, 18, 19, 24-26) are correct.
- Verified cross-solution reference to 12-regulatory-compliance-dashboard is valid.
- Verified script parameter names and shared module imports match implementation.
- No corrections required; all content verified accurate as of 2026-05-25.

## v0.1.2 — 2026-05-23 — Council review remediation

### Fixed

- F-07: Corrected regulatory notification threshold logic to use severity-rank comparison so major incidents are flagged when the configured threshold is significant.

### Documentation tightened

- F-01: Separated DORA Art. 17 incident-management alignment from Art. 24-26 resilience-testing readiness in the architecture notes.
- F-02: Updated README regulatory alignment to distinguish Art. 17 incident management, Art. 18 classification, and Art. 19 reporting-package preparation.
- F-03: Aligned evidence-export wording with the Art. 17, Art. 18, and Art. 19 mapping used across the README and architecture guidance.
- F-11: Added an Art. 18 severity-classification coverage note that identifies modeled criteria and manual assessment gaps.
- F-12: Clarified regulated-tier reporting scope by adding intermediate and final report timeline fields while preserving documentation-first, non-submission behavior.

### Dead config

- F-08: Wired regulated notification-window and RCA-window settings into incident-register evidence metadata and due-date fields.
- F-09: Aligned the default polling interval key with the tier configuration key and added default fallback handling.

### Version drift

- None in the verified brief; aligned remediation release version strings to v0.1.2.

## [v0.1.1] - 2026-05-04

- Corrected roadmap awareness wording to match Microsoft Learn release-plan terminology for 2026 Release Wave 1 governance capabilities.
- Added Sentinel preview, customer-defined ingestion, and Microsoft Graph permission caveats for operational-resilience enrichment.
- Normalized Microsoft Graph service-health status values before incident classification.

## v0.1.0 - 2025-01-15

### Added
- Initial solution scaffold with DORA-aligned incident classification schema
- Service health monitoring for Copilot-dependent M365 services (Exchange Online, SharePoint Online, Teams, Microsoft Graph)
- Incident register structure aligned to DORA Art. 17 ICT incident taxonomy (significant/major/minor)
- Resilience test evidence collection template (annual DORA ICT resilience testing framework)
- Deploy-Solution.ps1 with tier-aware configuration deployment
- Monitor-Compliance.ps1 with health-status polling and incident severity scoring
- Export-Evidence.ps1 with service-health-log, incident-register, and resilience-test-results artifacts
- Tiered configuration: baseline (monitoring + alerting), recommended (+ incident register), regulated (+ full DORA reporting)
- Pester tests covering config presence, required fields, and script parameter validation