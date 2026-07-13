#!/usr/bin/env python3
"""Validate FSI lab-validation contracts."""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

try:
    from jsonschema import Draft202012Validator, FormatChecker
except ImportError as exc:  # pragma: no cover - exercised in CLI environments only
    print(
        "ERROR: jsonschema format validation is required. Install dependencies with "
        "'pip install -r requirements-docs.txt'.",
        file=sys.stderr,
    )
    raise SystemExit(2) from exc

ROOT = Path(__file__).resolve().parent.parent
SCHEMA_PATH = ROOT / "data" / "lab-validation-contract.schema.json"
CONTROLS_PATH = ROOT / "data" / "controls-master.json"
SOLUTION_CONFIG_PATH = ROOT / "scripts" / "solution-config.yml"

CONTRACT_ID_RE = re.compile(
    r"^lab-contract:(?P<solution>[a-z0-9][a-z0-9-]*):(?P<revision>[a-z0-9][a-z0-9.-]*)$"
)

ALLOWED_SOURCE_HOSTS = {
    "learn.microsoft.com",
    "support.microsoft.com",
    "admin.microsoft.com",
    "roadmap.cloud.microsoft",
    "azure.microsoft.com",
    "techcommunity.microsoft.com",
    "aka.ms",
}
ALLOWED_GA_SOURCE_TYPES = {"learn-doc", "graph-reference", "service-description"}
EXPECTED_DISPOSITIONS = {"PASS", "PARTIAL", "BLOCKED", "NOT-APPLICABLE", "FAIL"}
REQUIRED_PHASES = {"setup", "exercise", "verify", "cleanup"}
PROHIBITED_KEY_PATTERN = re.compile(
    r"(password|secret|token|apikey|api[_-]?key|connectionstring|tenantid|tenant[_-]?id)",
    re.IGNORECASE,
)
PROHIBITED_VALUE_PATTERNS = (
    (re.compile(r"(?i)\b[a-z0-9-]+\.onmicrosoft\.com\b"), "tenant domain"),
    (re.compile(r"(?i)\b[a-z0-9-]+\.microsoftonline\.(com|us)\b"), "tenant endpoint"),
    (re.compile(r"(?i)-----BEGIN [A-Z ]*PRIVATE KEY-----"), "private key material"),
    (re.compile(r"(?i)\b(client[_-]?secret|access[_-]?token|refresh[_-]?token)\b"), "secret token marker"),
)
GUID_RE = re.compile(
    r"\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b"
)


def rel(path: Path) -> Path:
    try:
        return path.relative_to(ROOT)
    except ValueError:
        return path


def err(path: Path, message: str) -> str:
    return f"{rel(path)}: {message}"


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def discover_contract_paths(raw_paths: list[str]) -> tuple[list[Path], bool]:
    explicit = bool(raw_paths)
    discovered: list[Path] = []

    if explicit:
        for raw_path in raw_paths:
            candidate = Path(raw_path).expanduser()
            if not candidate.is_absolute():
                candidate = (Path.cwd() / candidate).resolve()
            else:
                candidate = candidate.resolve()

            if candidate.is_dir():
                discovered.extend(sorted(candidate.rglob("*.lab.json")))
                continue
            if candidate.is_file():
                discovered.append(candidate)
                continue
            discovered.append(candidate)
    else:
        discovered.extend(sorted((ROOT / "solutions").glob("*/lab/*.lab.json")))

    unique: list[Path] = []
    seen: set[Path] = set()
    for path in discovered:
        if path in seen:
            continue
        seen.add(path)
        unique.append(path)
    return unique, explicit


def infer_solution_from_path(path: Path) -> str | None:
    if path.parent.name == "lab":
        return path.parent.parent.name
    return None


def parse_date(value: str, path: Path, field_name: str, errors: list[str]) -> date | None:
    try:
        return date.fromisoformat(value)
    except ValueError:
        errors.append(err(path, f"{field_name} must be an ISO-8601 date, got {value!r}"))
        return None


