# 07 Progression and difficulty (M7)

| | |
| --- | --- |
| Branch | `feat/progression-difficulty` |
| Best with | Claude Code (plan mode). Ask Codex to write extra tests afterward. |
| Needs | M6 merged |

## Prompt

```text
Add levels, difficulty and word review to Signcaster. Follow AGENTS.md.

Read first:
- docs/GAME_DESIGN.md: "Difficulty plan" (all subsections), "Stars per level"
- docs/ARCHITECTURE.md: "Picking the next challenge", "Spaced repetition", "Rubber-banding"
- docs/DATA_FORMATS.md: "Difficulty config"

Goal: a season of 4 groups plays with a clear sawtooth feel: each group ramps up to a boss level, then the next group starts a little easier than that boss. The game quietly eases off when the player struggles and tightens when they are on fire.

Do this:
1. Expand game/content/config/difficulty.json to 4 groups with 4 tiers each (the 4th is a boss with more challenges). Change only one knob per step, as the design doc says. Run the content validator.
2. difficulty.gd: resolve the current tier for a level id, apply the mode's timer_scale and default bubble, and implement rubber-banding exactly as written in the architecture doc. Emit difficulty_adjusted for the debug overlay.
3. word_bank.gd: Leitner boxes and the 70/30 new versus review mix, word length from the tier, max new words per level per mode, kid_safe filtering for wizard mode.
4. challenge_manager.gd: get tiers from Difficulty and words from WordBank. Support the bubble styles "fade" and "flash" (emit bubble_style_changed at the right time) and the "audible" twist (word_changed). Leave "decoy" as a TODO.
5. Stars per level from scoring.json, emitted with level_completed.
6. Debug skin: an overlay (toggle with F10) showing tier id, live seconds, rubber-band factor and word boxes.
7. QB skin: show drive and play numbers from the level id, a boss intro card ("Two-minute drill!"), and the audible animation (QB points and shouts the new word).
8. Tests: rubber-banding caps and resets per group, Leitner moves, due calculation, review share over many picks (seeded), one knob changes per step in the config (write a test that diffs adjacent tiers), stars thresholds.

Before editing, show me the 16 tiers you plan to put in difficulty.json as a table, so we can tune them together. Wait for my OK.

When done, report what you changed and give me a 10 minute playtest plan.
```

## After the agent finishes

- [ ] Play a full season. Does each boss feel hard but winnable? Does each new group feel fresh?
- [ ] Watch the F10 overlay while failing on purpose. Does the game ease off?
- [ ] Tune numbers in `difficulty.json`, not in code.
