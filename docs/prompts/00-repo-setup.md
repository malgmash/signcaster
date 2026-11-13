# 00 Repo and project setup (M0)

| | |
| --- | --- |
| Branch | `chore/repo-setup` |
| Best with | Either agent |
| Needs | Nothing. This is the first step. |
| You do by hand first | Install Godot 4 and Python 3.11+. Clone the repo. Open it in VS Code. |

## Prompt

```text
You are setting up the Signcaster repo. Read AGENTS.md, README.md and docs/ARCHITECTURE.md (sections "Godot project layout" and "Tracker internals") before doing anything.

Goal: a fresh clone opens in Godot, CI passes, and every folder from the architecture doc exists.

Do this:
1. Create the Godot 4 project in game/ with project.godot named "Signcaster", window 1280x720, stretch mode canvas_items, aspect expand. Main scene: game/skins/debug/debug_main.tscn with a single Label that says "Signcaster debug skin".
2. Create the folders from the architecture doc: game/engine, game/skins/debug, game/skins/qb, game/skins/wizard, game/ui, game/tests. Keep empty folders with a .gitkeep file.
3. Do NOT create the engine scripts yet. That is the next milestone.
4. Create the tracker package skeleton: tracker/pyproject.toml (package name signtracker, Python >= 3.11, dependencies mediapipe, numpy, opencv-python; optional dev extras pytest, ruff), tracker/signtracker/__init__.py with __version__ = "0.1.0", and tracker/tests/test_version.py that checks the version string.
5. Add game/assets_credits.md with a table: asset, author, license, source link.
6. Check that .gitignore covers game/.godot/, tracker/models/*.task, tracker/data/, .venv/ and export builds.
7. Explain to me (do not do it yourself) how to install the GUT addon into game/addons/gut from Godot's AssetLib, since you may not be able to download it.
8. Run python scripts/validate_content.py and python scripts/sync_skills.py --check and fix anything they report.

Constraints:
- Follow the folder names in docs/ARCHITECTURE.md exactly.
- Do not add any other dependencies.

Before editing, give me a short plan (files you will create) and wait for my OK.

When done, report: files created, the exact commands I should run to check it, and anything you could not do.
```

## After the agent finishes

- [ ] Open `game/project.godot` in Godot. Press Play. You see the debug label.
- [ ] Install GUT from AssetLib (search "GUT"), enable it in Project Settings, Plugins.
- [ ] `cd tracker && pip install -e ".[dev]" && python -m pytest` passes.
- [ ] Push the branch, open a PR, CI is green.
