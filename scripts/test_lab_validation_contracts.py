#!/usr/bin/env python3
"""Unit tests for lab contract and result validators."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTRACT_VALIDATOR = ROOT / "scripts" / "validate-lab-contracts.py"
RESULT_VALIDATOR = ROOT / "scripts" / "validate-lab-result.py"
FIXTURES = ROOT / "scripts" / "tests" / "fixtures"


def run_validator(script_path: Path, *paths: Path) -> subprocess.CompletedProcess[str]:
    args = [sys.executable, str(script_path), *(str(path) for path in paths)]
    return subprocess.run(
        args,
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )


class LabValidationTests(unittest.TestCase):
    def test_contract_validator_accepts_repository_contracts(self) -> None:
        result = run_validator(CONTRACT_VALIDATOR)
        self.assertEqual(result.returncode, 0, msg=result.stderr or result.stdout)
        self.assertIn("lab contract validation passed", result.stdout.lower())
        self.assertIn("file(s) checked", result.stdout.lower())

    def test_contract_validator_accepts_valid_fixture(self) -> None:
        valid_path = FIXTURES / "lab-contracts" / "valid"
        result = run_validator(CONTRACT_VALIDATOR, valid_path)
        self.assertEqual(result.returncode, 0, msg=result.stderr or result.stdout)
        self.assertIn("validation passed", result.stdout.lower())

    def test_contract_validator_rejects_invalid_fixture(self) -> None:
        invalid_path = FIXTURES / "lab-contracts" / "invalid"
        result = run_validator(CONTRACT_VALIDATOR, invalid_path)
        self.assertNotEqual(result.returncode, 0, msg=result.stdout)
        combined_output = f"{result.stdout}\n{result.stderr}"
        self.assertIn("unknown control ids", combined_output.lower())
        self.assertIn("generally-available", combined_output.lower())
        self.assertIn("mutation 'mutation-sample-policy' is reversible", combined_output.lower())

    def test_contract_validator_accepts_solution21_repository_contract(self) -> None:
        contract_path = (
            ROOT
            / "solutions"
            / "21-cross-tenant-agent-federation-auditor"
            / "lab"
            / "21-cross-tenant-agent-federation-auditor.lab.json"
        )
        result = run_validator(CONTRACT_VALIDATOR, contract_path)
        self.assertEqual(result.returncode, 0, msg=result.stderr or result.stdout)
        self.assertIn("validation passed", result.stdout.lower())

    def test_result_validator_allows_zero_repository_results(self) -> None:
        result = run_validator(RESULT_VALIDATOR)
        self.assertEqual(result.returncode, 0, msg=result.stderr or result.stdout)
        self.assertIn("0 file(s) checked", result.stdout)

    def test_result_validator_accepts_valid_fixture(self) -> None:
        valid_path = FIXTURES / "lab-results" / "valid"
        result = run_validator(RESULT_VALIDATOR, valid_path)
        self.assertEqual(result.returncode, 0, msg=result.stderr or result.stdout)
        self.assertIn("validation passed", result.stdout.lower())

    def test_result_validator_rejects_invalid_fixture(self) -> None:
        invalid_path = FIXTURES / "lab-results" / "invalid"
        result = run_validator(RESULT_VALIDATOR, invalid_path)
        self.assertNotEqual(result.returncode, 0, msg=result.stdout)
        combined_output = f"{result.stdout}\n{result.stderr}"
        self.assertIn("cannot be true when disposition is fail", combined_output.lower())
        self.assertIn("preflight decision no-go", combined_output.lower())
        self.assertIn("cleanup.state 'completed' cannot include orphanedmutations", combined_output.lower())

    def test_contract_validator_accepts_read_only_contract_with_zero_mutations(self) -> None:
        contract_path = (
            FIXTURES
            / "lab-contracts"
            / "valid"
            / "read-only-no-mutations"
            / "01-copilot-readiness-scanner"
            / "lab"
            / "01-copilot-readiness-scanner.lab.json"
        )
        result = run_validator(CONTRACT_VALIDATOR, contract_path)
        self.assertEqual(result.returncode, 0, msg=result.stderr or result.stdout)
        self.assertIn("validation passed", result.stdout.lower())

    def test_result_validator_accepts_read_only_no_mutation_cleanup_not_required(self) -> None:
        result_path = (
            FIXTURES
            / "lab-results"
            / "valid"
            / "read-only-no-mutations"
            / "01-copilot-readiness-scanner"
            / "lab"
            / "01-copilot-readiness-scanner.lab-result.json"
        )
        result = run_validator(RESULT_VALIDATOR, result_path)
        self.assertEqual(result.returncode, 0, msg=result.stderr or result.stdout)
        self.assertIn("validation passed", result.stdout.lower())

    def test_result_validator_rejects_mutation_executed_without_reference(self) -> None:
        result_path = (
            FIXTURES
            / "lab-results"
            / "invalid"
            / "mutation-executed-without-ref"
            / "01-copilot-readiness-scanner"
            / "lab"
            / "01-copilot-readiness-scanner.lab-result.json"
        )
        result = run_validator(RESULT_VALIDATOR, result_path)
        self.assertNotEqual(result.returncode, 0, msg=result.stdout)
        combined_output = f"{result.stdout}\n{result.stderr}".lower()
        self.assertIn("mutationexecuted=true requires a non-null mutationref", combined_output)

    def test_result_validator_rejects_invalid_datetime_formats(self) -> None:
        source_path = (
            FIXTURES
            / "lab-results"
            / "valid"
            / "01-copilot-readiness-scanner"
            / "lab"
            / "01-copilot-readiness-scanner.lab-result.json"
        )
        document = json.loads(source_path.read_text(encoding="utf-8"))
        document["generatedAt"] = "not-a-date-time"
        document["preflight"]["checkedOn"] = "also-not-a-date-time"

        with tempfile.TemporaryDirectory() as temp_dir:
            invalid_path = Path(temp_dir) / "invalid-format.lab-result.json"
            invalid_path.write_text(json.dumps(document), encoding="utf-8")
            result = run_validator(RESULT_VALIDATOR, invalid_path)

        self.assertNotEqual(result.returncode, 0, msg=result.stdout)
        combined_output = f"{result.stdout}\n{result.stderr}".lower()
        self.assertIn("is not a 'date-time'", combined_output)


if __name__ == "__main__":
    unittest.main()
