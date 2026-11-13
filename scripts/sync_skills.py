"""Copy shared agent skills from .agents/skills (read by Codex) to .claude/skills (read by Claude Code).

Usage:
    python scripts/sync_skills.py          copy and report
    python scripts/sync_skills.py --check  exit 1 if the copies are out of date (used in CI)

Edit skills only in .agents/skills. The .claude/skills copy is generated.
"""
from __future__ import annotations

import argparse
import filecmp
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / ".agents" / "skills"
DST = ROOT / ".claude" / "skills"
NOTICE = "<!-- Generated from .agents/skills by scripts/sync_skills.py. Edit the source, not this copy. -->\n"


def expected_files() -> dict[Path, bytes]:
    files: dict[Path, bytes] = {}
    for path in sorted(SRC.rglob("*")):
        if path.is_dir():
            continue
        rel = path.relative_to(SRC)
        data = path.read_bytes()
        if path.name == "SKILL.md":
            text = data.decode("utf-8")
            # keep YAML frontmatter first, put the notice right after it
            if text.startswith("---"):
                end = text.find("\n---", 3)
                if end != -1:
                    end = text.find("\n", end + 1) + 1
                    text = text[:end] + NOTICE + text[end:]
            data = text.encode("utf-8")
        files[rel] = data
    return files


def check() -> int:
    want = expected_files()
    problems: list[str] = []
    for rel, data in want.items():
        target = DST / rel
        if not target.exists():
            problems.append(f"missing: .claude/skills/{rel}")
        elif target.read_bytes() != data:
            problems.append(f"out of date: .claude/skills/{rel}")
    if DST.exists():
        for path in DST.rglob("*"):
            if path.is_file() and path.relative_to(DST) not in want:
                problems.append(f"extra (no source): .claude/skills/{path.relative_to(DST)}")
    for p in problems:
        print(p)
    if problems:
        print("Run: python scripts/sync_skills.py")
        return 1
    print(f"Skills in sync ({len(want)} files).")
    return 0


def sync() -> int:
    want = expected_files()
    if DST.exists():
        shutil.rmtree(DST)
    for rel, data in want.items():
        target = DST / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    print(f"Copied {len(want)} files from .agents/skills to .claude/skills.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true", help="only check, do not copy")
    args = parser.parse_args()
    if not SRC.exists():
        print("No .agents/skills folder found.")
        return 1
    return check() if args.check else sync()


if __name__ == "__main__":
    sys.exit(main())
