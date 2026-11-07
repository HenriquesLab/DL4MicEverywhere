#!/usr/bin/env python3
"""Compatibility wrapper for the old notebook-status table generator."""

import sys
from notebook_status import main

if __name__ == "__main__":
    if len(sys.argv) == 1:
        sys.argv.append("render")
    raise SystemExit(main())