def collect_sensitive_strings(node: Any, path: Path, errors: list[str], pointer: str = "<root>") -> None:
    if isinstance(node, dict):
        for key, value in node.items():
            child_pointer = f"{pointer}.{key}" if pointer != "<root>" else key
            if PROHIBITED_KEY_PATTERN.search(str(key)):
                errors.append(err(path, f"prohibited key in contract content: {child_pointer}"))
            if re.search(r"tenant", str(key), flags=re.IGNORECASE) and isinstance(value, str) and GUID_RE.search(value):
                errors.append(err(path, f"tenant identifier is not allowed at {child_pointer}"))
            collect_sensitive_strings(value, path, errors, child_pointer)
        return

    if isinstance(node, list):
        for index, item in enumerate(node):
            collect_sensitive_strings(item, path, errors, f"{pointer}[{index}]")
        return

    if isinstance(node, str):
        for pattern, label in PROHIBITED_VALUE_PATTERNS:
            if pattern.search(node):
                errors.append(err(path, f"prohibited {label} value at {pointer}"))
                break


def validate_path_and_identity(
    data: dict[str, Any],
    path: Path,
    known_solution_ids: set[str],
    errors: list[str],
) -> str | None:
    if not path.name.endswith(".lab.json"):
        errors.append(err(path, "contract filename must end with '.lab.json'"))

    expected_solution = infer_solution_from_path(path)
    file_solution = path.name[: -len(".lab.json")] if path.name.endswith(".lab.json") else path.stem
    solution_id = str(data.get("solution", {}).get("id", ""))

    if expected_solution and file_solution != expected_solution:
        errors.append(
            err(
                path,
                f"filename '{file_solution}' must match its parent solution folder '{expected_solution}'",
            )
        )

    if expected_solution and solution_id and solution_id != expected_solution:
        errors.append(
            err(path, f"solution.id '{solution_id}' does not match folder '{expected_solution}'")
        )

    if solution_id and solution_id not in known_solution_ids:
        errors.append(err(path, f"solution.id '{solution_id}' is not present in scripts/solution-config.yml"))

    contract_id = str(data.get("contractId", ""))
    match = CONTRACT_ID_RE.fullmatch(contract_id)
    if not match:
        errors.append(err(path, f"contractId '{contract_id}' does not follow 'lab-contract:<solution>:<revision>'"))
    elif solution_id and match.group("solution") != solution_id:
        errors.append(
            err(
                path,
                f"contractId solution '{match.group('solution')}' does not match solution.id '{solution_id}'",
            )
        )
    return solution_id or None


def validate_controls(
    data: dict[str, Any],
    path: Path,
    valid_controls: set[str],
    solution_controls: dict[str, set[str]],
    solution_id: str | None,
    errors: list[str],
) -> None:
    contract_controls = [str(control_id) for control_id in data.get("controls", [])]
    unknown = sorted({control_id for control_id in contract_controls if control_id not in valid_controls})
    if unknown:
        errors.append(err(path, f"unknown control IDs: {unknown}"))

    if solution_id and solution_id in solution_controls:
        unsupported = sorted(
            {
                control_id
                for control_id in contract_controls
                if control_id not in solution_controls[solution_id]
            }
        )
        if unsupported:
            errors.append(
                err(
                    path,
                    f"controls not mapped to solution {solution_id} in scripts/solution-config.yml: {unsupported}",
                )
            )


def validate_scope(data: dict[str, Any], path: Path, errors: list[str]) -> None:
    scope = data.get("scope", {})
    if scope.get("cloud") != "m365-us-commercial":
        errors.append(err(path, "scope.cloud must be 'm365-us-commercial'"))
    if scope.get("usCommercialOnly") is not True:
        errors.append(err(path, "scope.usCommercialOnly must be true"))

    prohibited = set(scope.get("prohibitedClouds", []))
    required = {"gcc", "gcc-high", "dod", "sovereign"}
    if not required.issubset(prohibited):
        missing = sorted(required - prohibited)
        errors.append(err(path, f"scope.prohibitedClouds is missing required entries: {missing}"))


