#!/usr/bin/env python3
"""Regression tests for the committed docs-autonomy protection contract."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path

from docs_autonomy import classify, is_docs_relevant

ROOT = Path(__file__).resolve().parent.parent
PROTECTION_PATH = ROOT / ".github" / "branch-protection.json"
DOCS_WORKFLOW_PATH = ROOT / ".github" / "workflows" / "docs-autonomy.yml"

REQUIRED_CONTEXTS = [
    "Docs Autonomy Gate",
    "Analyze (python)",
    "Dependency Review",
    "gitleaks",
]

CONTEXT_WORKFLOWS = {
    "Docs Autonomy Gate": "docs-autonomy.yml",
    "Analyze (python)": "codeql.yml",
    "Dependency Review": "dependency-review.yml",
    "gitleaks": "secret-scan.yml",
}


def pull_request_child_keys(workflow: str) -> set[str]:
    lines = workflow.splitlines()
    try:
        start = lines.index("  pull_request:")
    except ValueError as error:
        raise AssertionError("workflow must have a top-level pull_request trigger") from error

    keys: set[str] = set()
    for line in lines[start + 1 :]:
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if re.match(r"^  [A-Za-z_][A-Za-z0-9_-]*:", line):
            break
        match = re.match(r"^    ([A-Za-z_][A-Za-z0-9_-]*):", line)
        if match:
            keys.add(match.group(1))
    return keys


class DocsProtectionTests(unittest.TestCase):
    def test_branch_protection_is_exact_and_reviewless(self) -> None:
        protection = json.loads(PROTECTION_PATH.read_text(encoding="utf-8"))

        self.assertEqual(protection["required_status_checks"]["contexts"], REQUIRED_CONTEXTS)
        self.assertIs(protection["required_status_checks"]["strict"], True)
        self.assertIs(protection["enforce_admins"], True)
        self.assertIsNone(protection["required_pull_request_reviews"])
        self.assertIsNone(protection["restrictions"])
        self.assertIs(protection["allow_force_pushes"], False)
        self.assertIs(protection["allow_deletions"], False)
        self.assertFalse(
            any("link" in context.lower() for context in REQUIRED_CONTEXTS),
            "external network link checks must remain non-required",
        )

    def test_every_required_context_is_an_unfiltered_pull_request_job(self) -> None:
        for context, filename in CONTEXT_WORKFLOWS.items():
            workflow = (ROOT / ".github" / "workflows" / filename).read_text(encoding="utf-8")
            self.assertNotIn("pull_request_target:", workflow, filename)
            trigger_keys = pull_request_child_keys(workflow)
            self.assertTrue({"paths", "paths-ignore"}.isdisjoint(trigger_keys), filename)

            if context == "Analyze (python)":
                self.assertIn("name: Analyze (${{ matrix.language }})", workflow)
                self.assertRegex(workflow, r"(?m)^\s+language:\s*\[python\]\s*$")
            else:
                escaped = re.escape(context)
                has_display_name = re.search(
                    rf"(?m)^\s{{4}}name:\s*['\"]?{escaped}['\"]?\s*$",
                    workflow,
                )
                has_job_key = re.search(
                    rf"(?m)^\s{{2}}{re.escape(context)}:\s*$",
                    workflow,
                )
                self.assertTrue(has_display_name or has_job_key, f"{context} is not a workflow job")

    def test_trigger_parser_detects_first_child_path_filter(self) -> None:
        workflow = """on:
  pull_request:
    paths-ignore:
      - 'docs/**'
  push:
    branches: [main]
"""
        self.assertIn("paths-ignore", pull_request_child_keys(workflow))

    def test_docs_gate_pins_deterministic_validators(self) -> None:
        workflow = DOCS_WORKFLOW_PATH.read_text(encoding="utf-8")
        self.assertIn('git diff --name-only "$BASE_SHA" "$HEAD_SHA"', workflow)
        self.assertNotIn("--diff-filter=", workflow, "deleted documentation paths must be classified")
        required_commands = (
            "python scripts/build-docs.py",
            "python scripts/validate-contracts.py",
            "python scripts/validate_data_classification.py",
            "python scripts/test_lab_validation_contracts.py",
            "python scripts/validate-lab-contracts.py",
            "python scripts/validate-lab-result.py",
            "python scripts/validate-solutions.py",
            "python scripts/validate-documentation.py",
            "python scripts/verify_commercial_scope.py",
            "./scripts/validate-lab-package.ps1 -Path ./scripts/tests/fixtures/lab-package/portable-evidence.json -ResultPath ./scripts/tests/fixtures/lab-results/valid/01-copilot-readiness-scanner/lab/01-copilot-readiness-scanner.lab-result.json",
            "Invoke-Pester -Path ./scripts/tests/lab-validation.Tests.ps1 -Output Detailed",
            "python scripts/validate_solutions_json.py",
            "python scripts/validate_solutions_graph.py",
            "python scripts/verify_readme_counts.py",
            "python scripts/sync-agent-md-versions.py --check",
            "./scripts/validate-evidence.ps1 -ConfigurationTier baseline",
            "mkdocs build --strict",
        )
        for command in required_commands:
            self.assertIn(command, workflow)
        self.assertNotRegex(workflow.lower(), r"(lychee|markdown-link-check|linkinator)")

    def test_path_classifier_shims_non_docs_changes(self) -> None:
        self.assertTrue(is_docs_relevant("docs/guide.md"))
        self.assertTrue(is_docs_relevant("solutions/01-example/README.md"))
        self.assertTrue(is_docs_relevant("data/solution-catalog.json"))
        self.assertTrue(is_docs_relevant(".github/branch-protection.json"))
        self.assertTrue(is_docs_relevant("scripts/validate-lab-contracts.py"))
        self.assertTrue(is_docs_relevant("scripts/common/EvidenceExport.psm1"))
        self.assertTrue(is_docs_relevant("scripts/tests/lab-validation.Tests.ps1"))
        self.assertFalse(is_docs_relevant(".github/workflows/release.yml"))
        self.assertFalse(is_docs_relevant("scripts/deploy.ps1"))

        changed, relevant = classify(["scripts/deploy.ps1", ".github/workflows/release.yml"])
        self.assertFalse(changed)
        self.assertEqual(relevant, [])


if __name__ == "__main__":
    unittest.main()
