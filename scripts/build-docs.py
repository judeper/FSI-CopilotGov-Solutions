#!/usr/bin/env python3
"""Build site-docs/ from source docs and solution READMEs, then validate nav."""

import json
import shutil
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None  # type: ignore[assignment]

ROOT = Path(__file__).resolve().parent.parent
SOURCE_DOCS = ROOT / "docs"
SITE_DOCS = ROOT / "site-docs"
SOLUTIONS_ROOT = ROOT / "solutions"
CONFIG_PATH = ROOT / "scripts" / "solution-config.yml"
MKDOCS_PATH = ROOT / "mkdocs.yml"


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def load_yaml(path: Path):
    text = path.read_text(encoding="utf-8")
    if yaml is not None:
        # Use a loader that tolerates the !!python/name tags MkDocs uses for superfences
        loader = yaml.SafeLoader
        loader.add_multi_constructor(
            "tag:yaml.org,2002:python/",
            lambda loader, suffix, node: None,
        )
        return yaml.load(text, Loader=loader)  # noqa: S506
    # Fallback: try JSON in case the file is JSON-formatted YAML
    return json.loads(text)


FRAMEWORK_SITE = "https://judeper.github.io/FSI-CopilotGov"
FRAMEWORK_BLOB = "https://github.com/judeper/FSI-CopilotGov/blob/main"


def rewrite_solution_links(content: str) -> str:
    """Rewrite relative links in solution docs for the site-docs context.

    - docs/playbooks/... -> absolute framework site URL
    - ./docs/ prefix -> stripped (sibling page reference)
    - docs/ prefix -> stripped
    """
    import re

    def replace_link(match):
        prefix, path, suffix = match.group(1), match.group(2), match.group(3)
        if path.startswith(("http://", "https://", "#", "mailto:")):
            return match.group(0)
        # Framework playbook / control links
        if "playbooks/control-implementations" in path or path.startswith("docs/controls"):
            clean = path.lstrip("./")
            return f"{prefix}{FRAMEWORK_BLOB}/{clean}{suffix}"
        # Strip docs/ prefix for intra-solution links
        clean = path
        if clean.startswith("./docs/"):
            clean = clean[7:]
        elif clean.startswith("docs/"):
            clean = clean[5:]
        return f"{prefix}{clean}{suffix}"

    return re.sub(r"(\[[^\]]*\]\()([^)]+)(\))", replace_link, content)


def copy_markdown_tree(source: Path, destination: Path) -> None:
    if destination.exists():
        shutil.rmtree(destination)
    shutil.copytree(source, destination)


def validate_nav(nav, base: Path) -> list:
    missing = []
    if isinstance(nav, str):
        target = base / nav
        if not target.exists():
            missing.append(str(target))
    elif isinstance(nav, list):
        for item in nav:
            missing.extend(validate_nav(item, base))
    elif isinstance(nav, dict):
        for value in nav.values():
            missing.extend(validate_nav(value, base))
    return missing


def main() -> None:
    config = load_json(CONFIG_PATH)
    mkdocs = load_yaml(MKDOCS_PATH)

    SITE_DOCS.mkdir(parents=True, exist_ok=True)
    copy_markdown_tree(SOURCE_DOCS, SITE_DOCS)

    reference_dir = SITE_DOCS / "reference"
    reference_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / "CHANGELOG.md", reference_dir / "changelog.md")

    for slug in config["solutions"].keys():
        solution_dir = SOLUTIONS_ROOT / slug
        output_dir = SITE_DOCS / "solutions" / slug
        output_dir.mkdir(parents=True, exist_ok=True)

        readme_path = solution_dir / "README.md"
        if readme_path.exists():
            readme_text = readme_path.read_text(encoding="utf-8")
            (output_dir / "index.md").write_text(
                rewrite_solution_links(readme_text), encoding="utf-8"
            )

        docs_dir = solution_dir / "docs"
        if docs_dir.exists():
            for doc_path in docs_dir.glob("*.md"):
                target = output_dir / doc_path.name
                target.write_text(
                    rewrite_solution_links(doc_path.read_text(encoding="utf-8")),
                    encoding="utf-8",
                )

    missing = validate_nav(mkdocs["nav"], SITE_DOCS)
    if missing:
        msg = "Missing MkDocs nav files:\n" + "\n".join(sorted(missing))
        raise SystemExit(msg)

    print("Documentation build inputs refreshed successfully.")


if __name__ == "__main__":
    main()
