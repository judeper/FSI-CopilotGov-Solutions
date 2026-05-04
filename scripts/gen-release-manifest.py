#!/usr/bin/env python3
"""Generate RELEASE-MANIFEST.txt with SHA-256 for every git-tracked file.

Deterministic: file list comes from `git ls-files` and is sorted lexicographically.
Output format (per line): "<sha256>  <relative-posix-path>".
"""

from __future__ import annotations

import hashlib
import subprocess
import sys
from pathlib import Path

OUTPUT_NAME = "RELEASE-MANIFEST.txt"
CHUNK = 1024 * 1024


def tracked_files(repo_root: Path) -> list[str]:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=repo_root,
        check=True,
        stdout=subprocess.PIPE,
    )
    raw = result.stdout.decode("utf-8")
    files = [p for p in raw.split("\x00") if p]
    files.sort()
    return files


def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(CHUNK), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    files = tracked_files(repo_root)
    out_path = repo_root / OUTPUT_NAME

    lines: list[str] = []
    skipped: list[str] = []
    for rel in files:
        full = repo_root / rel
        if not full.is_file():
            # Submodule pointers, deleted files, symlinks to nowhere.
            skipped.append(rel)
            continue
        digest = sha256_of(full)
        lines.append(f"{digest}  {rel}")

    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {out_path} with {len(lines)} entries.")
    if skipped:
        print(f"Skipped {len(skipped)} non-regular tracked entries.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
