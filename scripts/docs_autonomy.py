#!/usr/bin/env python3
"""Classify whether a pull request can affect published documentation."""

from __future__ import annotations

import argparse
from pathlib import Path, PurePosixPath

DOCS_PREFIXES = (
    "data/",
    "docs/",
    "overrides/",
    "site-docs/",
    "solutions/",
    "templates/",
)

DOCS_FILES = {
    ".github/branch-protection.json",
    ".github/copilot-instructions.md",
    ".github/workflows/docs-autonomy.yml",
    "AGENTS.md",
    "CHANGELOG.md",
    "DEPLOYMENT-GUIDE.md",
    "README.md",
    "SCOPE.md",
    "SOLUTION-README-TEMPLATE.md",
    "mkdocs.yml",
    "requirements-docs.txt",
    "scripts/build-docs.py",
    "scripts/build_solutions_graph.py",
    "scripts/build_solutions_json.py",
    "scripts/common/EvidenceExport.psm1",
    "scripts/docs_autonomy.py",
    "scripts/solution-config.yml",
    "scripts/sync-agent-md-versions.py",
    "scripts/test_docs_protection.py",
    "scripts/test_lab_validation_contracts.py",
    "scripts/tests/lab-validation.Tests.ps1",
    "scripts/validate-contracts.py",
    "scripts/validate-documentation.py",
    "scripts/validate-evidence.ps1",
    "scripts/validate-lab-contracts.py",
    "scripts/validate-lab-package.ps1",
    "scripts/validate-lab-result.py",
    "scripts/validate-solutions.py",
    "scripts/validate_data_classification.py",
    "scripts/validate_solutions_graph.py",
    "scripts/validate_solutions_json.py",
    "scripts/verify_commercial_scope.py",
    "scripts/verify_readme_counts.py",
    "solutions-graph.json",
    "solutions.json",
}

DOCS_SUFFIXES = {".json", ".jsonl", ".md", ".mdx", ".txt"}


def normalize_path(value: str) -> str:
    return value.strip().replace("\\", "/").removeprefix("./")


def is_docs_relevant(value: str) -> bool:
    path = normalize_path(value)
    if not path:
        return False
    return (
        path in DOCS_FILES
        or path.startswith(DOCS_PREFIXES)
        or PurePosixPath(path).suffix.lower() in DOCS_SUFFIXES
    )


def classify(paths: list[str]) -> tuple[bool, list[str]]:
    relevant = [normalize_path(path) for path in paths if is_docs_relevant(path)]
    return bool(relevant), relevant


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--paths-file", required=True, type=Path)
    parser.add_argument("--github-output", type=Path)
    args = parser.parse_args()

    paths = args.paths_file.read_text(encoding="utf-8").splitlines()
    docs_changed, relevant = classify(paths)
    value = str(docs_changed).lower()

    print(f"docs_changed={value}")
    for path in relevant:
        print(f"docs_path={path}")

    if args.github_output:
        with args.github_output.open("a", encoding="utf-8") as output:
            output.write(f"docs_changed={value}\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
