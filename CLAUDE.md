@AGENTS.md

## Claude Code notes

Everything above is shared with Codex. Put rules for every agent in AGENTS.md, not here.

- For any task that touches more than three files, start in plan mode, write the plan, and wait for approval before editing.
- Read only the docs you need for the task. Start with the "Sources of truth" table above.
- Project skills (type them as slash commands):
  - `/plan-feature` plans a feature against the design docs, no code.
  - `/build-step` runs one prompt from docs/prompts/ end to end.
  - `/review-diff` reviews the current branch against the docs and the golden rules.
  - `/write-tests` adds GUT or pytest tests for the code you point it at.
- Skills are edited in `.agents/skills/` and copied here by `python scripts/sync_skills.py`. Do not edit `.claude/skills/` by hand.
- When the humans ask you to explain something, teach it: short explanation, a small example from this repo, then one question to check understanding.
