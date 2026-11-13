---
name: review-diff
description: Review the current Signcaster branch against main using the project docs and golden rules. Use when the user asks for a review, a second opinion, or a check before opening or merging a pull request. Reports findings only, never edits files.
---
<!-- Generated from .agents/skills by scripts/sync_skills.py. Edit the source, not this copy. -->

# Review the branch

Do not edit files. Report only.

1. Get the changes: `git diff main...HEAD` and `git log main..HEAD --oneline`. If there is no main branch locally, ask which base branch to use.
2. Read AGENTS.md golden rules and the docs that match the changed files (engine changes: ARCHITECTURE.md and EVENTS.md; content changes: DATA_FORMATS.md; tracker changes: TRACKER_PROTOCOL.md).
3. Check, in order:
   1. Correctness: logic bugs, off-by-one, timer and state machine mistakes, missing null checks, error handling.
   2. Golden rules: engine never references skins or ui, EventBus changes are reflected in docs/EVENTS.md, numbers live in content JSON, privacy (no frames saved or sent, localhost only), cosmetic-only store, no invented sign descriptions.
   3. Tests: new logic has tests, and the tests would fail if the logic broke. Time and randomness are controlled.
   4. Docs: any changed contract or format is documented.
   5. Performance on an Intel laptop with integrated graphics: per-frame allocations, heavy loops, too many particles.
   6. Readability for two CS students.
4. If you can run tests and lint without changing files, run them and include the results.
5. Output a numbered list of findings, most serious first. Each finding: file and line, the problem, why it matters, a suggested fix. Label each as must fix, should fix, or nit.
6. End with a one-line verdict: ready to merge, merge after fixes, or needs another pass.
