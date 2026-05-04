"""Validate solutions.json against the v0.1.0 canonical schema.

Checks:
- schemaVersion, generatedAt, solutions present
- Every solution has required fields
- Every version is bare semver (no leading 'v')
- Every repoPath exists as a directory
Exits non-zero on any failure.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SOLUTIONS_JSON = REPO / "solutions.json"

SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+(?:-[\w.]+)?$")
REQUIRED_FIELDS = (
    "id",
    "slug",
    "tier",
    "name",
    "version",
    "domain",
    "summary",
    "repoPath",
    "url",
    "prerequisites",
    "verification",
    "tiersSupported",
    "tierRecommended",
    "tierMaturity",
    "maturity",
)

ALLOWED_TIERS = ("baseline", "recommended", "regulated")
ALLOWED_TIER_MATURITY = ("active", "preview", "deprecated")
ALLOWED_MATURITY = ("documentation-first-scaffold", "preview", "live")


def main() -> int:
    if not SOLUTIONS_JSON.exists():
        print(f"ERROR: {SOLUTIONS_JSON} not found", file=sys.stderr)
        return 1

    try:
        doc = json.loads(SOLUTIONS_JSON.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"ERROR: invalid JSON: {e}", file=sys.stderr)
        return 1

    errors: list[str] = []

    if doc.get("schemaVersion") != "0.2.0":
        errors.append(f"schemaVersion must be '0.2.0', got {doc.get('schemaVersion')!r}")
    if not doc.get("generatedAt"):
        errors.append("generatedAt missing")

    solutions = doc.get("solutions")
    if not isinstance(solutions, list) or not solutions:
        errors.append("solutions must be a non-empty array")
        solutions = []

    seen_ids: set[str] = set()
    for i, s in enumerate(solutions):
        prefix = f"solutions[{i}]"
        if not isinstance(s, dict):
            errors.append(f"{prefix}: not an object")
            continue
        for field in REQUIRED_FIELDS:
            if field not in s:
                errors.append(f"{prefix}: missing required field '{field}'")
        sid = s.get("id")
        if sid in seen_ids:
            errors.append(f"{prefix}: duplicate id {sid!r}")
        if sid:
            seen_ids.add(sid)
        tier = s.get("tier")
        if tier not in (1, 2, 3):
            errors.append(f"{prefix} ({sid}): tier must be 1|2|3, got {tier!r}")
        version = s.get("version")
        if not isinstance(version, str) or not SEMVER_RE.match(version):
            errors.append(f"{prefix} ({sid}): version {version!r} is not bare semver")
        repo_path = s.get("repoPath")
        if repo_path:
            p = REPO / repo_path
            if not p.is_dir():
                errors.append(f"{prefix} ({sid}): repoPath {repo_path!r} is not a directory")
        for list_field in ("prerequisites", "verification"):
            v = s.get(list_field)
            if not isinstance(v, list):
                errors.append(f"{prefix} ({sid}): {list_field} must be an array")

        ts = s.get("tiersSupported")
        if not isinstance(ts, list) or not ts:
            errors.append(f"{prefix} ({sid}): tiersSupported must be a non-empty array")
        else:
            for t in ts:
                if t not in ALLOWED_TIERS:
                    errors.append(f"{prefix} ({sid}): tiersSupported contains invalid value {t!r}")
        tr = s.get("tierRecommended")
        if tr not in ALLOWED_TIERS:
            errors.append(f"{prefix} ({sid}): tierRecommended must be one of {ALLOWED_TIERS}, got {tr!r}")
        tm = s.get("tierMaturity")
        if tm not in ALLOWED_TIER_MATURITY:
            errors.append(f"{prefix} ({sid}): tierMaturity must be one of {ALLOWED_TIER_MATURITY}, got {tm!r}")
        mat = s.get("maturity")
        if mat not in ALLOWED_MATURITY:
            errors.append(f"{prefix} ({sid}): maturity must be one of {ALLOWED_MATURITY}, got {mat!r}")

    if errors:
        print(f"FAIL: {len(errors)} validation error(s):", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1

    print(f"OK: {len(solutions)} solutions validated")
    return 0


if __name__ == "__main__":
    sys.exit(main())
