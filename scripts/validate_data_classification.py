#!/usr/bin/env python3
"""Validate data/data-classification.json against its schema and the solution catalog.

Checks:
  * The matrix conforms to data/data-classification.schema.json (Draft 2020-12).
  * Every solution slug in data/solution-catalog.json appears exactly once in the matrix.
  * No extra slugs appear in the matrix.
  * retention_default_days <= retention_max_days for every entry.
"""

from __future__ import annotations

import json
from pathlib import Path

from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parent.parent
MATRIX_PATH = ROOT / "data" / "data-classification.json"
SCHEMA_PATH = ROOT / "data" / "data-classification.schema.json"
CATALOG_PATH = ROOT / "data" / "solution-catalog.json"


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def validate_matrix() -> list[str]:
    errors: list[str] = []

    schema = load_json(SCHEMA_PATH)
    matrix = load_json(MATRIX_PATH)
    catalog = load_json(CATALOG_PATH)

    validator = Draft202012Validator(schema)
    for err in sorted(validator.iter_errors(matrix), key=lambda e: list(e.absolute_path)):
        path = "/".join(str(p) for p in err.absolute_path) or "<root>"
        errors.append(f"schema: {path}: {err.message}")

    catalog_slugs = {entry["slug"] for entry in catalog}
    matrix_slugs: list[str] = []
    seen: set[str] = set()
    for entry in matrix:
        slug = entry.get("slug")
        if not isinstance(slug, str):
            continue
        if slug in seen:
            errors.append(f"duplicate slug in matrix: {slug}")
        seen.add(slug)
        matrix_slugs.append(slug)

    missing = sorted(catalog_slugs - seen)
    extra = sorted(seen - catalog_slugs)
    if missing:
        errors.append(f"matrix is missing slugs from solution-catalog.json: {missing}")
    if extra:
        errors.append(f"matrix contains slugs not in solution-catalog.json: {extra}")

    for entry in matrix:
        slug = entry.get("slug", "<unknown>")
        default_days = entry.get("retention_default_days")
        max_days = entry.get("retention_max_days")
        if isinstance(default_days, int) and isinstance(max_days, int):
            if default_days > max_days:
                errors.append(
                    f"{slug}: retention_default_days ({default_days}) "
                    f"exceeds retention_max_days ({max_days})"
                )

    return errors


def main() -> None:
    errors = validate_matrix()
    if errors:
        raise SystemExit(
            "Data classification validation failed:\n"
            + "\n".join(f"  - {error}" for error in errors)
        )
    print("Data classification matrix validation passed.")


if __name__ == "__main__":
    main()