def validate_sources(data: dict[str, Any], path: Path, reviewed_on: date | None, errors: list[str]) -> None:
    claims = data.get("microsoftSourceClaims", [])
    claim_ids: set[str] = set()

    for index, claim in enumerate(claims):
        claim_id = str(claim.get("id", ""))
        pointer = f"microsoftSourceClaims[{index}]"
        if claim_id in claim_ids:
            errors.append(err(path, f"duplicate claim id '{claim_id}'"))
        claim_ids.add(claim_id)

        source_url = str(claim.get("sourceUrl", ""))
        parsed = urlparse(source_url)
        host = (parsed.hostname or "").lower()
        if host.startswith("www."):
            host = host[4:]
        if host not in ALLOWED_SOURCE_HOSTS:
            errors.append(
                err(path, f"{pointer}.sourceUrl host '{host or '<missing>'}' is not in approved Microsoft hosts")
            )

        lifecycle_state = str(claim.get("lifecycleState", ""))
        source_type = str(claim.get("sourceType", ""))
        if lifecycle_state == "generally-available":
            if host != "learn.microsoft.com":
                errors.append(
                    err(path, f"{pointer} is generally-available and must cite learn.microsoft.com")
                )
            if source_type not in ALLOWED_GA_SOURCE_TYPES:
                errors.append(
                    err(
                        path,
                        f"{pointer}.sourceType '{source_type}' is not allowed for generally-available claims",
                    )
                )

        verified_on = parse_date(str(claim.get("verifiedOn", "")), path, f"{pointer}.verifiedOn", errors)
        if reviewed_on and verified_on and verified_on > reviewed_on:
            errors.append(
                err(path, f"{pointer}.verifiedOn ({verified_on.isoformat()}) cannot be after reviewedOn ({reviewed_on.isoformat()})")
            )

        affected_files = claim.get("affectedFiles", [])
        if any(Path(item).is_absolute() for item in affected_files):
            errors.append(err(path, f"{pointer}.affectedFiles must use repository-relative paths"))


