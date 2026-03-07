#!/usr/bin/env python3
"""Validate that every solution folder meets the required structure contract."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOLUTIONS_ROOT = ROOT / "solutions"

REQUIRED_FILES = [
    "README.md",
    "CHANGELOG.md",
    "DELIVERY-CHECKLIST.md",
    "docs/architecture.md",
    "docs/deployment-guide.md",
    "docs/evidence-export.md",
    "docs/prerequisites.md",
    "docs/troubleshooting.md",
    "config/default-config.json",
    "config/baseline.json",
    "config/recommended.json",
    "config/regulated.json",
]

REQUIRED_SCRIPTS = [
    "scripts/Deploy-Solution.ps1",
    "scripts/Monitor-Compliance.ps1",
    "scripts/Export-Evidence.ps1",
]


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def get_evidence_outputs(config: dict) -> list:
    if isinstance(config.get("evidenceOutputs"), list):
        return config["evidenceOutputs"]

    defaults = config.get("defaults")
    if isinstance(defaults, dict) and isinstance(defaults.get("evidenceOutputs"), list):
        return defaults["evidenceOutputs"]

    return []


def validate_solution(slug: str) -> list:
    errors = []
    sol_dir = SOLUTIONS_ROOT / slug

    if not sol_dir.is_dir():
        return [f"{slug}: directory not found"]

    for rel in REQUIRED_FILES:
        if not (sol_dir / rel).exists():
            errors.append(f"{slug}: missing {rel}")

    for rel in REQUIRED_SCRIPTS:
        if not (sol_dir / rel).exists():
            errors.append(f"{slug}: missing {rel}")

    # Validate tests file exists (name varies by slug)
    test_files = list((sol_dir / "tests").glob("*.Tests.ps1")) if (sol_dir / "tests").exists() else []
    if not test_files:
        errors.append(f"{slug}: missing tests/*.Tests.ps1")

    # Validate JSON configs are parseable
    for cfg in ["config/default-config.json", "config/baseline.json",
                "config/recommended.json", "config/regulated.json"]:
        cfg_path = sol_dir / cfg
        if cfg_path.exists():
            try:
                load_json(cfg_path)
            except json.JSONDecodeError as exc:
                errors.append(f"{slug}: invalid JSON in {cfg}: {exc}")

    default_config_path = sol_dir / "config" / "default-config.json"
    if default_config_path.exists():
        default_config = load_json(default_config_path)
        evidence_outputs = get_evidence_outputs(default_config)
        if not evidence_outputs:
            errors.append(f"{slug}: config/default-config.json must declare evidenceOutputs")
        elif any(not isinstance(item, str) or not item.strip() for item in evidence_outputs):
            errors.append(f"{slug}: evidenceOutputs must contain non-empty strings only")
        elif len(set(evidence_outputs)) != len(evidence_outputs):
            errors.append(f"{slug}: evidenceOutputs contains duplicate entries")

    return errors


def main() -> None:
    config_path = ROOT / "scripts" / "solution-config.yml"
    config = load_json(config_path)
    slugs = list(config["solutions"].keys())

    all_errors = []
    for slug in slugs:
        all_errors.extend(validate_solution(slug))

    if all_errors:
        raise SystemExit(
            f"Solution validation failed ({len(all_errors)} errors):\n"
            + "\n".join(f"  - {e}" for e in all_errors)
        )

    print(f"Solution validation passed: {len(slugs)} solutions validated.")


if __name__ == "__main__":
    main()
