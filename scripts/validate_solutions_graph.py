"""Validate solutions-graph.json against the schema and business rules.

Checks:
* JSON Schema 2020-12 compliance.
* No duplicate solution IDs.
* Counts namespace matches the actual data (solutions, tier breakdown,
  framework_controls_referenced length).
* All controlCoverage entries appear in framework_controls_referenced.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
GRAPH = REPO / "solutions-graph.json"
SCHEMA = REPO / "scripts" / "solutions-graph.schema.json"


def main() -> int:
    if not GRAPH.is_file():
        print(f"ERROR: {GRAPH} not found. Run build_solutions_graph.py first.", file=sys.stderr)
        return 2
    if not SCHEMA.is_file():
        print(f"ERROR: schema not found at {SCHEMA}", file=sys.stderr)
        return 2

    graph = json.loads(GRAPH.read_text(encoding="utf-8"))
    schema = json.loads(SCHEMA.read_text(encoding="utf-8"))

    # JSON Schema validation (jsonschema is required in CI but we degrade
    # gracefully with structural checks if unavailable).
    try:
        import jsonschema

        jsonschema.validate(instance=graph, schema=schema)
    except ImportError:
        print("WARN: jsonschema not installed; skipping schema validation (structural checks only).")
    except Exception as e:
        print(f"ERROR: schema validation failed: {e}", file=sys.stderr)
        return 1

    errors: list[str] = []

    # Duplicate solution IDs
    sol_ids = [s["id"] for s in graph.get("solutions", [])]
    dups = sorted({sid for sid in sol_ids if sol_ids.count(sid) > 1})
    if dups:
        errors.append(f"Duplicate solution IDs: {dups}")

    # Counts integrity
    counts = graph.get("counts") or {}
    if counts.get("solutions") != len(sol_ids):
        errors.append(
            f"counts.solutions={counts.get('solutions')} != actual {len(sol_ids)}"
        )
    actual_t1 = sum(1 for s in graph["solutions"] if s.get("tier") == 1)
    actual_t2 = sum(1 for s in graph["solutions"] if s.get("tier") == 2)
    actual_t3 = sum(1 for s in graph["solutions"] if s.get("tier") == 3)
    if counts.get("tier1") != actual_t1:
        errors.append(f"counts.tier1={counts.get('tier1')} != actual {actual_t1}")
    if counts.get("tier2") != actual_t2:
        errors.append(f"counts.tier2={counts.get('tier2')} != actual {actual_t2}")
    if counts.get("tier3") != actual_t3:
        errors.append(f"counts.tier3={counts.get('tier3')} != actual {actual_t3}")

    fw_refs = graph.get("framework_controls_referenced") or []
    if counts.get("framework_controls_referenced") != len(fw_refs):
        errors.append(
            f"counts.framework_controls_referenced={counts.get('framework_controls_referenced')} "
            f"!= actual {len(fw_refs)}"
        )

    # All controlCoverage entries must appear in framework_controls_referenced
    fw_set = set(fw_refs)
    for sol in graph["solutions"]:
        for c in sol.get("controlCoverage", []):
            if c not in fw_set:
                errors.append(
                    f"solution {sol['id']} references control {c} not in framework_controls_referenced"
                )

    if errors:
        print("FAILED: solutions-graph validation found errors:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1

    print(
        f"Solutions graph OK -- solutions={counts.get('solutions')} "
        f"(tier1={counts.get('tier1')} tier2={counts.get('tier2')} tier3={counts.get('tier3')}) "
        f"framework_controls_referenced={counts.get('framework_controls_referenced')}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
