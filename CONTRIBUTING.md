# Contributing

This is how the two of us (and our two AI agents) work on Signcaster without stepping on each other.

## The loop for every change

1. **Issue.** Every piece of work starts as a GitHub issue. Use a template. Put it on the project board.
2. **Branch.** One issue, one branch: `feat/memory-bubble`, `fix/timer-drift`, `content/starter-pack`.
3. **Plan.** For anything bigger than a small fix, ask the agent for a plan first (`/plan-feature` in Claude Code, `$plan-feature` in Codex). Read it. Push back.
4. **Build.** Paste the matching prompt from `docs/prompts/` or use `/build-step`. Let the agent work in small steps.
5. **Try it yourself.** Run the game. Play the thing you changed. Tests passing is not the same as fun.
6. **Pull request.** Fill in the PR template. CI must be green.
7. **Cross-review.** The other human reviews, and the *other* agent reviews too (`/review-diff` or `$review-diff`). If Claude Code built it, Codex reviews it, and the other way around.
8. **Merge.** Squash and merge. Delete the branch.

## Which agent for what

These are starting suggestions. Change them once you see what works for you.

| Job | Suggested agent | Why |
| --- | --- | --- |
| Planning a feature across several files | Claude Code | Plan mode, reads the docs well |
| Building a milestone prompt | Either | Pick whoever has usage left today |
| Writing tests for existing code | Codex | Good second pair of eyes on someone else's code |
| Reviewing a pull request | The agent that did not write it | Fresh context catches more |
| Explaining code to you | Either | Use `docs/prompts/templates/explain-code.md` |

Rules:

- Never run two agents on the same branch at the same time. They will overwrite each other.
- Both agents read AGENTS.md. If you correct an agent twice about the same thing, add the rule to AGENTS.md.
- Both plans have usage limits. Do the thinking yourself, use agents for the typing and the checking.

## Branches and commits

- `main` is always playable. Never commit to it directly.
- Commit messages use Conventional Commits:
  - `feat(engine): add difficulty manager`
  - `fix(qb): bubble overlaps HUD on small windows`
  - `docs: update events table`
  - `content: add starter word pack`
  - `test(tracker): cover smoothing edge cases`

## Code review checklist

- Does it follow the golden rules in AGENTS.md (engine and skins separate, content in JSON, privacy, cosmetic-only store)?
- If a signal or data format changed, did docs/EVENTS.md or docs/DATA_FORMATS.md change too?
- Are there tests for new logic? Do they actually fail if the logic breaks?
- Can you explain every line? If not, ask before approving.

## Sign content

Anything that shows or describes how a sign is made uses the "Sign content review" issue template and gets the
`needs-asl-review` label. It does not ship until a Deaf ASL signer has checked it.

## Assets

- Only add art, sound and fonts we made ourselves or that have a license allowing use in a game. Record the source and license in `game/assets_credits.md`.
- No team logos, league names or real players. Our football league is made up.
- Keep files under 5 MB. Large binaries need a discussion first (Git LFS).
