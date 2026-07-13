#!/usr/bin/env python3
"""Validate FSI lab-validation result files."""

from __future__ import annotations

import argparse
import json
import re
import sys
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
SCHEMA_PATH = ROOT / "data" / "lab-validation-result.schema.json"

RESULT_ID_RE = re.compile(
    r"^lab-result:(?P<solution>[a-z0-9][a-z0-9-]*):(?P<revision>[a-z0-9][a-z0-9.-]*)$"
)
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


def rel(path: Path) -> Path:
    try:
        return path.relative_to(ROOT)
    except ValueError:
        return path


def err(path: Path, message: str) -> str:
    return f"{rel(path)}: {message}"


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def discover_result_paths(raw_paths: list[str]) -> tuple[list[Path], bool]:
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
                discovered.extend(sorted(candidate.rglob("*.lab-result.json")))
                continue
            if candidate.is_file():
                discovered.append(candidate)
                continue
            discovered.append(candidate)
    else:
        discovered.extend(sorted((ROOT / "solutions").glob("*/lab/*.lab-result.json")))
        discovered.extend(sorted((ROOT / "solutions").glob("*/lab/results/*.lab-result.json")))

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
    if path.parent.name == "results" and path.parent.parent.name == "lab":
        return path.parent.parent.parent.name
    return None


def collect_sensitive_strings(node: Any, path: Path, errors: list[str], pointer: str = "<root>") -> None:
    if isinstance(node, dict):
        for key, value in node.items():
            child_pointer = f"{pointer}.{key}" if pointer != "<root>" else key
            if PROHIBITED_KEY_PATTERN.search(str(key)):
                errors.append(err(path, f"prohibited key in result content: {child_pointer}"))
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


def collect_all_evidence_refs(data: dict[str, Any]) -> set[str]:
    refs: set[str] = set()
    for step in data.get("stepResults", []):
        refs.update(str(item) for item in step.get("evidenceRefs", []) if str(item))
    for blocker in data.get("blockers", []):
        refs.update(str(item) for item in blocker.get("evidenceRefs", []) if str(item))
    for claim in data.get("sourceVerification", {}).get("claims", []):
        refs.update(str(item) for item in claim.get("evidenceRefs", []) if str(item))
    package = data.get("evidencePackage")
    if isinstance(package, dict):
        package_path = str(package.get("path", "")).strip()
        if package_path:
            refs.add(package_path)
    return refs


def validate_identity(data: dict[str, Any], path: Path, errors: list[str]) -> None:
    if not path.name.endswith(".lab-result.json"):
        errors.append(err(path, "result filename must end with '.lab-result.json'"))

    expected_solution = infer_solution_from_path(path)
    file_solution = (
        path.name[: -len(".lab-result.json")] if path.name.endswith(".lab-result.json") else path.stem
    )
    solution_id = str(data.get("solutionId", ""))
    if expected_solution and file_solution != expected_solution:
        errors.append(
            err(
                path,
                f"filename '{file_solution}' must match its parent solution folder '{expected_solution}'",
            )
        )
    if expected_solution and solution_id and solution_id != expected_solution:
        errors.append(err(path, f"solutionId '{solution_id}' does not match folder '{expected_solution}'"))

    result_id = str(data.get("resultId", ""))
    result_match = RESULT_ID_RE.fullmatch(result_id)
    if not result_match:
        errors.append(err(path, f"resultId '{result_id}' does not follow 'lab-result:<solution>:<revision>'"))
    elif solution_id and result_match.group("solution") != solution_id:
        errors.append(
            err(
                path,
                f"resultId solution '{result_match.group('solution')}' does not match solutionId '{solution_id}'",
            )
        )

    contract_id = str(data.get("contractId", ""))
    contract_match = CONTRACT_ID_RE.fullmatch(contract_id)
    if not contract_match:
        errors.append(
            err(path, f"contractId '{contract_id}' does not follow 'lab-contract:<solution>:<revision>'")
        )
    elif solution_id and contract_match.group("solution") != solution_id:
        errors.append(
            err(
                path,
                f"contractId solution '{contract_match.group('solution')}' does not match solutionId '{solution_id}'",
            )
        )