def validate_execution_and_mutations(data: dict[str, Any], path: Path, errors: list[str]) -> None:
    phases = data.get("execution", {}).get("phases", [])
    phase_ids: list[str] = [str(phase.get("id", "")) for phase in phases]
    duplicate_phases = sorted({phase_id for phase_id in phase_ids if phase_ids.count(phase_id) > 1 and phase_id})
    if duplicate_phases:
        errors.append(err(path, f"duplicate execution phase IDs: {duplicate_phases}"))

    missing_required_phases = sorted(REQUIRED_PHASES - set(phase_ids))
    if missing_required_phases:
        errors.append(err(path, f"execution.phases missing required phases: {missing_required_phases}"))

    step_ids: list[str] = []
    mutation_refs_by_phase: dict[str, list[str]] = {}
    mutation_ref_steps: dict[str, list[str]] = {}
    step_readback_for_mutation: dict[str, bool] = {}

    for phase in phases:
        phase_id = str(phase.get("id", ""))
        for step in phase.get("steps", []):
            step_id = str(step.get("id", ""))
            if step_id:
                step_ids.append(step_id)

            mutation_ref = step.get("mutationRef")
            if isinstance(mutation_ref, str) and mutation_ref:
                mutation_refs_by_phase.setdefault(phase_id, []).append(mutation_ref)
                mutation_ref_steps.setdefault(mutation_ref, []).append(step_id or "<missing-step-id>")
                read_back_required = bool(step.get("readBack", {}).get("required"))
                step_readback_for_mutation[mutation_ref] = (
                    step_readback_for_mutation.get(mutation_ref, False) or read_back_required
                )

    duplicate_steps = sorted({step_id for step_id in step_ids if step_ids.count(step_id) > 1})
    if duplicate_steps:
        errors.append(err(path, f"duplicate step IDs: {duplicate_steps}"))

    mutation_index: dict[str, dict[str, Any]] = {}
    for mutation in data.get("mutations", []):
        mutation_id = str(mutation.get("id", ""))
        if mutation_id in mutation_index:
            errors.append(err(path, f"duplicate mutation id '{mutation_id}'"))
            continue
        mutation_index[mutation_id] = mutation

    cleanup_refs = set(mutation_refs_by_phase.get("cleanup", []))
    referenced_mutations = {ref for refs in mutation_refs_by_phase.values() for ref in refs}
    unknown_refs = sorted(reference for reference in referenced_mutations if reference not in mutation_index)
    for reference in unknown_refs:
        step_list = sorted(set(mutation_ref_steps.get(reference, [])))
        errors.append(
            err(
                path,
                f"steps reference undefined mutation id '{reference}' "
                f"(stepIds: {step_list})",
            )
        )

    for mutation_id, mutation in mutation_index.items():
        reversibility = str(mutation.get("reversibilityClass", ""))
        cleanup_required = bool(mutation.get("cleanupRequired"))
        cleanup_strategy = str(mutation.get("cleanupStrategy", ""))
        break_glass_required = bool(mutation.get("breakGlassRequired"))
        is_referenced = mutation_id in referenced_mutations

        if reversibility == "prohibited":
            if is_referenced:
                errors.append(err(path, f"prohibited mutation '{mutation_id}' must not be referenced by execution steps"))
            if cleanup_required:
                errors.append(err(path, f"prohibited mutation '{mutation_id}' cannot require cleanup"))
            if cleanup_strategy != "none":
                errors.append(err(path, f"prohibited mutation '{mutation_id}' must use cleanupStrategy 'none'"))
            continue

        if reversibility == "read-only":
            if cleanup_required:
                errors.append(err(path, f"read-only mutation '{mutation_id}' cannot require cleanup"))
            if cleanup_strategy != "none":
                errors.append(err(path, f"read-only mutation '{mutation_id}' must use cleanupStrategy 'none'"))

        if reversibility in {"reversible", "delayed-cleanup", "tenant-reset"}:
            if not cleanup_required:
                errors.append(err(path, f"mutation '{mutation_id}' is {reversibility} and must set cleanupRequired=true"))
            if cleanup_strategy == "none":
                errors.append(err(path, f"mutation '{mutation_id}' is {reversibility} and cannot use cleanupStrategy 'none'"))
            if mutation_id not in cleanup_refs:
                errors.append(
                    err(
                        path,
                        f"mutation '{mutation_id}' requires cleanup but no cleanup phase step references it",
                    )
                )

        if reversibility == "tenant-reset" and not break_glass_required:
            errors.append(err(path, f"tenant-reset mutation '{mutation_id}' must set breakGlassRequired=true"))

        if bool(mutation.get("readBackRequired")) and not step_readback_for_mutation.get(mutation_id, False):
            errors.append(err(path, f"mutation '{mutation_id}' requires read-back but no referencing step marks readBack.required=true"))

        if cleanup_required is False and mutation_id in cleanup_refs and reversibility in {"read-only", "prohibited"}:
            errors.append(err(path, f"mutation '{mutation_id}' is non-mutable and must not be listed in cleanup steps"))


def validate_disposition_rules(data: dict[str, Any], path: Path, errors: list[str]) -> None:
    rules = data.get("dispositionRules", {})
    allowed = set(rules.get("allowedDispositions", []))
    if allowed != EXPECTED_DISPOSITIONS:
        errors.append(
            err(
                path,
                "dispositionRules.allowedDispositions must contain exactly "
                f"{sorted(EXPECTED_DISPOSITIONS)}",
            )
        )
    if rules.get("failIsBlocking") is not True:
        errors.append(err(path, "dispositionRules.failIsBlocking must be true"))
    if rules.get("blockedRequiresSourceEvidence") is not True:
        errors.append(err(path, "dispositionRules.blockedRequiresSourceEvidence must be true"))
    if rules.get("notApplicableRequiresSourceEvidence") is not True:
        errors.append(err(path, "dispositionRules.notApplicableRequiresSourceEvidence must be true"))


