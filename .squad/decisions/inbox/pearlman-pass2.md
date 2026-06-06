# Pearlman Pass-2 Decision Record

**Author:** Pearlman (Editor / Technical Writer)
**Date:** 2026-06-05
**Branch:** squad/accuracy-pass2
**Based on:** Freamon Pass-2 re-verification files `freamon-p2-03.md` through `freamon-p2-19.md`

---

## Summary

Applied all 7 confirmed minor findings from Freamon's Pass-2 MS Learn re-verification. Each correction is surgical — only the flagged text changed; all surrounding content, regulatory mappings, and evidence-export details are untouched.

---

## Corrections Applied

| Sol | Old Version | New Version | One-line correction |
|-----|-------------|-------------|---------------------|
| 03 | v0.2.3 | v0.2.4 | Removed unverifiable "(previously only emails)" parenthetical from service-side auto-labeling label-override statement (README.md:150) |
| 08 | v0.1.2 | v0.1.3 | Replaced "message meter / $0.01 per message" with "pay-as-you-go meter / $0.01 per Copilot Credit"; added per-interaction credit costs (1 credit classic, 2 credits generative) in architecture.md; fixed outdated CHANGELOG pass-1 entry |
| 10 | v0.2.2 | v0.2.3 | Replaced "through configuration rather than code" with "using Copilot's own orchestrator and models, buildable with low-code or pro-code tooling" for declarative agents (README.md:13) |
| 14 | v0.2.3 | v0.2.4 | Removed "or risky intent" from IRM Risky AI usage detection clause — MS Learn lists "sensitive information" only for Copilot-specific detection (docs/architecture.md:142) |
| 17 | v0.1.3 | v0.1.4 | Corrected SAM report name "Permission state reports" → "Site permissions" report (docs/architecture.md:49) |
| 18 | v0.1.3 | v0.1.4 | Replaced outdated "Enterprise Mobility + Security (EMS) E5" with "Microsoft Entra ID Governance, Microsoft Entra Suite, or Microsoft Entra ID P2" (docs/prerequisites.md:6) |
| 19 | v0.1.3 | v0.1.4 | Corrected "Microsoft 365 Copilot Agent Builder" → "Agent Builder in Microsoft 365 Copilot" and "Agent 365" → "Microsoft Agent 365" (README.md:29 and README.md:101) |

---

## Version Propagation Surfaces Updated (per solution)

For each of the 7 solutions:
- README.md status line version bumped
- CHANGELOG.md new version entry added (dated 2026-06-05)
- DELIVERY-CHECKLIST.md version line updated where present
- `config/default-config.json` `version` field updated; `last_verified` updated to 2026-06-05 where field already existed (sols 08, 10, 19)
- `data/solution-catalog.json` entry `version` field updated
- `scripts/solution-config.yml` entry `version` field updated
- `solutions.json`, `solutions-graph.json`, `site-docs/` regenerated via build scripts
- Sol 19 Pester test version regex updated from `v0\.1\.3` to `v0\.1\.4`

---

## Validator Results (all GREEN)

| Validator | Result |
|-----------|--------|
| `validate-documentation.py` | ✅ PASS — 375 markdown files checked |
| `validate-solutions.py` | ✅ PASS — 23 solutions validated |
| `validate_solutions_json.py` | ✅ PASS — 23 solutions validated |
| `validate_solutions_graph.py` | ✅ PASS — 23 solutions (tier1=6 tier2=9 tier3=8) |
| `verify_readme_counts.py` | ✅ PASS |
| PS1 syntax check | ✅ PASS |
| Pester sols 03/08/10/14/17/18/19 | ✅ PASS — 9+8+10+21+18+10+17 tests |

---

## Status

- Branch: `squad/accuracy-pass2`
- NOT pushed — Daniels handles push + PR