def validate_source_hosts(data: dict[str, Any], path: Path, errors: list[str]) -> None:
    for index, claim in enumerate(data.get("sourceVerification", {}).get("claims", [])):
        source_url = str(claim.get("sourceUrl", ""))
        parsed = urlparse(source_url)
        host = (parsed.hostname or "").lower()
        if host.startswith("www."):
            host = host[4:]
        if host not in ALLOWED_SOURCE_HOSTS:
            errors.append(
                err(
                    path,
                    f"sourceVerification.claims[{index}].sourceUrl host "
                    f"'{host or '<missing>'}' is not in approved Microsoft hosts",
                )
            )


def validate_semantics(data: dict[str, Any], path: Path, errors: list[str]) -> None:
    summary = data.get("summary", {})
    disposition = str(summary.get("disposition", ""))
    accepted = bool(summary.get("accepted"))
    control_implementation = str(summary.get("controlImplementation", ""))
    preflight_decision = str(data.get("preflight", {}).get("decision", ""))

    step_results = data.get("stepResults", [])
    blockers = data.get("blockers", [])
    cleanup = data.get("cleanup", {})
    source_claims = data.get("sourceVerification", {}).get("claims", [])

    step_ids = [str(step.get("stepId", "")) for step in step_results]
    duplicate_steps = sorted({step_id for step_id in step_ids if step_ids.count(step_id) > 1 and step_id})
    if duplicate_steps:
        errors.append(err(path, f"duplicate stepResult.stepId values: {duplicate_steps}"))

    claim_ids = [str(claim.get("claimId", "")) for claim in source_claims]
    duplicate_claims = sorted({claim_id for claim_id in claim_ids if claim_ids.count(claim_id) > 1 and claim_id})
    if duplicate_claims:
        errors.append(err(path, f"duplicate sourceVerification claim IDs: {duplicate_claims}"))

    if disposition == "FAIL" and accepted:
        errors.append(err(path, "summary.accepted cannot be true when disposition is FAIL"))
    if disposition == "PASS" and not accepted:
        errors.append(err(path, "summary.accepted must be true when disposition is PASS"))
    if disposition == "PARTIAL" and accepted:
        errors.append(err(path, "summary.accepted cannot be true when disposition is PARTIAL"))

    if accepted and disposition in {"BLOCKED", "NOT-APPLICABLE"} and control_implementation in {"implemented", "partial"}:
        errors.append(
            err(
                path,
                "accepted BLOCKED/NOT-APPLICABLE dispositions cannot report controlImplementation as implemented or partial",
            )
        )

    evidence_refs = collect_all_evidence_refs(data)
    if accepted and disposition in {"PASS", "BLOCKED", "NOT-APPLICABLE"} and not evidence_refs:
        errors.append(
            err(
                path,
                "accepted PASS/BLOCKED/NOT-APPLICABLE dispositions must include at least one evidence reference",
            )
        )

    if disposition == "BLOCKED" and len(blockers) == 0:
        errors.append(err(path, "disposition BLOCKED requires at least one blocker entry"))
    if preflight_decision == "HOLD" and len(blockers) == 0:
        errors.append(err(path, "preflight decision HOLD requires at least one blocker entry"))

    if preflight_decision == "NO-GO":
        disallowed = [
            str(step.get("stepId", "<missing>"))
            for step in step_results
            if step.get("outcome") in {"PASS", "FAIL"}
        ]
        if disallowed:
            errors.append(
                err(
                    path,
                    f"preflight decision NO-GO cannot include PASS/FAIL step outcomes (stepIds: {disallowed})",
                )
            )

    for index, step in enumerate(step_results):
        mutation_executed = step.get("mutationExecuted")
        mutation_ref = step.get("mutationRef")
        if mutation_executed is True and (not isinstance(mutation_ref, str) or not mutation_ref):
            errors.append(
                err(
                    path,
                    f"stepResults[{index}] mutationExecuted=true requires a non-null mutationRef",
                )
            )
        if mutation_executed is False and mutation_ref is not None:
            errors.append(
                err(
                    path,
                    f"stepResults[{index}] mutationExecuted=false requires mutationRef to be null",
                )
            )

    if accepted and disposition in {"BLOCKED", "NOT-APPLICABLE"}:
        source_evidence_ok = any(
            claim.get("status") in {"verified", "negative-verified"} and len(claim.get("evidenceRefs", [])) > 0
            for claim in source_claims
        )
        if not source_evidence_ok:
            errors.append(
                err(
                    path,
                    "accepted BLOCKED/NOT-APPLICABLE results require sourceVerification evidence "
                    "(verified or negative-verified with evidenceRefs)",
                )
            )

    cleanup_state = str(cleanup.get("state", ""))
    orphaned = [str(mutation_id) for mutation_id in cleanup.get("orphanedMutations", [])]
    if cleanup_state == "orphaned" and len(orphaned) == 0:
        errors.append(err(path, "cleanup.state 'orphaned' requires orphanedMutations entries"))
    if cleanup_state == "completed" and len(orphaned) > 0:
        errors.append(err(path, "cleanup.state 'completed' cannot include orphanedMutations"))
    if cleanup_state == "not-required":
        executed_mutations = [
            step.get("mutationRef")
            for step in step_results
            if step.get("mutationExecuted") is True
            and isinstance(step.get("mutationRef"), str)
            and step.get("mutationRef")
        ]
        if executed_mutations:
            errors.append(
                err(
                    path,
                    "cleanup.state 'not-required' is inconsistent with executed mutated steps: "
                    f"{sorted(set(str(item) for item in executed_mutations))}",
                )
            )
    if disposition == "PASS" and cleanup_state in {"failed", "orphaned"}:
        errors.append(err(path, "PASS disposition cannot be combined with failed/orphaned cleanup state"))


