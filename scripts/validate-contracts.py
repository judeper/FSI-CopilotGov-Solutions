#!/usr/bin/env python3
"""Validate that all shared contract files exist and are internally consistent."""

import json
from pathlib import Path

from traceability import FRAMEWORK_ID_RE, normalize_traceability_token

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
    ROOT / "scripts" / "traceability.py",
]


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def iter_framework_names(item: dict) -> list[str]:
    return [item["id"], item["display_name"], item["title"], *item.get("aliases", [])]


def build_framework_index(frameworks: list[dict]) -> tuple[dict[str, dict], dict[str, str]]:
    framework_by_id = {}
    alias_to_id = {}
    errors = []
    for item in frameworks:
        missing = [
            field
            for field in ("id", "display_name", "title", "controls", "solutions")
            if field not in item
        ]
        if missing:
            errors.append(
                f"Framework entry {item.get('id', '<missing id>')} is missing fields: {missing}"
            )
            continue
        framework_id = item["id"]
        if not FRAMEWORK_ID_RE.fullmatch(framework_id):
            errors.append(f"Framework id is not canonical kebab-case: {framework_id}")
        if framework_id in framework_by_id:
            errors.append(f"Duplicate framework id: {framework_id}")
            continue
        framework_by_id[framework_id] = item
        for name in iter_framework_names(item):
            key = normalize_traceability_token(name)
            existing = alias_to_id.get(key)
            if existing and existing != framework_id:
                errors.append(
                    f"Framework alias '{name}' is ambiguous between {existing} and {framework_id}"
                )
                continue
            alias_to_id[key] = framework_id
    if errors:
        raise SystemExit(
            "Framework registry validation failed:\n"
            + "\n".join(f"  - {error}" for error in errors)
        )
    return framework_by_id, alias_to_id


def resolve_framework_ids(values: list[str], alias_to_id: dict[str, str], source: str) -> list[str]:
    resolved = []
    seen = set()
    for value in values:
        framework_id = alias_to_id.get(normalize_traceability_token(value))
        if not framework_id:
            raise SystemExit(f"{source}: unknown framework reference '{value}'")
        if framework_id not in seen:
            resolved.append(framework_id)
            seen.add(framework_id)
    return resolved


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
    default_configs = {
        slug: load_json(ROOT / "solutions" / slug / "config" / "default-config.json")
        for slug in config["solutions"].keys()
    }

    if len(controls) != 57:
        raise SystemExit(f"Expected 57 controls, found {len(controls)}")

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
    framework_by_id, framework_alias_to_id = build_framework_index(frameworks)

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
        for framework_id in item.get("framework_ids", []):
            if framework_id not in framework_by_id:
                raise SystemExit(
                    f"Unknown framework id in control coverage for {item['control_id']}: {framework_id}"
                )

    if not frameworks:
        raise SystemExit("Framework registry is empty")

    expected_frameworks_by_control = {control_id: [] for control_id in control_ids}
    expected_frameworks_by_solution = {slug: [] for slug in solution_slugs}
    for item in frameworks:
        if item.get("solutions") and not item.get("controls"):
            raise SystemExit(
                f"Framework {item['id']} maps to solutions but has no control mappings"
            )
        for control_id in item.get("controls", []):
            if control_id not in control_ids:
                raise SystemExit(
                    f"Unknown control id in framework {item['id']}: {control_id}"
                )
            expected_frameworks_by_control[control_id].append(item["id"])
        for slug in item.get("solutions", []):
            if slug not in solution_slugs:
                raise SystemExit(
                    f"Unknown solution slug in framework {item['id']}: {slug}"
                )
            expected_frameworks_by_solution[slug].append(item["id"])

    catalog_by_slug = {item["slug"]: item for item in catalog}
    for slug, item in catalog_by_slug.items():
        framework_ids = item.get("framework_ids")
        if not framework_ids:
            raise SystemExit(f"solution-catalog.json is missing framework_ids for {slug}")
        if framework_ids != expected_frameworks_by_solution[slug]:
            raise SystemExit(
                f"solution-catalog.json framework_ids do not match frameworks-master for {slug}.\n"
                f"  Catalog:   {framework_ids}\n"
                f"  Expected:  {expected_frameworks_by_solution[slug]}"
            )
        for framework_id in framework_ids:
            if framework_id not in framework_by_id:
                raise SystemExit(f"Unknown framework id in solution-catalog.json: {framework_id}")
        resolved = resolve_framework_ids(
            item.get("regulations", []),
            framework_alias_to_id,
            f"solution-catalog.json:{slug}",
        )
        if not set(resolved).issubset(set(framework_ids)):
            raise SystemExit(
                f"solution-catalog.json regulations are not a subset of framework_ids for {slug}.\n"
                f"  Regulations:   {resolved}\n"
                f"  Framework IDs: {framework_ids}"
            )

    playbooks_by_solution = {item["solution"]: item for item in playbooks}
    for slug, item in playbooks_by_solution.items():
        if item.get("framework_ids") != expected_frameworks_by_solution[slug]:
            raise SystemExit(
                f"solution-to-playbooks.json framework_ids do not match frameworks-master for {slug}.\n"
                f"  Playbooks: {item.get('framework_ids')}\n"
                f"  Expected:  {expected_frameworks_by_solution[slug]}"
            )

    for item in coverage:
        expected = expected_frameworks_by_control[item["control_id"]]
        if item.get("framework_ids", []) != expected:
            raise SystemExit(
                f"control-coverage.json framework_ids do not match frameworks-master for {item['control_id']}.\n"
                f"  Coverage: {item.get('framework_ids', [])}\n"
                f"  Expected: {expected}"
            )

    for slug, item in default_configs.items():
        if item.get("framework_ids") != expected_frameworks_by_solution[slug]:
            raise SystemExit(
                f"default-config.json framework_ids do not match frameworks-master for {slug}.\n"
                f"  Config:   {item.get('framework_ids')}\n"
                f"  Expected: {expected_frameworks_by_solution[slug]}"
            )
        if "regulations" in item:
            resolved = resolve_framework_ids(
                item["regulations"],
                framework_alias_to_id,
                f"solutions/{slug}/config/default-config.json",
            )
            if not set(resolved).issubset(set(item["framework_ids"])):
                raise SystemExit(
                    f"default-config.json regulations are not a subset of framework_ids for {slug}.\n"
                    f"  Regulations:   {resolved}\n"
                    f"  Framework IDs: {item['framework_ids']}"
                )

    print("Contract validation passed.")


if __name__ == "__main__":
    main()
