"""Build the canonical solutions graph for FSI-CopilotGov-Solutions.

Walks the solutions catalog and emits ``solutions-graph.json`` as a
single source of truth for downstream tooling (drift verification,
README count gates, future cross-repo coupling with FSI-CopilotGov).

Stdlib only -- no external dependencies.

Output schema (version 1.0.0):

    {
      "schemaVersion": "1.0.0",
      "generatedAt": "<ISO UTC>",
      "counts": {
        "solutions": <int>,
        "tier1": <int>,
        "tier2": <int>,
        "tier3": <int>,
        "framework_controls_referenced": <int>,
        "doc_files_total": <int>
      },
      "solutions": [
        {
          "id": "01-copilot-readiness-scanner",
          "name": "...",
          "tier": 1,
          "version": "0.2.0",
          "domain": "readiness-data",
          "controlCoverage": ["1.1", "1.2"],
          "docFileCount": <int>
        },
        ...
      ],
      "framework_controls_referenced": ["1.1", "1.2", ...]
    }
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SOLUTIONS_DIR = REPO / "solutions"
SOLUTIONS_JSON = REPO / "solutions.json"
CATALOG = REPO / "data" / "solution-catalog.json"
OUTPUT = REPO / "solutions-graph.json"

SCHEMA_VERSION = "1.1.0"


def _rel(path: Path) -> str:
    return path.relative_to(REPO).as_posix()


def _doc_file_count(solution_dir: Path) -> int:
    if not solution_dir.is_dir():
        return 0
    return sum(1 for _ in solution_dir.rglob("*.md"))


def _control_coverage(sol: dict) -> list[str]:
    cov = sol.get("controlCoverage") or sol.get("control_coverage") or []
    return [c for c in cov if isinstance(c, str)]


def _load_catalog_coverage() -> dict[str, list[str]]:
    """Map slug -> sorted unique union of primary_controls + supporting_controls."""
    if not CATALOG.is_file():
        return {}
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    out: dict[str, list[str]] = {}
    for entry in catalog:
        slug = entry.get("slug")
        if not slug:
            continue
        controls: set[str] = set()
        for key in ("primary_controls", "supporting_controls"):
            for c in entry.get(key) or []:
                if isinstance(c, str) and c.strip():
                    controls.add(c.strip())
        out[slug] = sorted(controls, key=_natural_control_key)
    return out


def build_graph() -> dict:
    if not SOLUTIONS_JSON.is_file():
        raise SystemExit(
            f"ERROR: {SOLUTIONS_JSON} not found. Run scripts/build_solutions_json.py first."
        )

    src = json.loads(SOLUTIONS_JSON.read_text(encoding="utf-8"))
    src_solutions = src.get("solutions") or []
    catalog_coverage = _load_catalog_coverage()

    enriched: list[dict] = []
    framework_refs: set[str] = set()
    tier_counts = {1: 0, 2: 0, 3: 0}
    total_doc_files = 0

    for sol in src_solutions:
        sid = sol.get("id", "")
        slug = sol.get("slug") or sid
        sol_dir = SOLUTIONS_DIR / slug
        doc_count = _doc_file_count(sol_dir)
        total_doc_files += doc_count
        tier = sol.get("tier")
        if isinstance(tier, int) and tier in tier_counts:
            tier_counts[tier] += 1
        coverage = catalog_coverage.get(slug) or _control_coverage(sol)
        framework_refs.update(coverage)
        enriched.append(
            {
                "id": sid,
                "name": sol.get("name", ""),
                "tier": tier,
                "version": sol.get("version", ""),
                "domain": sol.get("domain", ""),
                "controlCoverage": sorted(coverage),
                "docFileCount": doc_count,
                "tiersSupported": sol.get("tiersSupported", []),
                "tierRecommended": sol.get("tierRecommended"),
                "tierMaturity": sol.get("tierMaturity"),
                "maturity": sol.get("maturity"),
            }
        )

    enriched.sort(key=lambda s: s["id"])
    framework_list = sorted(framework_refs, key=_natural_control_key)

    return {
        "schemaVersion": SCHEMA_VERSION,
        "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "counts": {
            "solutions": len(enriched),
            "tier1": tier_counts[1],
            "tier2": tier_counts[2],
            "tier3": tier_counts[3],
            "framework_controls_referenced": len(framework_list),
            "doc_files_total": total_doc_files,
        },
        "solutions": enriched,
        "framework_controls_referenced": framework_list,
    }


def _natural_control_key(cid: str):
    parts = cid.split(".")
    out = []
    for p in parts:
        # Allow trailing letter (e.g., 3.8a) for forward compatibility.
        digits = "".join(ch for ch in p if ch.isdigit())
        suffix = "".join(ch for ch in p if not ch.isdigit())
        out.append((int(digits) if digits else 0, suffix))
    return tuple(out)


def main() -> int:
    graph = build_graph()
    OUTPUT.write_text(
        json.dumps(graph, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    counts = graph["counts"]
    print(f"Wrote {_rel(OUTPUT)}")
    print(
        "  solutions={solutions} (tier1={tier1} tier2={tier2} tier3={tier3}) "
        "framework_controls_referenced={framework_controls_referenced} "
        "doc_files_total={doc_files_total}".format(**counts)
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
