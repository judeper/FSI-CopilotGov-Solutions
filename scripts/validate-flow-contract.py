#!/usr/bin/env python3
"""Validate a hybrid flow contract JSON against the pilot schema.

This validator is part of the Hybrid Flow Validation pilot proposal
(see docs/reference/hybrid-flow-validation-proposal.md). It is intentionally
NOT wired into CI. It exists to demonstrate that the proposed contract
format is machine-checkable and that action names declared in the contract
also appear in a sibling markdown narrative under
``solutions/<id>/docs/flows/<flow_id>.md`` when one is present.

Usage::

    python scripts/validate-flow-contract.py <path-to-flow.json> [more...]

Exits 0 on success, 1 on validation errors.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent

SCHEMA_VERSION = "1.0"

REQUIRED_TOP_LEVEL_FIELDS: dict[str, type | tuple[type, ...]] = {
    "schema_version": str,
    "solution_id": str,
    "flow_name": str,
    "flow_id": str,
    "sample": bool,
    "trigger": dict,
    "connectors": list,
    "actions": list,
    "condition_branches": list,
    "error_handling": dict,
    "retry_policy": dict,
    "naming_pattern": str,
    "evidence_outputs": list,
}

ALLOWED_TRIGGER_KINDS = {"recurrence", "automated", "manual"}
ALLOWED_RETRY_TYPES = {"none", "fixed", "exponential"}
ALLOWED_SCOPE_PATTERNS = {"try-catch", "none"}


def _err(path: Path, msg: str) -> str:
    try:
        rel = path.relative_to(ROOT)
    except ValueError:
        rel = path
    return f"{rel}: {msg}"


def validate_contract(path: Path) -> list[str]:
    errors: list[str] = []
    try:
        data: Any = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return [_err(path, f"invalid JSON: {exc}")]
    except OSError as exc:
        return [_err(path, f"cannot read: {exc}")]

    if not isinstance(data, dict):
        return [_err(path, "root must be a JSON object")]

    for field, expected_type in REQUIRED_TOP_LEVEL_FIELDS.items():
        if field not in data:
            errors.append(_err(path, f"missing required field '{field}'"))
            continue
        if not isinstance(data[field], expected_type):
            errors.append(
                _err(path, f"field '{field}' must be of type {expected_type.__name__}")
            )

    if errors:
        return errors

    if data["schema_version"] != SCHEMA_VERSION:
        errors.append(
            _err(path, f"schema_version '{data['schema_version']}' is not supported (expected '{SCHEMA_VERSION}')")
        )

    expected_solution = path.parents[1].name
    if data["solution_id"] != expected_solution:
        errors.append(
            _err(path, f"solution_id '{data['solution_id']}' does not match folder '{expected_solution}'")
        )

    expected_flow_id = path.name.removesuffix(".flow.json")
    if data["flow_id"] != expected_flow_id:
        errors.append(
            _err(path, f"flow_id '{data['flow_id']}' does not match filename '{expected_flow_id}'")
        )

    trigger = data["trigger"]
    if trigger.get("kind") not in ALLOWED_TRIGGER_KINDS:
        errors.append(_err(path, f"trigger.kind must be one of {sorted(ALLOWED_TRIGGER_KINDS)}"))
    if not isinstance(trigger.get("details"), str) or not trigger.get("details"):
        errors.append(_err(path, "trigger.details must be a non-empty string"))

    if not data["connectors"]:
        errors.append(_err(path, "connectors must declare at least one entry"))
    for idx, conn in enumerate(data["connectors"]):
        if not isinstance(conn, dict) or not conn.get("name") or not conn.get("kind"):
            errors.append(_err(path, f"connectors[{idx}] must include 'name' and 'kind'"))

    action_names: list[str] = []
    if not data["actions"]:
        errors.append(_err(path, "actions must declare at least one entry"))
    for idx, action in enumerate(data["actions"]):
        if not isinstance(action, dict) or not action.get("name") or not action.get("type"):
            errors.append(_err(path, f"actions[{idx}] must include 'name' and 'type'"))
        else:
            action_names.append(action["name"])

    naming_pattern = data["naming_pattern"]
    try:
        compiled = re.compile(naming_pattern)
    except re.error as exc:
        errors.append(_err(path, f"naming_pattern is not a valid regex: {exc}"))
        compiled = None
    if compiled is not None:
        for name in action_names:
            if not compiled.match(name):
                errors.append(_err(path, f"action name '{name}' does not match naming_pattern"))

    action_name_set = set(action_names)
    for idx, branch in enumerate(data["condition_branches"]):
        if not isinstance(branch, dict):
            errors.append(_err(path, f"condition_branches[{idx}] must be an object"))
            continue
        cname = branch.get("name")
        if cname not in action_name_set:
            errors.append(
                _err(path, f"condition_branches[{idx}].name '{cname}' is not declared in actions")
            )
        for side in ("yes", "no"):
            members = branch.get(side, [])
            if not isinstance(members, list):
                errors.append(_err(path, f"condition_branches[{idx}].{side} must be a list"))
                continue
            for member in members:
                if member not in action_name_set:
                    errors.append(
                        _err(path, f"condition_branches[{idx}].{side} references unknown action '{member}'")
                    )

    eh = data["error_handling"]
    if not isinstance(eh.get("configured_run_after"), bool):
        errors.append(_err(path, "error_handling.configured_run_after must be a boolean"))
    if eh.get("scope_pattern") not in ALLOWED_SCOPE_PATTERNS:
        errors.append(_err(path, f"error_handling.scope_pattern must be one of {sorted(ALLOWED_SCOPE_PATTERNS)}"))

    rp = data["retry_policy"]
    if rp.get("type") not in ALLOWED_RETRY_TYPES:
        errors.append(_err(path, f"retry_policy.type must be one of {sorted(ALLOWED_RETRY_TYPES)}"))
    if not isinstance(rp.get("count"), int) or rp.get("count") < 0:
        errors.append(_err(path, "retry_policy.count must be a non-negative integer"))
    if not isinstance(rp.get("interval"), str) or not rp.get("interval", "").startswith("PT"):
        errors.append(_err(path, "retry_policy.interval must be an ISO8601 duration starting with 'PT'"))

    if not all(isinstance(item, str) and item for item in data["evidence_outputs"]):
        errors.append(_err(path, "evidence_outputs must be a list of non-empty strings"))

    narrative = path.parents[1] / "docs" / "flows" / f"{data['flow_id']}.md"
    if narrative.exists():
        narrative_text = narrative.read_text(encoding="utf-8", errors="replace")
        for name in action_names:
            if name not in narrative_text:
                errors.append(
                    _err(path, f"action '{name}' is not mentioned in narrative {narrative.relative_to(ROOT)}")
                )
    return errors


def main(argv: list[str]) -> int:
    if not argv:
        print("usage: validate-flow-contract.py <path-to-flow.json> [more...]", file=sys.stderr)
        return 2

    total_errors: list[str] = []
    for arg in argv:
        path = Path(arg).resolve()
        if not path.exists():
            total_errors.append(f"{arg}: file not found")
            continue
        errs = validate_contract(path)
        if errs:
            total_errors.extend(errs)
        else:
            try:
                rel = path.relative_to(ROOT)
            except ValueError:
                rel = path
            print(f"OK  {rel}")

    if total_errors:
        print(f"\nFlow contract validation failed ({len(total_errors)} issues):", file=sys.stderr)
        for err in total_errors:
            print(f"  - {err}", file=sys.stderr)
        return 1

    print(f"\nFlow contract validation passed: {len(argv)} file(s) checked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
