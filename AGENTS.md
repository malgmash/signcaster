# AGENTS.md

Instructions for AI coding agents (Codex, Claude Code and others) working in this repo.
Humans should read README.md and CONTRIBUTING.md first.

## What this project is

Signcaster is a game that teaches sign language (ASL fingerspelling and everyday signs) under time pressure.
One shared engine runs two skins:

- QB mode (teens and adults): study the play call in the huddle, recall it while the defense rushes.
- Wizard mode (kids): study the spell in the spellbook, recall it before the monster arrives.

Every challenge has a direction:

- Sign it: the bubble shows a word, the player signs it to the webcam.
- Read it: the bubble shows signs, the player types the word.

## Sources of truth (read the relevant one before changing code)

| Topic | File |
| --- | --- |
| What the game is and how it should feel | docs/GAME_DESIGN.md |
| System design, modules, algorithms | docs/ARCHITECTURE.md |
| Event bus signals (the engine to skin contract) | docs/EVENTS.md |
| JSON content and save formats | docs/DATA_FORMATS.md |
| Game to tracker messages | docs/TRACKER_PROTOCOL.md |
| Milestones and order of work | docs/ROADMAP.md |
| Why we made big decisions | docs/adr/ |

If code and docs disagree, stop and ask which one is right. Do not silently pick one.

## Repo map

```
game/            Godot 4 project (open game/project.godot)
  engine/        Shared engine autoloads. No art, no skin code here.
  skins/menu/    Main menu and mode select
  skins/debug/   Minimal test skin
  skins/qb/      QB mode scenes, scripts, assets
  skins/wizard/  Wizard mode scenes, scripts, assets
  ui/            Shared, themeable widgets (memory bubble, timer bar, sign card, coin counter)
  content/       JSON word packs, store catalogs, difficulty config
  tests/         GUT unit tests for the engine
tracker/         Python hand tracking sidecar (MediaPipe), sends results to the game over localhost UDP
scripts/         Repo tools (content validator, skills sync)
docs/            Design docs, ADRs, prompt pack
.agents/skills/  Shared agent skills (source of truth). Mirrored to .claude/skills/ by scripts/sync_skills.py
```

## Commands

Run these from the repo root. If a command does not exist yet, say so instead of inventing output.

| Task | Command |
| --- | --- |
| Validate content JSON | `python scripts/validate_content.py` |
| Sync agent skills | `python scripts/sync_skills.py` |
| Engine unit tests (GUT, headless) | `godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` |
| GDScript lint and format check | `gdlint game/engine game/skins game/ui` and `gdformat --check game/engine game/skins game/ui` |
| Tracker tests | `cd tracker && python -m pytest` |
| Tracker lint | `cd tracker && ruff check .` |
| Run the tracker | `cd tracker && python -m signtracker` |
| Fake tracker (no webcam) | `cd tracker && python -m signtracker.fake --word BLUE` |

The Godot executable may be named `godot`, `godot4` or a full path on each laptop. Ask if it is not on PATH.

## Golden rules

1. Engine and skins stay separate. Code in `game/engine/` never references a skin, a scene in `skins/`, or any art.
   Skins only listen to EventBus signals and call the public methods on the `Game` autoload.
2. EventBus signals are a contract. Adding, renaming or changing arguments of a signal means updating docs/EVENTS.md in the same change.
3. Content lives in JSON under `game/content/`. No hardcoded word lists, prices or difficulty numbers in code.
   Run `python scripts/validate_content.py` after any content change.
4. Privacy. Webcam frames never leave the tracker process. Never write frames to disk, never open a network connection other than localhost, never add analytics. Wizard mode stores nothing personal.
5. Sign accuracy. Never invent how a sign is made. Do not write handshape descriptions or generate sign art on your own.
   Any change to sign content gets the label `needs-asl-review` and must be checked by a human with Deaf ASL signers.
6. Cosmetic-only store. Store items never change difficulty, timers or scoring. No real-money purchases anywhere.
7. Small steps. One feature per branch. For changes touching more than three files, write a short plan first and wait for approval.
8. Tests come with logic. Any new engine logic (scoring, difficulty, word selection, economy) gets GUT tests. Any tracker logic gets pytest tests.
   Inject time and randomness so tests are deterministic.
9. No new dependencies (Godot addons, pip packages) without asking first and recording why in the PR.

## GDScript style

- Godot 4, static typing everywhere: `var speed: float = 1.0`, `func score(ratio: float) -> int:`.
- snake_case for files, functions and variables. PascalCase for `class_name`. UPPER_SNAKE_CASE for constants.
- Signals are named in the past tense (`challenge_succeeded`, `coins_changed`).
- One responsibility per script. Keep functions short. Prefer early returns.
- No magic numbers. Tunable numbers come from `game/content/config/*.json` through the Config autoload.
- Comments explain why, not what. Every public function in `engine/` has a one-line doc comment (`##`).

## Python style (tracker)

- Python 3.11+, type hints on all functions, `ruff` for lint, `pytest` for tests.
- Keep MediaPipe and camera code thin. Put math (normalizing landmarks, features, smoothing) in pure functions that are easy to test.
- Import MediaPipe and OpenCV inside the functions that need them, so tests and CI run without a camera.

## Git rules

- Never commit to `main` directly. Branch names: `feat/...`, `fix/...`, `docs/...`, `chore/...`, `content/...`.
- Commit messages: Conventional Commits, for example `feat(engine): add leitner word scheduling`.
- Never force push, rewrite history, or delete branches unless a human asks.
- Do not commit: `game/.godot/`, `tracker/models/*.task`, recorded datasets, `.env` files, anything over 5 MB.

## Definition of done

- The feature works when run, not just when it compiles.
- Tests pass, lint passes, content validates.
- Docs updated if a contract, format or design rule changed.
- Final message to the human: what changed, files touched, how to try it by hand, and anything left unfinished.

## Things the humans want from you

- Explain your reasoning in plain language. The humans are CS students and want to learn, not just receive code.
- When you are unsure about game feel or design, ask instead of guessing.
- No em-dashes in docs or UI text.
