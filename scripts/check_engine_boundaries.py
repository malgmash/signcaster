"""Fail if engine code references skins or shared UI (see docs/ARCHITECTURE.md, Dependency rules).

Usage: python scripts/check_engine_boundaries.py
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENGINE = ROOT / "game" / "engine"
FORBIDDEN = ("res://skins/", "res://ui/")


def main() -> int:
    if not ENGINE.exists():
        print("game/engine does not exist yet, nothing to check.")
        return 0
    problems = []
    for path in sorted(ENGINE.rglob("*")):
        if path.suffix not in {".gd", ".tscn", ".tres"}:
            continue
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            for bad in FORBIDDEN:
                if bad in line:
                    problems.append(f"{path.relative_to(ROOT)}:{number}: engine must not reference {bad}")
    for p in problems:
        print(p)
    if problems:
        return 1
    print("Engine boundaries OK.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
