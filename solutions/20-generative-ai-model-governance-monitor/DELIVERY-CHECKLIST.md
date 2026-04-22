# Delivery Checklist

## Delivery Summary

| Item | Value |
|------|-------|
| Solution | Generative AI Model Governance Monitor |
| Solution Code | GMG |
| Version | v0.1.0 |
| Track | D |
| Priority | P1 |
| Phase | 4 |
| Primary Controls | 3.8a, 3.8 |
| Supporting Controls | 3.1, 3.11, 3.12 |
| Regulations | SR 26-2 / OCC Bulletin 2026-13, SR 11-7 / OCC Bulletin 2011-12 (interim genAI principles), NIST AI RMF 1.0, ISO/IEC 42001 |
| Evidence Outputs | copilot-model-inventory, validation-summary, ongoing-monitoring-log, third-party-due-diligence |

## Documentation

- [x] README.md present with status banner and doc-first warning
- [x] CHANGELOG.md present with v0.1.0 entry
- [x] docs/architecture.md
- [x] docs/deployment-guide.md
- [x] docs/evidence-export.md
- [x] docs/prerequisites.md
- [x] docs/troubleshooting.md

## Configuration

- [x] config/default-config.json
- [x] config/baseline.json
- [x] config/recommended.json
- [x] config/regulated.json
- [x] Each tier defines model_inventory_review_cadence_days, monitoring_log_retention_days, validation_assessment_required, third_party_review_cadence_days

## Scripts

- [x] scripts/Deploy-Solution.ps1
- [x] scripts/Monitor-Compliance.ps1
- [x] scripts/Export-Evidence.ps1
- [x] scripts/GmgConfig.psm1
- [x] All scripts include comment-based help noting documentation-first scope and use of representative sample data
- [ ] Live Microsoft Graph or Purview integration (deferred — not in v0.1.0 scope)

## Tests

- [x] tests/20-generative-ai-model-governance-monitor.Tests.ps1 with file presence, config validation, and parse checks
- [ ] End-to-end live tests (deferred — requires tenant integration outside v0.1.0)

## Evidence Format

- [x] Four evidence artifacts emitted as JSON
- [x] Each JSON artifact paired with a `.sha256` sidecar file
- [x] Artifacts include solution, tier, generatedAt, runtimeMode, warning, and records fields
- [ ] Shared evidence package contract integration (deferred — stub uses local sidecar pattern)

## Regulatory Mapping

- [x] README.md Regulatory Alignment section cites SR 26-2 / OCC Bulletin 2026-13 and notes the generative AI exclusion
- [x] Federal Reserve SR 11-7 / OCC Bulletin 2011-12 interim generative AI applicability documented
- [x] NIST AI RMF 1.0 and ISO/IEC 42001 references included
- [x] framework_ids align with the catalog: sr-26-2, occ-2026-13, sr-11-7, occ-2011-12, nist-ai-rmf, iso-iec-42001

## Customer Handover

- [ ] README reviewed with customer model risk officer and compliance stakeholders
- [ ] Tier selection confirmed (baseline, recommended, or regulated)
- [ ] Evidence storage path and retention requirements confirmed
- [ ] Customer acknowledges documentation-first scope of v0.1.0
