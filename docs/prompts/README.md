# Prompt pack

Copy-paste prompts for building Signcaster with Claude Code and Codex in VS Code.
There is one prompt per roadmap milestone, plus reusable templates.

## How to use a milestone prompt

1. Create the GitHub issue and branch named at the top of the prompt file.
2. Open the agent panel in VS Code (Claude Code or Codex) with the repo folder open.
3. Paste everything inside the `text` box. Do not paste the notes around it.
4. The prompt asks the agent for a plan first. Read it, ask questions, then say "go".
5. When it finishes, do the "After the agent finishes" checklist yourself. Play the game.
6. Open a PR and ask the *other* agent to review it with the review skill.

Both agents already read AGENTS.md (Codex reads it directly, Claude Code through CLAUDE.md), so prompts stay short and point to the docs instead of repeating rules.

## Skills (shortcuts for common prompts)

Shared skills live in `.agents/skills/` (Codex reads this folder). `python scripts/sync_skills.py` copies them to `.claude/skills/` for Claude Code.

| Skill | Claude Code | Codex | What it does |
| --- | --- | --- | --- |
| plan-feature | `/plan-feature <what>` | `$plan-feature` then describe it | Plan only, checks the docs, no code |
| build-step | `/build-step 03` | `$build-step` with the prompt number | Runs a milestone prompt from this folder |
| review-diff | `/review-diff` | `$review-diff` | Reviews the branch against the docs and golden rules |
| write-tests | `/write-tests <file>` | `$write-tests` with the file | Adds GUT or pytest tests |

If a skill does not show up, restart the agent panel and check the folder names.

## Milestone prompts

| File | Milestone |
| --- | --- |
| [00-repo-setup.md](00-repo-setup.md) | M0 Repo and project setup |
| [01-engine-skeleton.md](01-engine-skeleton.md) | M1 Engine skeleton |
| [02-read-it-loop.md](02-read-it-loop.md) | M2 Read it loop with the debug skin |
| [03-qb-skin-v1.md](03-qb-skin-v1.md) | M3 QB skin, first drive |
| [04-tracker-sidecar.md](04-tracker-sidecar.md) | M4 Tracker sidecar and fake tracker |
| [05-letter-classifier.md](05-letter-classifier.md) | M5 Letter recording and classifier |
| [06-sign-it-integration.md](06-sign-it-integration.md) | M6 Sign it in the game |
| [07-progression-difficulty.md](07-progression-difficulty.md) | M7 Progression and difficulty |
| [08-economy-store.md](08-economy-store.md) | M8 Coins, stars and the QB store |
| [09-wizard-skin.md](09-wizard-skin.md) | M9 Wizard skin and wizard shop |
| [10-save-daily-streaks.md](10-save-daily-streaks.md) | M10 Saves, daily challenge, streaks |
| [11-polish-release.md](11-polish-release.md) | M11 Polish and release |
| [12-standalone-distribution.md](12-standalone-distribution.md) | M12 Standalone downloads (can start after M6) |

## Templates

| File | Use it to |
| --- | --- |
| [templates/feature.md](templates/feature.md) | Build any feature not covered by a milestone |
| [templates/bugfix.md](templates/bugfix.md) | Fix a bug with a failing test first |
| [templates/write-tests.md](templates/write-tests.md) | Add tests to existing code |
| [templates/review.md](templates/review.md) | Review a PR (when not using the skill) |
| [templates/refactor.md](templates/refactor.md) | Clean up code without changing behavior |
| [templates/docs-update.md](templates/docs-update.md) | Bring docs back in line with the code |
| [templates/explain-code.md](templates/explain-code.md) | Learn how a piece of the code works |
| [templates/playtest-to-issues.md](templates/playtest-to-issues.md) | Turn playtest notes into GitHub issues |

## Tips that save usage

- Point at files instead of pasting them. "Read docs/EVENTS.md" costs less than pasting it.
- One milestone per conversation. Start a fresh chat for the next one.
- If the agent goes off track, stop it early and restate the goal with the acceptance criteria.
- When you correct the same mistake twice, add a rule to AGENTS.md so both agents learn it.
- Do the design thinking yourselves. Use agents for typing, testing and checking.