def validate_result(path: Path, schema_validator: Draft202012Validator) -> list[str]:
    errors: list[str] = []

    try:
        data = load_json(path)
    except json.JSONDecodeError as exc:
        return [err(path, f"invalid JSON: {exc}")]
    except OSError as exc:
        return [err(path, f"cannot read file: {exc}")]

    if not isinstance(data, dict):
        return [err(path, "result root must be a JSON object")]

    for schema_error in sorted(schema_validator.iter_errors(data), key=lambda item: list(item.absolute_path)):
        location = "/".join(str(token) for token in schema_error.absolute_path) or "<root>"
        errors.append(err(path, f"schema: {location}: {schema_error.message}"))

    validate_identity(data, path, errors)
    validate_source_hosts(data, path, errors)
    validate_semantics(data, path, errors)
    collect_sensitive_strings(data, path, errors)

    return errors


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Validate lab result files. Without arguments, scans "
            "solutions/*/lab/*.lab-result.json and exits successfully when none exist."
        )
    )
    parser.add_argument("paths", nargs="*", help="Optional file(s) or directory(ies) to validate.")
    args = parser.parse_args(argv)

    paths, explicit = discover_result_paths(args.paths)
    if explicit:
        missing = [path for path in paths if not path.exists()]
        if missing:
            for missing_path in missing:
                print(err(missing_path, "path not found"), file=sys.stderr)
            return 2

    existing_files = [path for path in paths if path.exists() and path.is_file()]
    if not existing_files:
        if explicit:
            print("No lab result files matched the provided path(s).", file=sys.stderr)
            return 2
        print("Lab result validation passed: 0 file(s) checked (no results found under solutions/*/lab).")
        return 0

    schema = load_json(SCHEMA_PATH)
    validator = Draft202012Validator(schema, format_checker=FormatChecker())

    all_errors: list[str] = []
    success_count = 0
    for path in existing_files:
        file_errors = validate_result(path, validator)
        if file_errors:
            all_errors.extend(file_errors)
            continue
        success_count += 1
        print(f"OK  {rel(path)}")

    if all_errors:
        print(f"\nLab result validation failed ({len(all_errors)} issue(s)):", file=sys.stderr)
        for message in all_errors:
            print(f"  - {message}", file=sys.stderr)
        return 1

    print(f"\nLab result validation passed: {success_count} file(s) checked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
