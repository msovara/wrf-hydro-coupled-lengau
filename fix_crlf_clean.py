#!/usr/bin/env python3
"""Convert CRLF to LF for shell scripts. Usage: fix_crlf_clean.py [dir ...]"""
import sys
from pathlib import Path

dirs = [Path(p) for p in (sys.argv[1:] or ["."])]
for base in dirs:
    for path in sorted(base.rglob("*")):
        if path.suffix in {".sh", ".pbs", ".py"} or path.name.endswith(".pbs"):
            data = path.read_bytes()
            fixed = data.replace(b"\r\n", b"\n").replace(b"\r", b"\n")
            if fixed != data:
                path.write_bytes(fixed)
                print(f"fixed {path}")
