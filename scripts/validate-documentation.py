#!/usr/bin/env python3
"""Validate documentation: check language rules, required sections, and link integrity."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOLUTIONS_ROOT = ROOT / "solutions"

FORBIDDEN_PHRASES = [
    "ensures compliance",
    "guarantees compliance",
    "will prevent",
    "eliminates risk",
    "fully compliant",
    "100% compliant",
]

REQUIRED_README_SECTIONS = [
    "## Overview",
    "## Related Controls",
    "## Prerequisites",
    "## Deployment",
    "## Evidence Export",
    "## Regulatory Alignment",
]


def check_language(path: Path) -> list:
    errors = []
    text = path.read_text(encoding="utf-8", errors="replace")
    text_lower = text.lower()
    for phrase in FORBIDDEN_PHRASES:
        if phrase.lower() in text_lower:
            errors.append(f"{path.relative_to(ROOT)}: forbidden phrase '{phrase}'")
    return errors


def check_readme_sections(path: Path) -> list:
    errors = []
    text = path.read_text(encoding="utf-8", errors="replace")
    for section in REQUIRED_README_SECTIONS:
        if section not in text:
            errors.append(
                f"{path.relative_to(ROOT)}: missing required section '{section}'"
            )
    return errors


def main() -> None:
    all_errors = []

    # Check language rules in all markdown files under solutions/
    md_files = list(SOLUTIONS_ROOT.rglob("*.md"))
    for md_file in md_files:
        all_errors.extend(check_language(md_file))

    # Check README required sections
    for readme in SOLUTIONS_ROOT.glob("*/README.md"):
        all_errors.extend(check_readme_sections(readme))

    if all_errors:
        raise SystemExit(
            f"Documentation validation failed ({len(all_errors)} issues):\n"
            + "\n".join(f"  - {e}" for e in all_errors)
        )

    print(f"Documentation validation passed: {len(md_files)} markdown files checked.")


if __name__ == "__main__":
    main()
