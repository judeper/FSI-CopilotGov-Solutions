#!/usr/bin/env python3
"""Validate that all shared contract files exist and are internally consistent."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

REQUIRED_FILES = [
    ROOT / "SOLUTION-README-TEMPLATE.md",
    ROOT / "DELIVERY-CHECKLIST-TEMPLATE.md",
    ROOT / "docs" / "reference" / "shared-modules-contract.md",
    ROOT / "data" / "controls-master.json",
    ROOT / "data" / "frameworks-master.json",
    ROOT / "data" / "control-coverage.json",
    ROOT / "data" / "solution-catalog.json",
    ROOT / "data" / "solution-to-playbooks.json",
    ROOT / "data" / "evidence-schema.json",
    ROOT / "scripts" / "solution-config.yml",
]


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> None:
    missing = [str(path.relative_to(ROOT)) for path in REQUIRED_FILES if not path.exists()]
    if missing:
        raise SystemExit("Missing contract files:\n" + "\n".join(missing))

    controls = load_json(ROOT / "data" / "controls-master.json")
    coverage = load_json(ROOT / "data" / "control-coverage.json")
    catalog = load_json(ROOT / "data" / "solution-catalog.json")
    playbooks = load_json(ROOT / "data" / "solution-to-playbooks.json")
    frameworks = load_json(ROOT / "data" / "frameworks-master.json")
    config = load_json(ROOT / "scripts" / "solution-config.yml")

    if len(controls) != 54:
        raise SystemExit(f"Expected 54 controls, found {len(controls)}")

    coverage_ids = {item["control_id"] for item in coverage}
    control_ids = {item["control_id"] for item in controls}
    if coverage_ids != control_ids:
        missing_in_coverage = control_ids - coverage_ids
        extra_in_coverage = coverage_ids - control_ids
        msg = "Control coverage does not match controls-master."
        if missing_in_coverage:
            msg += f"\n  Missing from coverage: {sorted(missing_in_coverage)}"
        if extra_in_coverage:
            msg += f"\n  Extra in coverage: {sorted(extra_in_coverage)}"
        raise SystemExit(msg)

    solution_slugs = {item["slug"] for item in catalog}
    config_slugs = set(config["solutions"].keys())
    playbook_slugs = {item["solution"] for item in playbooks}

    if solution_slugs != config_slugs:
        raise SystemExit(
            f"solution-catalog.json slugs do not match solution-config.yml slugs.\n"
            f"  Catalog only: {sorted(solution_slugs - config_slugs)}\n"
            f"  Config only:  {sorted(config_slugs - solution_slugs)}"
        )
    if solution_slugs != playbook_slugs:
        raise SystemExit(
            f"solution-to-playbooks.json slugs do not match solution-catalog.json slugs.\n"
            f"  Catalog only:  {sorted(solution_slugs - playbook_slugs)}\n"
            f"  Playbooks only: {sorted(playbook_slugs - solution_slugs)}"
        )

    for item in coverage:
        for slug in item.get("solutions", []):
            if slug not in solution_slugs:
                raise SystemExit(f"Unknown solution slug in coverage map: {slug}")

    if not frameworks:
        raise SystemExit("Framework registry is empty")

    print("Contract validation passed.")


if __name__ == "__main__":
    main()
