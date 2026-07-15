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

### Issues Batch Consolidation (2026-06-06)

**Status:** COMPLETED | **PR:** #292 | **Commit:** bc72a69 (squash merge) | **Prior work:** Freamon verified (commit b6fd15e) → Pearlman implemented → Bunk APPROVED

#### Decision: Consolidate Issue #221, #101, #73, #75 Batch

**Scope:** Four issues merged via PR #292 (squash to bc72a69)
- **#221:** SecureString hardening — 7 sites converted to `[System.Security.SecureString]` with IDENTITY-STANDARD markers
- **#101:** Sol 02 SAM licensing wording — applied Freamon's verified F1 improved wording (base subscriptions, K/P1/P2 sub-dependency, site-creation note); F2 (DSPM) confirmed already fixed, no change
- **#73 + #75:** Sol 23 Agent 365 enhancements — Both README.md and architecture.md confirmed already correct by Freamon; applied two optional enhancements: (a) sol 23 docs/prerequisites.md Agent 365 GA date (2026-05-01), per-user licensing, E5 recommendation, plans link; (b) docs/architecture.md M365 admin center nav path (Agents > All Agents > Registry)

**Versions Bumped:**
- Sol 02: v0.2.2 → v0.2.3
- Sol 18: v0.1.4 → v0.1.5
- Sol 23: v0.1.3 → v0.1.4

**Validation:** All 9 validators green (build-docs.py, validate-contracts.py, validate-solutions.py, validate-documentation.py, validate_solutions_json.py, validate_solutions_graph.py, verify_readme_counts.py, PS1 syntax parse, Pester 93 tests)

