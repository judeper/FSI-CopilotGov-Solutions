#!/usr/bin/env python3
"""Shared traceability constants and helpers."""

from __future__ import annotations

import re

FRAMEWORK_REPO_OWNER = "judeper"
FRAMEWORK_REPO_NAME = "FSI-CopilotGov"
FRAMEWORK_REPO_REF = "e0fb7b769529dcc008cc2066402cdabae4f369cf"
FRAMEWORK_REPO_URL = f"https://github.com/{FRAMEWORK_REPO_OWNER}/{FRAMEWORK_REPO_NAME}"
FRAMEWORK_SITE_URL = f"https://{FRAMEWORK_REPO_OWNER}.github.io/{FRAMEWORK_REPO_NAME}"
FRAMEWORK_BLOB_ROOT = f"{FRAMEWORK_REPO_URL}/blob/{FRAMEWORK_REPO_REF}"

UNPINNED_FRAMEWORK_REF_RE = re.compile(
    rf"{re.escape(FRAMEWORK_REPO_URL)}/(?:blob|tree)/(?:main|master)\b"
)
FRAMEWORK_ID_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


def normalize_traceability_token(value: str) -> str:
    """Normalize a human-readable framework token for lookups."""
    return re.sub(r"\s+", " ", value.strip()).casefold()
