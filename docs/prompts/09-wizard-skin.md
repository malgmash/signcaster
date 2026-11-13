# 09 Wizard skin and wizard shop (M9)

| | |
| --- | --- |
| Branch | `feat/wizard-skin` |
| Best with | Either agent. This is mostly scene and animation work. |
| Needs | M8 merged. Placeholder wizard, monster and shop art. |

## Prompt

```text
Build Wizard mode for Signcaster, for kids, on the same engine. Follow AGENTS.md.

Read first:
- docs/GAME_DESIGN.md: "Modes" (Wizard column), "Kids rules (Wizard mode)", "Accessibility"
- docs/ARCHITECTURE.md: "Skins", "Dependency rules"
- docs/EVENTS.md
- game/skins/qb/ to see how the QB skin reacts to each signal

Goal: a full path of waves is playable in Wizard mode, with the wizard shop, using the same engine. The engine should not need changes. If it truly does, stop and ask me first.

Scenes under game/skins/wizard/:
1. wizard_main.tscn: root script connected to EventBus, like qb_main.
2. Spellbook view (on study_started): the wizard holding a big open book showing today's spell word and its sign cards. Untimed for kids (study_seconds is 0 in wizard config), "I'm ready!" button.
3. Path view (on live_started): the monster walks along a stone path toward the wizard as remaining_ratio drops. Memory bubble over the wizard's head (reuse game/ui/memory_bubble.tscn with a wizard theme).
4. Success: spell sparkles fly to the monster, monster poofs into stars, combo counter.
5. Fail: silly, never scary (the monster burps a cloud of glitter and the wizard's hat flies off), then Retry.
6. Boss monster for the last wave of each path.
7. Wizard shop: same Store autoload, wizard catalog, item preview on the wizard.
8. Main menu: enable the Wizard mode button.

Kid rules:
- Big text and buttons, bright colors, short words only (the engine filters with kid_safe and max word length).
- No timers on study, slower monster (timer_scale in config), bubble stays.
- Nothing scary, no losing coins, no real money anywhere.

Before editing, give me the scene tree and a table of each EventBus signal with the wizard animation it triggers. Wait for my OK.

When done, list any engine changes you needed (there should be none) and how to play a path.
```

## After the agent finishes

- [ ] Let a kid play it if you can (with their parent's OK). Watch, do not help. Write down where they got stuck.
- [ ] Confirm no engine files changed: `git diff main --stat -- game/engine`.
