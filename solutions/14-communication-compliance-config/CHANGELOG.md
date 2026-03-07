# Changelog

## [Unreleased]

## v0.1.0 - 2025-01-15

### Added
- Initial solution scaffold for Communication Compliance Configurator
- Communication compliance policy template library for Copilot-assisted content:
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