**What Was NOT Done:** Stage 3 CI workflow for managed identity audit (Issue #221 acceptance: file follow-up, not add workflow in this batch; coordinator to file follow-up issue)

**Team:** Freamon (research/verification), Pearlman (implementation/edits), Bunk (approval)

---

### Key Verified Facts — Agent 365 + SAM + DSPM (2026-06-06)

**Agent 365 Control Plane:**
- Generally available as of May 1, 2026 — Commercial segment, per-user licensing
- Centralized agent registry in Microsoft 365 admin center (navigate: Agents > All Agents > Registry)
- Control plane for: centralized registry, lifecycle management, access control (Entra), compliance (Purview)
- Microsoft E5 recommended as base subscription; at least one user must be licensed with Agent 365 per-user license
- **Source:** https://learn.microsoft.com/en-us/microsoft-agent-365/overview; https://learn.microsoft.com/en-us/microsoft-365/admin/manage/agent-registry

**SharePoint Advanced Management (SAM) Entitlement:**
- Base subscription required (one of): Office 365 E3/E5/A5; Microsoft 365 E1/E3/E5/A5; Microsoft 365 GCC/GCC-High/DoD
- PLUS one of: (a) At least one user assigned Microsoft 365 Copilot license → SAM capabilities granted automatically; (b) Subscription includes SharePoint K/P1/P2 → purchase SharePoint Advanced Management Plan 1 add-on
- Some features (e.g., restricted site creation) require SAM Plan 1 even when Copilot licenses present
- **Source:** https://learn.microsoft.com/en-us/sharepoint/sharepoint-advanced-management-prerequisites

**DSPM Naming + Prerequisites:**
- Product formerly called "DSPM for AI" is now "DSPM for AI (classic)" in portal; new version is simply "Data Security Posture Management"
- Prerequisites include: permissions (Compliance Admin, Global Admin, Purview Compliance Admin role group), Purview auditing, M365 Copilot user licenses, Edge/device/browser setup, pay-as-you-go billing for non-Copilot AI apps
- **Source:** https://learn.microsoft.com/en-us/purview/ai-microsoft-purview-considerations; https://learn.microsoft.com/en-us/purview/data-security-posture-management-learn-about

---

---

## Pass-1 MS Learn Accuracy Review — Archived Inbox Consolidation (2026-06-06)

**Status:** CONSOLIDATED | **Source:** Five pass-1 decision-inbox files (bunk-01/02, freamon-01/02/03) | **Track:** Hygiene archive

### Durable Verified Facts & Blocking Issues

Freamon's pass-1 accuracy review identified three corrections per solution (01, 02, 03) that became actionable for Pearlman. The corresponding Bunk verdicts flagged version-sync gaps as blocking issues. All findings are now reflected in main via PR #290 and related PRs.

**Solution 01 (Copilot Readiness Assessment Scanner) — v0.2.2 → v0.2.3**
- **Blocking issue (Bunk):** Version bump applied only to README.md and CHANGELOG.md; convention requires 10 files to be updated (catalog, solution-config.yml, DELIVERY-CHECKLIST.md, default-config.json, Pester test). All 10 sync gaps were remediated in amend/re-review pass.
- **Verified accuracy findings (Freamon):** (1) API name "Microsoft Copilot Retrieval API" → "Microsoft 365 Copilot Retrieval API" (2) Entra role "Directory Reader" → "Directory Readers" (plural) (3) Unverifiable named offering "Microsoft 365 Copilot Optimization Assessment" softened to generic "Copilot readiness and optimization guidance."

**Solution 02 (Oversharing Risk Assessment) — v0.2.2 (approved re-review)**
- **Blocking issue (Bunk/resolved):** Catalog entry lagged README version (v0.2.1 vs v0.2.2); resolved in version-propagation amend.
- **Verified accuracy findings (Freamon):** (1) PnP.PowerShell minimum "PowerShell 7.2 or later" → "PowerShell 7.4.0 or later" (major; current PnP docs require 7.4.0) (2) Azure Automation note partially outdated (now offers PS 7.4 runtime; "limited to PS 7.2" no longer universally true) (3) SAM add-on name "SharePoint Advanced Management" → "SharePoint Advanced Management Plan 1" (minor naming precision, 6 sites affected).

**Solution 03 (Sensitivity Label Coverage Auditor) — v0.2.2**
- **Major accuracy gaps (Freamon):** (1) Auto-labeling throughput cap stated 4× as "100,000 files per policy per day" — incorrect scoping; correct: "100,000 files per **tenant** per day" (README.md:16, README.md:145, architecture.md:162, deployment-guide.md:94). Overstates remediation-wave capacity. (2) `assignSensitivityLabel` API is metered/billable (charges may apply); solution omits this material fact for bulk-remediation cost planning (README.md:146, troubleshooting.md).

### Version-Sync Convention

Established in commit e1099b2 (ref: solution-01 v0.2.1 → v0.2.2 bump): a solution version bump touches **10 surfaces** (README status line, CHANGELOG, default-config.json, catalog, solution-config.yml, DELIVERY-CHECKLIST.md, Pester test version assertion, site-docs auto-regenerated from README). Validators do not enforce cross-file version parity (out-of-scope for this review but flagged for future hardening).

---

## Active Decisions

No new active decisions pending.

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction

---

## Serial Accuracy Review Complete → Lab Finalization Blocked (2026-07)

**Status:** REVIEW COMPLETE / LAB EXECUTION BLOCKED | **Snapshot:** 2026-07-15 | **`main`:** `61e8921` | **PRs:** #317, #319–#340 (23 draft PRs, one per solution) | **Handoff:** `docs/project-handoff.md`

### Decision

The serial Microsoft product & feature accuracy review of all 23 solutions is complete. Each solution was reviewed **one at a time** against first-party Microsoft sources, hardened for read-only lab validation, and delivered as a green draft PR held with `Lab status: pending`. All 22 non-Solution-01 PRs are mergeable; PR #317 (Solution 01) conflicts with `main` and is deliberately deferred to post-lab finalization. No PR is merged.

### Contract / Executor Split

- `FSI-CopilotGov-Solutions` owns the versioned lab contracts (`lab/<solution>.lab.json`), result and package validation, schemas, and fixtures, and stays documentation-first.
- `studio-video-factory` owns Playwright execution and evidence capture.

### Evidence Gate

- First lab cycle is read-only/detect-only (`mutations: []` normally).
- Accepted `BLOCKED` / `NOT-APPLICABLE` dispositions require negative evidence **and** source verification; they must not claim implemented control state.
- Package artifact paths are relative; caller paths are absolute. Provider-aware PowerShell path handling (never raw `GetFullPath` on relative input). No raw identifiers, secrets, or PII in evidence. Pester `5.7.1` + `Run.Exit` true. Strict MkDocs. Commercial-only contracts omit optional `prohibitedClouds`.
- Known canonical control gaps: 2.17 (Sol 21), 3.14 (Sol 22), 4.14 (Sol 23) — omitted from machine-checked arrays until canonical.

### Cleanup Policy

Steady state: root on `main` only, no review worktrees or local review branches, merged foundation remotes (#315/#316/#318) deleted, remote branches backing open PRs preserved, generated leftovers (built `site/`, `__pycache__`) removed. One modifying agent per worktree; never `git checkout` in another agent's worktree.

### Next-Phase Blocker

Blocked until `studio-video-factory` `feat/pilot-a-readiness` merges. Then: build the lab adapter → serial read-only lab runs → accepted evidence → per-PR source recheck/versioning/rebase/merge in the documented serial order, resolving PR #317's existing conflict during finalization.

---

## Studio Pilot A Prerequisite Confirmed Merged (2026-07-15)

**Status:** PREREQUISITE CLEARED | **Studio PR:** [#7](https://github.com/judep_microsoft/studio-video-factory/pull/7) | **Merged:** 2026-07-13 | **Current action:** Build governance-validation adapter

### Correction

The prior July handoff recorded `studio-video-factory` `feat/pilot-a-readiness` as an unresolved blocker. A direct GitHub read-back confirmed that branch merged into `judep_microsoft/studio-video-factory` `main` through PR #7 on 2026-07-13. The upstream readiness prerequisite is therefore cleared.

### Updated Next Phase

Synchronize the studio repository to updated `main`, build the isolated governance-validation adapter, then execute the 23 read-only lab contracts serially. No live lab run or accepted evidence exists yet. PR #317 remains deferred for conflict resolution during post-lab finalization.
