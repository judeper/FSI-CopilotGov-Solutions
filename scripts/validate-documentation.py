#!/usr/bin/env python3
"""Validate documentation: check language rules, required sections, and link integrity."""

import json
import re
from pathlib import Path

from traceability import FRAMEWORK_REPO_REF, UNPINNED_FRAMEWORK_REF_RE

ROOT = Path(__file__).resolve().parent.parent
SOLUTIONS_ROOT = ROOT / "solutions"
DOC_ROOTS = [SOLUTIONS_ROOT, ROOT / "docs", ROOT / "site-docs"]
EXAMINATION_READINESS = ROOT / "docs" / "reference" / "examination-readiness.md"

FORBIDDEN_PHRASES = [
    "ensures compliance",
    "guarantees compliance",
    "will prevent",
    "eliminates risk",
    "fully compliant",
    "100% compliant",
]

OVERSTATED_CLAIM_PATTERNS = [
    (re.compile(r"performs\s+graph\s+api[- ]based\s+scanning", re.IGNORECASE), "implies live Graph scanning"),
    (re.compile(r"captures\s+.*snapshots?\s+through\s+graph", re.IGNORECASE), "implies live Graph data capture"),
    (re.compile(r"sequences\s+.*license\s+assignment", re.IGNORECASE), "implies automated license assignment"),
    (re.compile(r"aggregates\s+evidence\s+.*into\s+.*power\s+bi", re.IGNORECASE), "implies deployed Power BI integration"),
    (re.compile(r"(?:^|\s)Status:\s*implemented", re.IGNORECASE), "solution-level 'implemented' status is not permitted"),
]

REQUIRED_README_SECTIONS = [
    "## Overview",
    "## Related Controls",
    "## Prerequisites",
    "## Deployment",
    "## Evidence Export",
    "## Regulatory Alignment",
    "## Scope Boundaries",
]


def check_language(path: Path) -> list:
    errors = []
    text = path.read_text(encoding="utf-8", errors="replace")
    text_lower = text.lower()
    for phrase in FORBIDDEN_PHRASES:
        if phrase.lower() in text_lower:
            errors.append(f"{path.relative_to(ROOT)}: forbidden phrase '{phrase}'")
    for pattern, reason in OVERSTATED_CLAIM_PATTERNS:
        if pattern.search(text):
            errors.append(f"{path.relative_to(ROOT)}: overstated claim ({reason})")
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


STATUS_LINE_RE = re.compile(
    r"^>\s*\*\*Status:\*\*\s*Documentation-first\s",
    re.MULTILINE,
)


def check_status_line(path: Path) -> list:
    text = path.read_text(encoding="utf-8", errors="replace")
    if not STATUS_LINE_RE.search(text):
        return [
            f"{path.relative_to(ROOT)}: status line must use bold blockquote format starting with 'Documentation-first'"
        ]
    return []


def check_framework_link_pinning(path: Path) -> list:
    text = path.read_text(encoding="utf-8", errors="replace")
    if UNPINNED_FRAMEWORK_REF_RE.search(text):
        return [
            f"{path.relative_to(ROOT)}: contains unpinned FSI-CopilotGov blob/tree reference; use commit {FRAMEWORK_REPO_REF}"
        ]
    return []


def split_markdown_row(line: str) -> list[str]:
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def check_examination_readiness_table(path: Path) -> list:
    errors = []
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    table_header = "| Solution | Evidence Outputs | Key Regulations | Framework IDs |"
    try:
        start = lines.index(table_header)
    except ValueError:
        return [f"{path.relative_to(ROOT)}: missing framework traceability table header"]

    rows = []
    for line in lines[start + 2 :]:
        if not line.strip().startswith("|"):
            break
        cells = split_markdown_row(line)
        if len(cells) != 4:
            errors.append(f"{path.relative_to(ROOT)}: malformed table row '{line.strip()}'")
            continue
        rows.append(cells)

    catalog = json.loads((ROOT / "data" / "solution-catalog.json").read_text(encoding="utf-8"))
    expected_rows = {
        item["display_name"]: {
            "evidence_outputs": ", ".join(item["evidence_outputs"]),
            "regulations": ", ".join(item["regulations"]),
            "framework_ids": ", ".join(item["framework_ids"]),
        }
        for item in catalog
    }

    if len(rows) != len(expected_rows):
        errors.append(
            f"{path.relative_to(ROOT)}: expected {len(expected_rows)} solution rows, found {len(rows)}"
        )

    seen = set()
    for solution, evidence_outputs, regulations, framework_ids in rows:
        expected = expected_rows.get(solution)
        if not expected:
            errors.append(f"{path.relative_to(ROOT)}: unknown solution row '{solution}'")
            continue
        seen.add(solution)
        if evidence_outputs != expected["evidence_outputs"]:
            errors.append(
                f"{path.relative_to(ROOT)}: evidence outputs drift for '{solution}'"
            )
        if regulations != expected["regulations"]:
            errors.append(f"{path.relative_to(ROOT)}: key regulations drift for '{solution}'")
        if framework_ids != expected["framework_ids"]:
            errors.append(f"{path.relative_to(ROOT)}: framework ids drift for '{solution}'")

    missing = set(expected_rows) - seen
    for solution in sorted(missing):
        errors.append(f"{path.relative_to(ROOT)}: missing row for '{solution}'")
    return errors


def main() -> None:
    all_errors = []

    md_files = []
    for root in DOC_ROOTS:
        if root.exists():
            md_files.extend(root.rglob("*.md"))

    unique_md_files = sorted({path.resolve(): path for path in md_files}.values())

    # Check language rules in solution markdown only.
    for md_file in SOLUTIONS_ROOT.rglob("*.md"):
        all_errors.extend(check_language(md_file))

    # Check README required sections
    for readme in SOLUTIONS_ROOT.glob("*/README.md"):
        all_errors.extend(check_readme_sections(readme))
        all_errors.extend(check_status_line(readme))

    for md_file in unique_md_files:
        all_errors.extend(check_framework_link_pinning(md_file))

    all_errors.extend(check_examination_readiness_table(EXAMINATION_READINESS))

    if all_errors:
        raise SystemExit(
            f"Documentation validation failed ({len(all_errors)} issues):\n"
            + "\n".join(f"  - {e}" for e in all_errors)
        )

    print(f"Documentation validation passed: {len(unique_md_files)} markdown files checked.")


if __name__ == "__main__":
    main()
