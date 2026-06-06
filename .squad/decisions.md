# Squad Decisions

## Pass-2 MS Learn Accuracy Review (2026-06-05)

**Status:** COMPLETED | **Outcome:** 16 CLEAN, 7 minor corrections | **Scope:** all 23 solutions | **PR:** #290

### Re-Verification Results

Freamon re-verified all 23 solutions against current MS Learn (second-opinion pass):
- **16 solutions:** CLEAN (no inaccuracies found)
  - Solutions 01, 02, 04, 05, 06, 07, 09, 11, 12, 13, 15, 16, 20, 21, 22, 23
- **7 solutions:** Minor findings identified and corrected
  - Solutions 03, 08, 10, 14, 17, 18, 19

### Corrections Applied

Pearlman applied 7 corrections per Freamon findings; all version propagation completed:

| Sol | Old → New | Correction | Files |
|-----|-----------|-----------|-------|
| 03 | v0.2.3 → v0.2.4 | Removed unverifiable "(previously only emails)" parenthetical from service-side auto-labeling label-override statement | README.md |
| 08 | v0.1.2 → v0.1.3 | Replaced outdated "message meter / $0.01 per message" with "pay-as-you-go meter / $0.01 per Copilot Credit"; added per-interaction credit costs (1 credit classic, 2 generative) | README.md, docs/architecture.md, CHANGELOG.md |
| 10 | v0.2.2 → v0.2.3 | Replaced "through configuration rather than code" with "using Copilot's own orchestrator and models, buildable with low-code or pro-code tooling" for declarative agents | README.md |
| 14 | v0.2.3 → v0.2.4 | Removed "or risky intent" from IRM Risky AI usage detection clause (MS Learn specifies "sensitive information" only) | docs/architecture.md |
| 17 | v0.1.3 → v0.1.4 | Corrected SAM report name "Permission state reports" → "Site permissions" | docs/architecture.md |
| 18 | v0.1.3 → v0.1.4 | Replaced outdated "Enterprise Mobility + Security (EMS) E5" with "Microsoft Entra ID Governance, Microsoft Entra Suite, or Microsoft Entra ID P2" | docs/prerequisites.md |
| 19 | v0.1.3 → v0.1.4 | Corrected "Microsoft 365 Copilot Agent Builder" → "Agent Builder in Microsoft 365 Copilot"; "Agent 365" → "Microsoft Agent 365" | README.md |

### Validation & Merge

- **Bunk gate:** PR #290 approved; all 9 validators pass green (validate-documentation.py, validate-solutions.py, validate_solutions_json.py, validate_solutions_graph.py, verify_readme_counts.py, PowerShell parse, Pester 93 tests)
- **Consolidation:** PR #290 squash-merged to main (commit 72ceb22); all 10 CI checks green
- **Prior work:** All 23 accuracy PRs from pass-1 + #288 (state consolidation) + #289 (solutions-graph regen) merged to main

---

## Active Decisions

No decisions recorded yet.

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
