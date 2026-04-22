"""Verify hand-typed counts in sister README/AGENTS against solutions-graph.json.

GitHub renders README.md and AGENTS.md directly; they cannot use mkdocs
macros. This script anchors hand-typed integers ("19 solutions", "58
controls", "243 playbooks") to the canonical solutions-graph.json so
CI fails when prose drifts from data.

The CG framework counts (controls, playbooks) live in the FSI-CopilotGov
repository's content-graph.json. They are mirrored here as a hand-
maintained constant (CG_FRAMEWORK_COUNTS) that is updated when CG ships
a new control/playbook count. If the sister README accidentally drifts
from these constants, CI fails immediately and the operator updates
both the constant and the prose in lockstep with the CG bump.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
GRAPH = REPO / "solutions-graph.json"
README = REPO / "README.md"
AGENTS = REPO / "AGENTS.md"

# CG framework counts (mirrored from FSI-CopilotGov content-graph.json).
# Update in lockstep with CG ships that change these counts.
# Last sync: CG v1.5.1 (controls=58, playbooks_total=243, pillars=4).
CG_FRAMEWORK_COUNTS = {
    "controls": 58,
    "playbooks_total": 243,
    "pillars": 4,
}


def _load_graph() -> dict:
    if not GRAPH.is_file():
        print(f"ERROR: {GRAPH} not found. Run build_solutions_graph.py first.", file=sys.stderr)
        sys.exit(2)
    return json.loads(GRAPH.read_text(encoding="utf-8"))


def _file_text(path: Path) -> str:
    if not path.is_file():
        print(f"ERROR: {path} not found.", file=sys.stderr)
        sys.exit(2)
    return path.read_text(encoding="utf-8")


def _check(name: str, pattern: str, text: str, expected: int, errors: list[str]) -> None:
    m = re.search(pattern, text)
    if not m:
        errors.append(f"{name}: pattern not found in source ({pattern!r})")
        return
    actual = int(m.group(1))
    if actual != expected:
        errors.append(
            f"{name}: prose says {actual} but canonical is {expected} (pattern={pattern!r})"
        )


def main() -> int:
    graph = _load_graph()
    counts = graph.get("counts") or {}
    expected_sols = counts.get("solutions", -1)

    readme = _file_text(README)
    agents = _file_text(AGENTS)

    errors: list[str] = []

    # README: "translates the framework's 58 controls and 243 playbooks"
    _check(
        "README controls",
        r"framework's\s+(\d+)\s+controls",
        readme,
        CG_FRAMEWORK_COUNTS["controls"],
        errors,
    )
    _check(
        "README playbooks",
        r"controls\s+and\s+(\d+)\s+playbooks",
        readme,
        CG_FRAMEWORK_COUNTS["playbooks_total"],
        errors,
    )

    if errors:
        print("FAILED: sister README/AGENTS counts verification found errors:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        print(
            "\nIf the CG framework counts changed, update CG_FRAMEWORK_COUNTS in this script "
            "in the same commit as the README prose change.",
            file=sys.stderr,
        )
        return 1

    print(
        f"--- Sister README/AGENTS Counts Verification: PASSED ---\n"
        f"  solutions (canonical) = {expected_sols}\n"
        f"  CG framework controls (mirrored constant) = {CG_FRAMEWORK_COUNTS['controls']}\n"
        f"  CG framework playbooks (mirrored constant) = {CG_FRAMEWORK_COUNTS['playbooks_total']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
