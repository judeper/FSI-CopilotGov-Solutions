# Bunk Verdict — Solution 02: Oversharing Risk Assessment and Remediation

- **Reviewer:** Bunk (QA gate, owl-mode adversarial)
- **Date:** 2026-06-05T18:54-04:00
- **Worktree:** `C:\dev\FSI-CopilotGov-Solutions-acc02` (branch `squad/accuracy-02`)
- **HEAD:** `7fde52a` — fix(02): correct Microsoft product/feature accuracy per MS Learn
- **Findings reviewed:** `.squad\decisions\inbox\freamon-02.md`

## VERDICT: **REJECT** (1 blocking sync gap; otherwise solid)

The edits themselves are correct, citation-accurate, and language-clean. Validators are all green. However, the README version was bumped to `v0.2.2` without a corresponding bump in `data/solution-catalog.json`, which still records solution 02 as `v0.2.1`. Per the team rule (README ↔ data/ metadata ↔ docs/*.md consistent) and the precedent set by solution 01 (catalog version tracks README), this is a blocking sync miss.

## Validator Summary (worktree root)

| Validator | Result | Notes |
|---|---|---|
| `python scripts/validate-documentation.py` | ✅ PASS (exit 0) | 375 markdown files checked |
| `python scripts/validate-solutions.py` | ✅ PASS (exit 0) | 23 solutions validated |
| `python scripts/validate_solutions_json.py` | ✅ PASS (exit 0) | 23 solutions validated |
| `python scripts/validate_solutions_graph.py` | ✅ PASS (exit 0) | tier1=6 tier2=9 tier3=8, 56 framework controls referenced |
| `python scripts/verify_readme_counts.py` | ✅ PASS (exit 0) | 23 solutions / 58 controls / 243 playbooks |
| `python scripts/build-docs.py` | ✅ PASS (exit 0) | Documentation build inputs refreshed |
| `pwsh ParseFile Deploy-Solution.ps1` | ✅ PS-PARSE-OK (exit 0) | No syntax errors |

Note: validators do not currently cross-check README version vs `solution-catalog.json` version, which is why this drift is green-on-CI but still wrong by convention.

## Coverage Assessment vs Findings File

| Finding | Severity | Addressed? | Notes |
|---|---|---|---|
| `prerequisites.md:33` PnP min "PS 7.2" → must be "PS 7.4.0 or later" | major | ✅ YES | Edit reads `"PnP.PowerShell 3.x requires PowerShell 7.4.0 or later."` — matches citation `pnp.github.io/powershell/articles/installation.html` verbatim. |
| `prerequisites.md:33` Azure Automation "PnP 2.12 / PS 7.2 only" outdated (PS 7.4 runtime GA) | minor | ✅ YES | Rewritten to: `"Azure Automation environments using the older PowerShell 7.2 runtime are limited to PnP.PowerShell 2.12.0; the PowerShell 7.4 runtime (GA) supports current PnP.PowerShell versions."` — exactly the recommended re-scoping. |
| SAM SKU naming: drop "Microsoft" prefix; use exact name "SharePoint Advanced Management Plan 1" (5 listed locations: README.md:44; prerequisites.md:5; deployment-guide.md:15; Deploy-Solution.ps1:78,88) | minor | ✅ YES (+1 bonus) | All 5 listed sites corrected, plus an additional catch in `DELIVERY-CHECKLIST.md` (same string pattern). Total 6 occurrences updated — verified zero residual `"Microsoft SharePoint Advanced Management"` strings remain in the solution folder. Exact name matches Learn citation. |
| 10 verified-clean claims (Restricted SP Search, DSPM-for-AI weekly top-100, `extractSensitivityLabels` Graph + scopes, VIEW+EXTRACT usage rights, multi-tenant PnP app retirement, PS 7.4/.NET 8.0, module names, `Connect-MgGraph`/`Connect-PnPOnline`, Graph site/drive URIs, base-license+Copilot-or-SAM logic) | verified | n/a | Untouched — correctly left alone. |

Coverage: **complete on findings**; nothing silently dropped.

## Correctness / Owl-Mode Adversarial Checks

- **No over-correction.** Edits stay tightly scoped to the three flagged issues; no opportunistic rewrites of the 10 verified-clean claims.
- **No new unverified claims.** The Azure Automation rewrite says "PowerShell 7.4 runtime (GA) supports current PnP.PowerShell versions" — a defensible, non-specific claim that aligns with the runbook runtimes article without inventing version pairings.
- **Citation match (PnP minimum).** Confirmed: PnP install docs require PowerShell 7.4.0 or later — fix matches verbatim.
- **Citation match (SAM Plan 1 naming).** Findings explicitly recommend `"SharePoint Advanced Management Plan 1"` (no "Microsoft" prefix). Diff uses exactly that string in all 6 occurrences. ✅
- **No forbidden FSI phrases.** grep across the solution folder returned zero hits for `"ensures compliance"`, `"guarantees"`, `"will prevent"`, `"eliminates risk"`.
- **Status line intact and well-formed.** `> **Status:** Documentation-first scaffold | **Version:** v0.2.2 | **Priority:** P0 | **Track:** A | **Last Verified:** 2026-05-25` — format matches `AGENTS.md` rule; status string unchanged from "Documentation-first scaffold".
- **Required README sections.** Overview / Scope Boundaries / Related Controls / Prerequisites / Deployment / Evidence Export / Regulatory Alignment — all present (none touched by this commit; spot-checked).
- **CHANGELOG.** New `[v0.2.2] - 2026-06-05` entry under `### Fixed` accurately enumerates the three corrections. Date matches CURRENT_DATETIME. Version bump matches the README status line.
- **PowerShell parse.** `Deploy-Solution.ps1` parses cleanly after edits.
- **No live-API overstatement introduced.** The two edited Deploy-Solution.ps1 strings are descriptive prose inside a stub validator function; no new "scans", "captures", or "aggregates" verbs.

## Blocking Issues (gaps that must close before APPROVE)

1. **Version drift between README and `data/solution-catalog.json`.**
   - `solutions/02-oversharing-risk-assessment/README.md:3` is now `v0.2.2`.
   - `data/solution-catalog.json:81` still records solution 02 as `"version": "v0.2.1"`.
   - Solution 01 demonstrates the correct pattern: catalog `v0.2.2` ↔ README `v0.2.2`.
   - **Required fix:** update `data/solution-catalog.json` line 81 from `"version": "v0.2.1"` to `"version": "v0.2.2"`.

## Non-Blocking Observations (informational, no action required)

- `README.md:3` still shows `**Last Verified:** 2026-05-25`. The PR is a *correction*, not a re-verification of all 13 Microsoft claims, and solution 01 also retains its earlier "Last Verified" date after a similar fix. Leaving the field unchanged is consistent with current convention — no action requested.
- The validator suite does not currently enforce README↔catalog version parity. Worth considering as a future hardening (out of scope for this review).
- Commit message and CHANGELOG correctly call out that the DELIVERY-CHECKLIST.md SAM occurrence was also updated, beyond the 5 file:line locations Freamon explicitly listed — that's a legitimate broader-pattern catch, not a silent scope expansion.

## Resolution Path

Single one-line edit in `data/solution-catalog.json` to bump solution 02's `version` field from `v0.2.1` to `v0.2.2`, re-run the six validators (no behavior change expected), and this becomes APPROVE.
