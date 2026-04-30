"""Build canonical solutions.json from the solution catalog and per-solution configs.

Source of truth precedence for version: config/default-config.json -> README -> catalog.
All versions are normalized to bare semver (no leading 'v').
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
CATALOG = REPO / "data" / "solution-catalog.json"
OUT = REPO / "solutions.json"

VERSION_RE = re.compile(r"^v?(\d+\.\d+\.\d+(?:-[\w.]+)?)$")
README_VERSION_RE = re.compile(r"(?i)version[:\s\*]+v?(\d+\.\d+\.\d+(?:-[\w.]+)?)")

TIER_FROM_PHASE = {1: 1, 2: 2, 3: 3}


def normalize_version(v: str | None) -> str | None:
    if not v:
        return None
    v = v.strip()
    m = VERSION_RE.match(v)
    return m.group(1) if m else None


def read_config_version(slug: str) -> str | None:
    cfg = REPO / "solutions" / slug / "config" / "default-config.json"
    if not cfg.exists():
        return None
    try:
        data = json.loads(cfg.read_text(encoding="utf-8"))
    except Exception:
        return None
    return normalize_version(data.get("version"))


def read_readme_version(slug: str) -> str | None:
    readme = REPO / "solutions" / slug / "README.md"
    if not readme.exists():
        return None
    content = readme.read_text(encoding="utf-8", errors="replace")
    m = README_VERSION_RE.search(content)
    return normalize_version(m.group(1)) if m else None


def main() -> None:
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    solutions = []
    for s in catalog:
        slug = s["slug"]
        cfg_v = read_config_version(slug)
        readme_v = read_readme_version(slug)
        cat_v = normalize_version(s.get("version"))
        version = cfg_v or readme_v or cat_v
        tier = TIER_FROM_PHASE.get(int(s.get("phase", 2)), 2)
        solutions.append({
            "id": slug,
            "slug": slug,
            "tier": tier,
            "name": s.get("display_name", slug),
            "version": version,
            "domain": s.get("domain", ""),
            "summary": s.get("summary", ""),
            "repoPath": f"solutions/{slug}",
            "url": f"https://github.com/judeper/FSI-CopilotGov-Solutions/tree/main/solutions/{slug}",
            "prerequisites": [],
            "verification": s.get("evidence_outputs", []) or [],
            "tiersSupported": s.get("tiers_supported", []),
            "tierRecommended": s.get("tier_recommended"),
            "tierMaturity": s.get("tier_maturity"),
            "maturity": s.get("maturity"),
        })

    doc = {
        "schemaVersion": "0.2.0",
        "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "solutions": solutions,
    }
    OUT.write_text(json.dumps(doc, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT} with {len(solutions)} solutions")


if __name__ == "__main__":
    main()
