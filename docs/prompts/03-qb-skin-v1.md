# 03 QB skin, first drive (M3)

| | |
| --- | --- |
| Branch | `feat/qb-skin-v1` |
| Best with | Claude Code for the plan, either agent for scenes |
| Needs | M2 merged. Some placeholder art (simple shapes are fine). |

## Prompt

```text
Build the first version of the QB skin for Signcaster. Follow AGENTS.md.

Read first:
- docs/GAME_DESIGN.md: "Modes" (QB column), "Core loop", "Grades and scoring"
- docs/ARCHITECTURE.md: "Skins", "Dependency rules"
- docs/EVENTS.md

Goal: one full drive of 4 plays is playable in QB mode and feels like football, using only EventBus signals and the Game facade. Placeholder art is fine.

Scenes to build under game/skins/qb/:
1. qb_main.tscn: root script connects to EventBus and switches between the views below.
2. Huddle view (on study_started): QB and teammates in a huddle, a speech bubble with the play call ("Blue 42, on two!" style text built from the word), and a play card showing the word large plus a row of sign cards (use game/ui/sign_card.tscn). A "Ready" button calls Game.skip_study().
3. Snap view (on live_started): field seen from behind the QB, linemen and rushing defenders moving toward the QB as remaining_ratio drops, and a pocket timer bar.
4. Memory bubble: a reusable widget at game/ui/memory_bubble.tscn that can show either a word or a row of sign cards, with styles "stay", "fade" and "flash" (bubble_style_changed switches style). The QB skin places it over the QB's head.
5. Letter slots under the bubble showing accepted letters (letter_accepted) and a short shake on letter_rejected.
6. Outcomes: on challenge_succeeded show a touchdown or gain animation based on grade; on challenge_failed show a sack, a near-miss line ("1 letter away!" when letters_total - letters_correct == 1) and a Retry button that calls Game.retry().
7. HUD: "Drive 1  Play 2 of 4" and the points total.
8. Main menu (game/skins/menu/): pick QB mode (Wizard button disabled for now). Make it the main scene; keep the debug skin reachable from a hidden key (F9).

Rules:
- Our league is made up. No real team names, logos or players.
- Sign cards use placeholder art only. Do not draw or describe real handshapes.
- Animation with Tweens and AnimationPlayer, no new addons.
- Keep particle effects light so it runs at 60 fps on Intel integrated graphics.

Before editing, give me a plan: scene tree for each view, which signal drives each animation, and what placeholder art you need from me. Wait for my OK.

When done, list the scenes, tell me how to play the drive, and list anything that felt like it needed an engine change (do not change the engine without asking).
```

## After the agent finishes

- [ ] Both of you play the drive. Write down three things that felt bad.
- [ ] Turn those notes into issues with `templates/playtest-to-issues.md`.
- [ ] Check the frame rate on the HP Envy (Debug, Monitors, FPS).
