# 01 Engine skeleton (M1)

| | |
| --- | --- |
| Branch | `feat/engine-skeleton` |
| Best with | Claude Code in plan mode (many files). Codex works too. |
| Needs | M0 merged, GUT installed |

## Prompt

```text
Build the Signcaster engine skeleton. Follow AGENTS.md.

Read first:
- docs/ARCHITECTURE.md: "Godot project layout", "Autoload order", "Dependency rules"
- docs/EVENTS.md (all of it)
- docs/DATA_FORMATS.md: "Content files" and the three config files

Goal: every engine autoload exists with typed stubs, EventBus has every signal from EVENTS.md, Config loads the JSON content, and tests run headless.

Do this:
1. Create every script listed under game/engine/ in the architecture doc. Register them as autoloads in project.godot in the exact order from "Autoload order".
2. event_bus.gd: declare every signal from docs/EVENTS.md with typed arguments. No logic.
3. clock.gd: a small class with now() -> float and a way for tests to set fake time (set_fake_time, advance). Engine code must use Clock instead of Time directly.
4. config.gd: load every file in game/content/ (word packs, store catalogs, config files) into typed getters, for example get_scoring() -> Dictionary, get_word_packs() -> Array. Push a clear error if a file is missing or has the wrong version.
5. All other autoloads: class doc comment, the public functions they will need with typed signatures and `pass` or a TODO comment pointing at the milestone that fills them in. game.gd gets every public method listed in EVENTS.md under "Public methods on Game".
6. Tests in game/tests/: one test file per autoload. For now: EventBus has every signal named in EVENTS.md (parse the markdown table or keep a list in the test), Config loads the starter content, Clock fake time works.
7. Make sure python scripts/check_engine_boundaries.py passes. Then add a job to .github/workflows/ci.yml (see the comment at the bottom of that file) that downloads the exact Godot version we use (ask me which one) and runs GUT headless.

Constraints:
- Static typing everywhere. Past-tense signal names. No logic beyond what is listed.
- Do not create any skin scenes.

Before editing, give me a plan: files, autoload order, and how you will test that every signal exists. Wait for my OK.

When done, run the GUT command and the boundary check from AGENTS.md and report the results, the files you created, and anything that differs from the docs.
```

## After the agent finishes

- [ ] Open the project. No errors in the Output panel on start.
- [ ] Run GUT from the editor and headless. All green.
- [ ] Read `event_bus.gd` side by side with EVENTS.md. Same names, same arguments.
- [ ] Learn it: use `templates/explain-code.md` on `game/engine/config.gd`.
