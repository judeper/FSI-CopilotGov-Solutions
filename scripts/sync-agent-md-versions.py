#!/usr/bin/env python3
"""
Drift gate: solution inventory in AGENTS.md vs solutions.json.

This is the durable gate that prevents the "Nineteen vs N solutions" class of
drift that PR #301 had to correct reactively.  Ported from the FSI-AgentGov-
Solutions sibling (scripts/sync-agent-md-versions.py) and re-fit to
FSI-CopilotGov-Solutions reality:

  * solutions.json is an **array** (not a dict keyed by ID)
  * AGENTS.md catalog format: | ID | Solution | Priority | Track | Controls |
  * No version/controls sync — CopilotGov solutions.json carries no controls
    field; the Controls column in AGENTS.md is curated separately.
  * Additionally guards prose English-number count phrases near "solution" so
    stale sentences like "Nineteen Copilot governance solution folders" are
    flagged automatically.

Checks performed:
  1. AGENTS.md catalog row count  ==  len(solutions.json[solutions])
  2. Every catalog row numeric ID (01, 02, ...) maps to a real solutions.json
     entry; no phantom rows.
  3. Every solutions.json entry has exactly one catalog row; no missing rows.
  4. English number-word count phrases near "solution" in AGENTS.md and
     .github/copilot-instructions.md match the actual count.

Usage:
    python scripts/sync-agent-md-versions.py            # auto-fix prose, report
    python scripts/sync-agent-md-versions.py --check    # exit 1 if any drift
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SOLUTIONS_JSON = REPO_ROOT / "solutions.json"
AGENTS_MD = REPO_ROOT / "AGENTS.md"
COPILOT_INSTRUCTIONS = REPO_ROOT / ".github" / "copilot-instructions.md"

# Catalog table data row: first cell is a 2-digit numeric ID.
# Example: | 01 | Copilot Readiness Assessment Scanner | P0 | A | 1.1, … |
CATALOG_ROW_RE = re.compile(r"^\|\s*(\d{2})\s*\|")

# English number words for plausible solution counts (1–30).
_WORDS = [
    "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
    "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
    "seventeen", "eighteen", "nineteen", "twenty",
    "twenty-one", "twenty-two", "twenty-three", "twenty-four", "twenty-five",
    "twenty-six", "twenty-seven", "twenty-eight", "twenty-nine", "thirty",
]
WORD_TO_INT: dict[str, int] = {w: i + 1 for i, w in enumerate(_WORDS)}
INT_TO_WORD: dict[int, str] = {v: k for k, v in WORD_TO_INT.items()}

# Matches an English number word followed (within the same line) by "solution".
_word_alt = "|".join(re.escape(w) for w in sorted(WORD_TO_INT, key=len, reverse=True))
PROSE_COUNT_RE = re.compile(
    r"\b(" + _word_alt + r")\b(?=[^\n]*\bsolution)",
    re.IGNORECASE,
)


def load_solutions() -> list[dict]:
    raw = json.loads(SOLUTIONS_JSON.read_text(encoding="utf-8"))
    sols = raw.get("solutions") or []
    if not isinstance(sols, list):
        sys.exit(
            f"solutions.json: expected 'solutions' to be an array, got {type(sols).__name__}"
        )
    return sols


def _numeric_prefix(sol_id: str) -> str:
    """Return the 2-digit numeric prefix from a solution ID.

    '01-copilot-readiness-scanner' -> '01'
    """
    return sol_id.split("-")[0]


def check_catalog(solutions: list[dict]) -> list[str]:
    """Return drift descriptions for the AGENTS.md Solution Catalog table."""
    if not AGENTS_MD.exists():
        return [f"AGENTS.md not found at {AGENTS_MD}"]

    sol_by_num: dict[str, dict] = {_numeric_prefix(s["id"]): s for s in solutions}
    expected_count = len(solutions)

    text = AGENTS_MD.read_text(encoding="utf-8")
    catalog_nums: list[str] = []
    in_catalog = False

    for line in text.splitlines():
        if "## Solution Catalog" in line:
            in_catalog = True
            continue
        if in_catalog and line.startswith("## "):
            # Next heading ends the catalog section.
            break
        if in_catalog:
            m = CATALOG_ROW_RE.match(line)
            if m:
                catalog_nums.append(m.group(1))

    drift: list[str] = []

    if len(catalog_nums) != expected_count:
        drift.append(
            f"AGENTS.md catalog row count mismatch: "
            f"got {len(catalog_nums)}, expected {expected_count} (per solutions.json)"
        )

    for num in catalog_nums:
        if num not in sol_by_num:
            drift.append(
                f"AGENTS.md catalog: row ID '{num}' has no matching entry in solutions.json"
            )

    catalog_set = set(catalog_nums)
    for num, sol in sorted(sol_by_num.items()):
        if num not in catalog_set:
            drift.append(
                f"AGENTS.md catalog: missing row for solution '{sol['id']}' (expected ID '{num}')"
            )

    return drift


def sync_prose_counts(
    solutions: list[dict], path: Path, check_only: bool
) -> tuple[list[str], bool]:
    """Check (and optionally fix) English-number count words near 'solution'.

    Returns (drift_list, was_changed).
    """
    if not path.exists():
        return [], False

    expected = len(solutions)
    expected_word = INT_TO_WORD.get(expected)
    original = path.read_text(encoding="utf-8")
    drift: list[str] = []

    def replacer(m: re.Match) -> str:
        word_lower = m.group(1).lower()
        actual_int = WORD_TO_INT.get(word_lower, 0)
        if actual_int == expected:
            return m.group(1)  # already correct

        display = expected_word or str(expected)
        rel = path.relative_to(REPO_ROOT)
        drift.append(
            f"{rel}: prose says '{m.group(1)}' solutions "
            f"but solutions.json has {expected} "
            f"(should be '{display}')"
        )
        if expected_word is None:
            return m.group(1)  # no known word; leave as-is

        orig = m.group(1)
        if orig[0].isupper():
            # Preserve title-case capitalisation (e.g. "Nineteen" → "Twenty-three").
            return expected_word[0].upper() + expected_word[1:]
        return expected_word

    new_text = PROSE_COUNT_RE.sub(replacer, original)
    changed = new_text != original

    if changed and not check_only:
        path.write_text(new_text, encoding="utf-8")

    return drift, changed


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        "--check",
        action="store_true",
        help="Do not write; exit 1 if any drift is detected.",
    )
    args = p.parse_args()

    solutions = load_solutions()
    total_drift: list[str] = []

    # Gate 1: catalog table presence, count, and ID integrity.
    total_drift.extend(check_catalog(solutions))

    # Gate 2: prose English-number count words in AGENTS.md + copilot-instructions.md.
    prose_files_changed = 0
    for path in (AGENTS_MD, COPILOT_INSTRUCTIONS):
        prose_drift, changed = sync_prose_counts(solutions, path, args.check)
        total_drift.extend(prose_drift)
        if changed and not args.check:
            prose_files_changed += 1
            print(f"  Fixed prose count(s) in {path.relative_to(REPO_ROOT)}")

    if args.check:
        if total_drift:
            print("DRIFT detected — solution inventory or prose counts are out of sync:\n")
            for d in total_drift:
                print(f"  {d}")
            print(
                f"\nTo fix prose drift: run `python {Path(__file__).relative_to(REPO_ROOT)}` "
                "(without --check).\n"
                "To fix catalog table drift: manually update AGENTS.md ## Solution Catalog."
            )
            return 1
        print(
            f"No drift: {len(solutions)} solutions in AGENTS.md catalog "
            "and prose are in lockstep with solutions.json."
        )
        return 0

    # Non-check (fix) mode.
    if total_drift:
        print("Remaining issues (require manual fix — cannot be auto-corrected):")
        for d in total_drift:
            print(f"  {d}")
        return 1

    if prose_files_changed:
        print(
            f"OK: updated prose count(s) in {prose_files_changed} file(s). "
            f"{len(solutions)} solutions in sync."
        )
    else:
        print(
            f"OK: {len(solutions)} solutions — AGENTS.md catalog and prose "
            "are in sync with solutions.json. No changes needed."
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
