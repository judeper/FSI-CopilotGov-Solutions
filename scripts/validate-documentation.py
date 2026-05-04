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
    (re.compile(r"performs\s+graph\s+api[- ]based\s+scanning", re.IGNORECASE), "implies live Graph scanning", "performs graph api scanning"),
    (re.compile(r"captures\s+.*snapshots?\s+through\s+graph", re.IGNORECASE), "implies live Graph data capture", "captures snapshots through graph"),
    (re.compile(r"sequences\s+.*license\s+assignment", re.IGNORECASE), "implies automated license assignment", "sequences license assignment"),
    (re.compile(r"aggregates\s+evidence\s+.*into\s+.*power\s+bi", re.IGNORECASE), "implies deployed Power BI integration", "aggregates evidence into power bi"),
    (re.compile(r"(?:^|\s)Status:\s*implemented", re.IGNORECASE), "solution-level 'implemented' status is not permitted", "status implemented"),
    (re.compile(r"\bzero[- ]trust\s+(?:guarantee|guaranteed|assured|complete)\b", re.IGNORECASE), "overstated zero-trust claim; prefer 'supports zero-trust principles' or similar", "zero-trust guarantee"),
    (re.compile(r"\b(?:fully|completely)\s+automated\b", re.IGNORECASE), "overstated automation; prefer 'documents the automation pattern for' or 'provides a framework for automating'", "fully automated"),
    (re.compile(r"\breal[- ]time\s+graph\s+api\b", re.IGNORECASE), "overstated live integration; scripts use representative sample data, not real-time Graph API calls", "real-time graph api"),
]

TOP_LEVEL_LANGUAGE_DOCS = [
    "DEPLOYMENT-GUIDE.md",
    "README.md",
    "CHANGELOG.md",
    "SOLUTION-README-TEMPLATE.md",
    "DELIVERY-CHECKLIST-TEMPLATE.md",
]

ALLOW_COMMENT_RE = re.compile(
    r'<!--\s*fsi-lang:allow="([^"]+)"\s+reason="([^"]+)"\s*-->',
    re.IGNORECASE,
)

REQUIRED_README_SECTIONS = [
    "## Overview",
    "## Related Controls",
    "## Prerequisites",
    "## Deployment",
    "## Evidence Export",
    "## Regulatory Alignment",
    "## Scope Boundaries",
]


def _is_allowed(lines: list[str], line_idx: int, key: str) -> bool:
    """Return True if a fsi-lang:allow comment suppresses `key`.

    The comment may appear on the same line as the finding (useful for
    markdown table cells) or up to 3 lines above it.
    """
    key_lower = key.lower()
    start = max(0, line_idx - 3)
    for j in range(start, line_idx + 1):
        match = ALLOW_COMMENT_RE.search(lines[j])
        if match and key_lower in match.group(1).lower():
            return True
    return False


def check_language(path: Path) -> list:
    errors = []
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    rel = path.relative_to(ROOT)
    for idx, line in enumerate(lines):
        line_lower = line.lower()
        for phrase in FORBIDDEN_PHRASES:
            if phrase in line_lower:
                if _is_allowed(lines, idx, phrase):
                    continue
                errors.append(f"{rel}:{idx + 1}: forbidden phrase '{phrase}'")
        for pattern, reason, key in OVERSTATED_CLAIM_PATTERNS:
            if pattern.search(line):
                if _is_allowed(lines, idx, key):
                    continue
                errors.append(f"{rel}:{idx + 1}: overstated claim ({reason})")
    return errors


def collect_language_files() -> list:
    """Collect all markdown files subject to FSI language rules.

    Includes docs/, site-docs/, solutions/ recursively, plus the named
    top-level docs. Skips site/ (built site output) and node_modules.
    """
    files: dict = {}
    for root in DOC_ROOTS:
        if not root.exists():
            continue
        for path in root.rglob("*.md"):
            parts = set(path.parts)
            if "node_modules" in parts:
                continue
            files[path.resolve()] = path
    for name in TOP_LEVEL_LANGUAGE_DOCS:
        path = ROOT / name
        if path.exists():
            files[path.resolve()] = path
    return [files[k] for k in sorted(files)]


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


def check_framework_version_file() -> list:
    """Verify FRAMEWORK-VERSION mirrors scripts/traceability.py:FRAMEWORK_REPO_REF."""
    fv = ROOT / "FRAMEWORK-VERSION"
    if not fv.exists():
        return ["FRAMEWORK-VERSION: file is missing at repository root"]
    text = fv.read_text(encoding="utf-8", errors="replace")
    m = re.search(r"^framework_ref:\s*([0-9a-fA-F]{7,40})\s*$", text, re.MULTILINE)
    if not m:
        return ["FRAMEWORK-VERSION: could not parse 'framework_ref:' line"]
    pinned = m.group(1)
    if pinned != FRAMEWORK_REPO_REF:
        return [
            f"FRAMEWORK-VERSION: framework_ref '{pinned}' does not match "
            f"scripts/traceability.py FRAMEWORK_REPO_REF '{FRAMEWORK_REPO_REF}'"
        ]
    return []


def check_deployment_guide_matrix() -> list:
    """Sanity-check DEPLOYMENT-GUIDE.md for required v1.0 sections."""
    dg = ROOT / "DEPLOYMENT-GUIDE.md"
    if not dg.exists():
        return ["DEPLOYMENT-GUIDE.md: file is missing"]
    text = dg.read_text(encoding="utf-8", errors="replace")
    errors = []
    if re.search(r"\bTODO\b", text):
        errors.append("DEPLOYMENT-GUIDE.md: contains TODO marker; promote outstanding items before release")
    return errors


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

    # Check language rules across all documentation roots and top-level docs.
    for md_file in collect_language_files():
        all_errors.extend(check_language(md_file))

    # Check README required sections
    for readme in SOLUTIONS_ROOT.glob("*/README.md"):
        all_errors.extend(check_readme_sections(readme))
        all_errors.extend(check_status_line(readme))

    for md_file in unique_md_files:
        all_errors.extend(check_framework_link_pinning(md_file))

    all_errors.extend(check_examination_readiness_table(EXAMINATION_READINESS))
    all_errors.extend(check_framework_version_file())
    all_errors.extend(check_deployment_guide_matrix())

    if all_errors:
        raise SystemExit(
            f"Documentation validation failed ({len(all_errors)} issues):\n"
            + "\n".join(f"  - {e}" for e in all_errors)
        )

    print(f"Documentation validation passed: {len(unique_md_files)} markdown files checked.")


if __name__ == "__main__":
    main()
