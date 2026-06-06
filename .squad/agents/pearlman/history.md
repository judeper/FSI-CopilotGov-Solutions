# Pearlman — History

## Seed (2026-06-05)
- **Project:** FSI-CopilotGov-Solutions — 23 documentation-first governance solutions.
- **User:** Jude. Priority: **accuracy over cost**.
- **My job:** Apply Freamon's verified fixes under strict FSI language rules; keep README ↔ `data/` ↔ `docs/` in sync; bump version + CHANGELOG.
- **Hard rules:** no "ensures compliance/guarantees/eliminates risk"; no overstated live-API claims (scripts use sample data); status stays "Documentation-first scaffold"; Dataverse logical names lowercase no inserted underscores; reuse `scripts/common/`.

## Learnings

## 2026-06-05 — Pass-2 MS Learn accuracy: 7 solutions (squad/accuracy-pass2)

### Edits applied (one per finding)

| Sol | Finding | File(s) changed |
|-----|---------|----------------|
| 03 | Removed unverifiable "(previously only emails)" parenthetical from auto-labeling label-override statement | README.md:150 |
| 08 | "message meter / $0.01 per message" → "pay-as-you-go meter / $0.01 per Copilot Credit"; added per-interaction credit costs to architecture note; fixed outdated CHANGELOG pass-1 entry | README.md:13, docs/architecture.md:128, CHANGELOG.md |
| 10 | "through configuration rather than code" → "using Copilot's own orchestrator and models, buildable with low-code or pro-code tooling" | README.md:13 |
| 14 | Removed "or risky intent" from IRM Risky AI usage detection clause (MS Learn says "sensitive information" only for Copilot-specific detection) | docs/architecture.md:142 |
| 17 | "Permission state reports" → "Site permissions" report (current SAM Data Access Governance report name) | docs/architecture.md:49 |
| 18 | "Enterprise Mobility + Security (EMS) E5" → "Microsoft Entra ID Governance, Microsoft Entra Suite, or Microsoft Entra ID P2" (outdated bundle name) | docs/prerequisites.md:6 |
| 19 | "Microsoft 365 Copilot Agent Builder" → "Agent Builder in Microsoft 365 Copilot"; "Agent 365" → "Microsoft Agent 365" (both occurrences) | README.md:29, README.md:101 |

### Version bumps

| Sol | Old | New |
|-----|-----|-----|
| 03 | v0.2.3 | v0.2.4 |
| 08 | v0.1.2 | v0.1.3 |
| 10 | v0.2.2 | v0.2.3 |
| 14 | v0.2.3 | v0.2.4 |
| 17 | v0.1.3 | v0.1.4 |
| 18 | v0.1.3 | v0.1.4 |
| 19 | v0.1.3 | v0.1.4 |

### Propagation surfaces touched per solution (standard set)
- README.md status line
- CHANGELOG.md (new version entry)
- DELIVERY-CHECKLIST.md version line (where present — sols 17/18/19 DELIVERY-CHECKLIST carried no version line)
- config/default-config.json `version` field (and `last_verified` where already present: 08, 10, 19)
- data/solution-catalog.json (each solution's `version` field)
- scripts/solution-config.yml (each solution's `version` field)

### Propagation surface that tripped a validator
- **Sol 19 Pester test** (`19-CopilotTuningGovernance.Tests.ps1:129`) had the version hard-coded as `v0\.1\.3` in the status-line regex. Bumped to `v0\.1\.4` before commit. **Lesson: always grep solution tests for hard-coded version strings before committing a version bump.** Pattern to grep: `v0\.\d+\.\d+` in `tests/*.ps1`.

### Lessons
- Sol 03 architecture.md had NO occurrence of "(previously only emails)" — Freamon's finding referenced architecture.md line 162 but grep confirmed only README.md:150 contained the text. Trust grep over line references when in doubt.
- Sol 08 pass-1 CHANGELOG entry itself was outdated ("$0.01-per-message"); fixed inline alongside the primary corrections.

## Pass-2 Consolidation (2026-06-05)
- **Outcome:** All 7 corrections applied (solutions 03, 08, 10, 14, 17, 18, 19); full version propagation completed; all 9 validators green; 93 Pester tests pass; PR #290 approved and merged to main.
- All 7 validators passed GREEN. All touched Pester suites passed (9+8+10+21+18+10+17 tests).



- Applied 1 major + 5 minor findings from Freamon's MS Learn verification.
- Major: "message packs" / "25,000-message packs" → "Copilot Studio capacity packs" / "25,000 Copilot Credits/month/pack". .01 figure attributed specifically to Copilot Studio message meter.
- Minor: billing policy scope broadened (security groups → security groups, distribution groups, or tenant). Config keys renamed (no script/test references existed, safe rename). Internal README inconsistency resolved.
- Config keys renamed: messagePacksEnabled → capacityPacksEnabled, highUsageThresholdMessagesPerDay → highUsageThresholdCreditsPerDay, billingPolicyScopeType value broadened.
- Lesson: grep ALL solution files for config keys before renaming — this time zero refs in scripts/tests made it safe.
- Version: v0.1.1 → v0.1.2. Pester 8/8 pass. Commit ecf48cf.
## 2026-06-05 — Solution 06 accuracy edit

- **Findings applied:** 2 minor (deprecated portal naming). 0 blockers, 0 major.
- **Pattern:** "Microsoft Purview compliance portal" → "Microsoft Purview portal" (compliance.microsoft.com retired into purview.microsoft.com).
- **Citation:** https://learn.microsoft.com/purview/audit-get-started
- **Version:** v0.2.2 → v0.2.3 (PATCH).
- **Propagation:** README status line, CHANGELOG, default-config.json, data/solution-catalog.json, scripts/solution-config.yml. DELIVERY-CHECKLIST and tests had no version line to update.
- **Lesson:** Solution 06 was high-accuracy overall (9 verified claims). Only 2 minor cosmetic portal-name nits. Freamon's review method (MS Learn fetch per claim) is effective at catching branding drift without false positives.
