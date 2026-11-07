#!/usr/bin/env python3
"""Reject floating Python requirements before installing them in an image.

The deterministic Docker templates accept normal package pins such as
``numpy==1.24.3`` and pins with extras/markers. Floating specifiers, VCS URLs,
direct URLs, editable installs and unconstrained package names are rejected.
"""
from pathlib import Path
import re
import sys

PIN = re.compile(
    r"^[A-Za-z0-9][A-Za-z0-9._-]*"
    r"(?:\[[A-Za-z0-9._,-]+\])?"
    r"(?:==|===)[^\s;]+"
    r"(?:\s*;\s*.+)?$"
)


def main(path: str) -> int:
    errors = []
    for lineno, raw in enumerate(Path(path).read_text(encoding="utf-8-sig").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith(("-", "http://", "https://", "git+", ".", "/")) or not PIN.match(line):
            errors.append((lineno, line))

    if errors:
        print("ERROR: requirements.txt contains non-deterministic package specifications.", file=sys.stderr)
        print("Every package must use an exact version, for example numpy==1.24.3.", file=sys.stderr)
        print("Floating ranges, direct URLs, VCS installs and unversioned packages are not allowed.", file=sys.stderr)
        for lineno, line in errors:
            print(f"  line {lineno}: {line}", file=sys.stderr)
        return 2

    print("Requirements pin check: OK")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} REQUIREMENTS_FILE", file=sys.stderr)
        raise SystemExit(2)
    raise SystemExit(main(sys.argv[1]))
