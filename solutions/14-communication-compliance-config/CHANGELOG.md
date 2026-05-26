# Changelog

## [Unreleased]

### Validation sweep — 2026-05-25

- Verified Communication Compliance role groups (`Communication Compliance Admins`, `Analysts`, `Investigators`, `Viewers`) are current per Microsoft Learn.
- Verified licensing terminology: Microsoft Purview Suite (formerly Microsoft 365 E5 Compliance) and Office 365 E3 with Advanced Compliance add-on are current.
- Verified Purview Insider Risk Management risky AI usage policy template capabilities are current.
- Verified Teams Intelligent Recap and Audio Recap compliance descriptions are current.
- Verified regulatory citations (FINRA 2210, FINRA 3110, SEC Reg BI, FCA SYSC 10, GLBA 501(b), SOX 302/404) are correct.
- Verified cross-solution reference to 04-finra-supervision-workflow is valid.
- Verified script parameter names and shared module imports match implementation.
- No corrections required; all content verified accurate as of 2026-05-25.

## v0.2.2 — 2026-05-23 — Council review remediation

### VERIFIED-BUG
- Added Pester coverage for deployment, monitoring, evidence output schemas, and tier progression invariants.
- Documented lexicon evidence fields as `wordAdded` and `wordRemoved` string arrays to match script output.
- Tightened credential-supplied detection for empty SecureString inputs in monitoring output.
- Corrected the evidence export operational note grammar.

### VERIFIED-DEAD-CONFIG
- Wired queue health thresholds into monitoring output and threshold evaluation.
- Surfaced regulated all-Copilot-content monitoring metadata in deployment manifest and output.

## v0.2.1 - 2026-05-04

- Corrected Communication Compliance licensing and role-group terminology to align with current Microsoft Learn guidance.
- Reframed Teams recap references around Intelligent recap and audio recap instead of non-current video-highlight terminology.
- Narrowed risky AI usage and retention statements to documented Microsoft Purview and Teams capabilities.

## v0.2.0

- Added insider risk management integration for risky AI usage detection: IRM prompt/response monitoring, Adaptive Protection correlation, and control 2.10 coverage.
- Added Teams Intelligent recap and audio recap compliance artifact documentation: governance patterns for FINRA 3110 supervision and SEC 17a-4 retention of AI-generated meeting notes, tasks, chapters, and audio summaries.
- Updated scope boundaries to clarify IRM and Teams recap governance posture.
- Updated architecture and evidence export documentation with new compliance artifact categories.

## v0.1.0 - 2025-01-15

### Added
- Initial solution scaffold for Microsoft Purview Communication Compliance Configurator
- Microsoft Purview Communication Compliance policy template library for Copilot-assisted content:
  - AI-generated financial advice detection pattern
  - FINRA 2210 promotional material detection
  - SEC Reg BI best-interest disclosure monitoring
  - Insider risk keyword lexicon (financial services specific)
- Reviewer workflow configuration: assignment rules, escalation timers, disposition tracking
- Queue metrics export: pending review count, avg review age, disposition distribution
- Lexicon update log: keyword additions, removals, policy publish history
- Deploy-Solution.ps1 with tier-aware Purview policy configuration
- Monitor-Compliance.ps1 with reviewer queue health checks
- Export-Evidence.ps1 with policy-template-export, reviewer-queue-metrics, lexicon-update-log
- Tiered configuration: baseline, recommended, regulated
- Pester tests covering configuration and script validation
