---
name: write-tests
description: Add GUT tests for Signcaster game code or pytest tests for tracker code, without changing the code under test. Use when the user asks for tests, more coverage, or to check an edge case.
---
<!-- Generated from .agents/skills by scripts/sync_skills.py. Edit the source, not this copy. -->

# Write tests

1. Identify the target from the user's message (a file, function or feature). If unclear, ask.
2. Use GUT in game/tests/ for anything under game/, and pytest in tracker/tests/ for anything under tracker/. Follow the naming of existing test files.
3. Make tests deterministic: use the Clock autoload for time and a seeded RandomNumberGenerator for randomness in Godot; use fixed inputs in Python. No webcam and no network in tests.
4. Cover the normal case, exact boundaries (thresholds, caps, empty inputs), error cases, and anything the docs promise (docs/GAME_DESIGN.md numbers, docs/EVENTS.md signal order).
5. Do not change the code under test. If a test exposes a bug, keep the failing test, mark it clearly, and report the bug instead of fixing it.
6. Run the tests and report: each new test in one line, results, and cases you think are still untested.
