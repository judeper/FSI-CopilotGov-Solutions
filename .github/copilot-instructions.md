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
