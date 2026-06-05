# Pearlman — History

## Seed (2026-06-05)
- **Project:** FSI-CopilotGov-Solutions — 23 documentation-first governance solutions.
- **User:** Jude. Priority: **accuracy over cost**.
- **My job:** Apply Freamon's verified fixes under strict FSI language rules; keep README ↔ `data/` ↔ `docs/` in sync; bump version + CHANGELOG.
- **Hard rules:** no "ensures compliance/guarantees/eliminates risk"; no overstated live-API claims (scripts use sample data); status stays "Documentation-first scaffold"; Dataverse logical names lowercase no inserted underscores; reuse `scripts/common/`.

## Learnings

## 2026-06-05 — Solution 08 Accuracy Fixes (squad/accuracy-08)

- Applied 1 major + 5 minor findings from Freamon's MS Learn verification.
- Major: "message packs" / "25,000-message packs" → "Copilot Studio capacity packs" / "25,000 Copilot Credits/month/pack". .01 figure attributed specifically to Copilot Studio message meter.
- Minor: billing policy scope broadened (security groups → security groups, distribution groups, or tenant). Config keys renamed (no script/test references existed, safe rename). Internal README inconsistency resolved.
- Config keys renamed: messagePacksEnabled → capacityPacksEnabled, highUsageThresholdMessagesPerDay → highUsageThresholdCreditsPerDay, billingPolicyScopeType value broadened.
- Lesson: grep ALL solution files for config keys before renaming — this time zero refs in scripts/tests made it safe.
- Version: v0.1.1 → v0.1.2. Pester 8/8 pass. Commit ecf48cf.
