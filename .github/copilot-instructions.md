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
