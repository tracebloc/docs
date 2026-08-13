#!/usr/bin/env python3
"""Validate every documented `pip install "tracebloc[...]"` line against PyPI.

Why this exists (backend#1858)
------------------------------
`tools-help/tracebloc.mdx` documented `tracebloc[boosting]` and
`tracebloc[survival]` for eight published releases after both extras were
removed in 0.10.0. Nothing caught it, because this is the one class of docs
error that no docs tool can see:

  * Mintlify validates links and MDX. A fenced code block is opaque to it.
  * `pip` does NOT fail on an unknown extra. It prints
    "WARNING: tracebloc X does not provide the extra 'boosting'", installs
    the core package, and exits 0. The user's build appears to succeed and
    then dies later as an ImportError, far from the command that caused it.

So a wrong extra in the docs silently mis-installs software. This script
closes that gap by resolving each documented extra against the published
`Provides-Extra` metadata for the version the documented floor selects.

It also checks the version floor itself, because the floor is what made the
original bug silent: `>=0.8.1` floats forward to a release that no longer has
the extras, while still being satisfiable by an ancient release on an old
Python.

Usage:
    python3 scripts/check-sdk-extras.py            # scan the repo
    python3 scripts/check-sdk-extras.py FILE...    # scan specific files

Exits 0 if every documented extra exists, 1 otherwise. Requires network
access to pypi.org.
"""

from __future__ import annotations

import json
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

PACKAGE = "tracebloc"
PYPI_URL = f"https://pypi.org/pypi/{PACKAGE}/json"

# Matches: tracebloc[a,b]>=1.2.3  /  tracebloc[a]  /  tracebloc[a]==1.2.3
# Captures the extras list and, when present, the version specifier.
SPEC_RE = re.compile(
    r"\b" + PACKAGE + r"\[([^\]]+)\]\s*(?:(==|>=|~=|>)\s*([0-9][0-9A-Za-z.*+!-]*))?"
)

DOC_SUFFIXES = {".mdx", ".md"}
SKIP_DIRS = {".git", "node_modules", ".venv", "images"}


def fetch_metadata() -> dict:
    try:
        with urllib.request.urlopen(PYPI_URL, timeout=30) as resp:
            return json.load(resp)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        sys.exit(f"error: could not read {PYPI_URL}: {exc}")


def parse_version(value: str) -> tuple:
    """Coarse numeric version key. Good enough to order this package's tags."""
    parts = []
    for chunk in value.split("."):
        digits = re.match(r"\d+", chunk)
        parts.append(int(digits.group()) if digits else 0)
    return tuple(parts)


def resolve_version(floor: str | None, operator: str | None, releases: list[str]) -> str:
    """Which published version does this documented specifier actually select?

    `pip` picks the NEWEST version satisfying the specifier, so that — not the
    floor itself — is the version whose extras the reader ends up with.
    """
    if floor is None:
        return max(releases, key=parse_version)
    if operator == "==":
        return floor
    candidates = [r for r in releases if parse_version(r) >= parse_version(floor)]
    if not candidates:
        return floor
    return max(candidates, key=parse_version)


def iter_doc_files(roots: list[str]) -> list[Path]:
    if roots:
        return [Path(r) for r in roots]
    found: list[Path] = []
    for path in Path(".").rglob("*"):
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        if path.is_file() and path.suffix in DOC_SUFFIXES:
            found.append(path)
    return sorted(found)


def main(argv: list[str]) -> int:
    meta = fetch_metadata()
    releases = sorted(meta["releases"].keys(), key=parse_version)
    latest = meta["info"]["version"]

    # Provides-Extra per version needs a per-version fetch; cache it.
    extras_cache: dict[str, set[str]] = {
        latest: set(meta["info"].get("provides_extra") or [])
    }

    def extras_for(version: str) -> set[str] | None:
        if version in extras_cache:
            return extras_cache[version]
        url = f"https://pypi.org/pypi/{PACKAGE}/{version}/json"
        try:
            with urllib.request.urlopen(url, timeout=30) as resp:
                data = json.load(resp)
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
            extras_cache[version] = None
            return None
        extras_cache[version] = set(data["info"].get("provides_extra") or [])
        return extras_cache[version]

    failures: list[str] = []
    checked = 0

    for path in iter_doc_files(argv):
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue

        for lineno, line in enumerate(text.splitlines(), start=1):
            for match in SPEC_RE.finditer(line):
                extras_raw, operator, floor = match.groups()
                extras = [e.strip() for e in extras_raw.split(",") if e.strip()]
                checked += 1

                if floor is not None and floor not in releases:
                    failures.append(
                        f"{path}:{lineno}: version {floor} is not published on PyPI"
                    )
                    continue

                version = resolve_version(floor, operator, releases)
                available = extras_for(version)
                if available is None:
                    failures.append(
                        f"{path}:{lineno}: could not read metadata for {PACKAGE} {version}"
                    )
                    continue

                for extra in extras:
                    if extra not in available:
                        failures.append(
                            f"{path}:{lineno}: {PACKAGE}[{extra}] does not exist in "
                            f"{version} (the version '{operator or ''}{floor or 'latest'}' "
                            f"resolves to). Available: {', '.join(sorted(available))}"
                        )

    print(f"Checked {checked} documented '{PACKAGE}[...]' spec(s); latest release is {latest}.")

    if failures:
        print(f"\n{len(failures)} problem(s) found:\n", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        print(
            "\nNote: pip warns and exits 0 on an unknown extra, so a wrong extra here "
            "silently installs the core SDK only.",
            file=sys.stderr,
        )
        return 1

    print("All documented extras exist in the versions they resolve to.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