def validate_contract(
    path: Path,
    schema_validator: Draft202012Validator,
    valid_controls: set[str],
    solution_controls: dict[str, set[str]],
) -> list[str]:
    errors: list[str] = []

    try:
        data = load_json(path)
    except json.JSONDecodeError as exc:
        return [err(path, f"invalid JSON: {exc}")]
    except OSError as exc:
        return [err(path, f"cannot read file: {exc}")]

    if not isinstance(data, dict):
        return [err(path, "contract root must be a JSON object")]

    for schema_error in sorted(schema_validator.iter_errors(data), key=lambda item: list(item.absolute_path)):
        location = "/".join(str(token) for token in schema_error.absolute_path) or "<root>"
        errors.append(err(path, f"schema: {location}: {schema_error.message}"))

    solution_id = validate_path_and_identity(data, path, set(solution_controls.keys()), errors)
    validate_controls(data, path, valid_controls, solution_controls, solution_id, errors)
    validate_scope(data, path, errors)

    reviewed_on = parse_date(str(data.get("reviewedOn", "")), path, "reviewedOn", errors)
    validate_sources(data, path, reviewed_on, errors)
    validate_execution_and_mutations(data, path, errors)
    validate_disposition_rules(data, path, errors)
    collect_sensitive_strings(data, path, errors)

    return errors


def load_solution_controls() -> dict[str, set[str]]:
    raw_config = load_json(SOLUTION_CONFIG_PATH)
    controls_by_solution: dict[str, set[str]] = {}
    for slug, payload in raw_config.get("solutions", {}).items():
        controls_by_solution[str(slug)] = {str(control_id) for control_id in payload.get("controls", [])}
    return controls_by_solution


def load_valid_control_ids() -> set[str]:
    controls = load_json(CONTROLS_PATH)
    return {str(item.get("control_id", "")) for item in controls}


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Validate lab contract files. Without arguments, scans solutions/*/lab/*.lab.json "
            "and exits successfully when none exist."
        )
    )
    parser.add_argument("paths", nargs="*", help="Optional file(s) or directory(ies) to validate.")
    args = parser.parse_args(argv)

    paths, explicit = discover_contract_paths(args.paths)
    if explicit:
        missing = [path for path in paths if not path.exists()]
        if missing:
            for missing_path in missing:
                print(err(missing_path, "path not found"), file=sys.stderr)
            return 2

    existing_files = [path for path in paths if path.exists() and path.is_file()]
    if not existing_files:
        if explicit:
            print("No contract files matched the provided path(s).", file=sys.stderr)
            return 2
        print("Lab contract validation passed: 0 file(s) checked (no contracts found under solutions/*/lab).")
        return 0

    schema = load_json(SCHEMA_PATH)
    validator = Draft202012Validator(schema, format_checker=FormatChecker())
    valid_controls = load_valid_control_ids()
    solution_controls = load_solution_controls()

    all_errors: list[str] = []
    success_count = 0
    for path in existing_files:
        file_errors = validate_contract(path, validator, valid_controls, solution_controls)
        if file_errors:
            all_errors.extend(file_errors)
            continue
        success_count += 1
        print(f"OK  {rel(path)}")

    if all_errors:
        print(
            f"\nLab contract validation failed ({len(all_errors)} issue(s)):",
            file=sys.stderr,
        )
        for message in all_errors:
            print(f"  - {message}", file=sys.stderr)
        return 1

    print(f"\nLab contract validation passed: {success_count} file(s) checked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
