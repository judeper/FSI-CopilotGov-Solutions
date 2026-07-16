# FSI-CopilotGov-Solutions Repository Instructions

This repository provides documentation-first governance solution scaffolds for the FSI Copilot Governance Framework.

- Treat `FSI-CopilotGov` as the source of truth for control language and playbook intent.
- Keep solution folders documentation-first for Power Automate and Power BI assets.
- Use precise phrases such as "supports compliance with" and "helps meet".
- Do not use overstated claims such as "performs Graph API-based scanning", "sequences license assignment", or "aggregates evidence into Power BI" when the scripts use representative sample data.
- Prefer reusable modules under `scripts/common/` instead of duplicating helper logic.
- Every solution README must include a "Scope Boundaries" section listing what the solution does NOT do.
- Every solution README status line must use the format: `> **Status:** Documentation-first scaffold | **Version:** vX.Y.Z | **Priority:** PX | **Track:** X`
- Every solution README must keep control mappings, regulatory alignment, and evidence-export details in sync with `data/` metadata files.
- Run `python scripts/validate-documentation.py` to check for forbidden phrases, overstated claims, required sections, and status line format.
- Run `python scripts/test_docs_protection.py` after changing `.github/branch-protection.json`, required workflow names/triggers, or the docs-autonomy gate.
- Keep `Docs Autonomy Gate` unfiltered at the `pull_request` trigger. Heavy documentation validators may be conditional inside the always-present job, but the job itself must never be path-filtered.
- Treat `.github/branch-protection.json` as a proposed source of truth only; do not apply live branch settings unless explicitly directed.
- Keep external network link checks non-required.

## Review and Lab Validation Lifecycle

- Solutions are reviewed one at a time for Microsoft product and feature accuracy, then hardened for read-only lab validation. The authoritative status snapshot, blockers, and resume sequence live in `docs/project-handoff.md` — read it before starting or resuming work.
- **Contract vs executor ownership.** `FSI-CopilotGov-Solutions` owns versioned lab contracts (`lab/<solution>.lab.json`), result and package validation, schemas, and fixtures. The separate `studio-video-factory` lane owns Playwright execution and evidence capture. Keep this repository documentation-first.
- **Read-only first cycle and dispositions.** The first lab cycle is read-only/detect-only; contracts normally declare `mutations: []`, and any non-null `mutationRef` must resolve to a declared mutation. Dispositions are `PASS`, `PARTIAL`, `BLOCKED`, `NOT-APPLICABLE`, and `FAIL`. Accepted `BLOCKED` and `NOT-APPLICABLE` require negative evidence **and** source verification and must not claim implemented control state.
- **Evidence and path portability.** Package artifact paths are relative (relocatable); caller-returned artifact paths are absolute. Resolve PowerShell paths provider-aware — never use raw `GetFullPath` on relative input. Never place raw identifiers, secrets, or PII in evidence.
- **Pester.** Pin Pester `5.7.1` and set `Run.Exit` to `true` so failing tests return a non-zero exit code.
- **Pester data-driven tests.** Do not define Pester tests inside a PowerShell `foreach` loop that relies on captured loop variables; use Pester's `-ForEach` parameter so values remain available at run time.
- **Strict MkDocs.** The site must build clean under `python -m mkdocs build --strict`.
- **Commercial-only contracts.** Forward-facing solution contracts omit the optional `prohibitedClouds` field and rely on the commercial-scope constants.

## Worktree and Branch Hygiene

- One modifying agent per worktree; a modifying agent owns its worktree exclusively. Never run `git checkout` in another agent's worktree.
- After a branch is pushed and its local worktree is clean, remove the worktree and local branch and prune merged worktrees.
- Preserve remote branches that back an open PR. Merged foundation remote branches (for example #315, #316, #318) may be deleted.

## Validation Commands

Run the deterministic validators from the repository root before pushing:

```powershell
python scripts/test_docs_protection.py
python scripts/build-docs.py
python scripts/validate-contracts.py
python scripts/validate-solutions.py
python scripts/validate-documentation.py
python scripts/validate_solutions_json.py
python scripts/validate_solutions_graph.py
python scripts/validate_data_classification.py
python scripts/verify_readme_counts.py
python scripts/verify_commercial_scope.py
python scripts/validate-lab-contracts.py
python scripts/validate-lab-result.py
python scripts/test_lab_validation_contracts.py
python -m mkdocs build --strict
pwsh -Command "Get-ChildItem -Recurse -Filter *.ps1 | ForEach-Object { [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$null) | Out-Null }"
```

## Site Design System

The documentation site uses a unified FSI design system shared across all FSI-AgentGov and FSI-CopilotGov repositories.

- **Theme:** MkDocs Material with `primary: custom` / `accent: custom` palette
- **Colors:** Microsoft Blue (`#0078D4`) primary, WCAG AA teal (`#007A7E`) accent, full dark mode tokens in `site-docs/stylesheets/extra.css`
- **Logo:** Shield + circuit motif SVG (`site-docs/assets/logo.svg`, `site-docs/assets/favicon.svg`)
- **Homepage pattern:** Hero section → metrics strip → role cards → architecture diagram (uses `hide: navigation, toc` frontmatter, `md_in_html` extension, `attr_list` for buttons)
- **Navigation:** `navigation.sections` is intentionally removed so sidebar sections collapse by default
- **Font:** `font: false` — avoids Google Fonts CDN (blocked in FSI network environments)
- **Extensions required:** `pymdownx.emoji` (icon shortcodes), `md_in_html` (hero/cards), `pymdownx.highlight` (code blocks)

When modifying the site theme, update `site-docs/stylesheets/extra.css` — do not change `primary`/`accent` in `mkdocs.yml` (they must stay `custom`).
