# Signcaster

Learn sign language under pressure. One game, two worlds.

Signcaster teaches ASL fingerspelling and everyday signs through short, high-pressure rounds.
You study a word, then recall it while time runs out, either by **signing it to your webcam** (Sign it)
or by **reading signs and typing the word** (Read it).

| | QB mode | Wizard mode |
| --- | --- | --- |
| For | Teens and adults | Kids |
| Study | The huddle shows the play call | The spellbook shows the spell |
| Pressure | The defense rushes the QB | A monster walks toward the wizard |
| Miss | Sacked | The monster gets you (cartoon style) |
| Store | Locker room | Wizard shop |

Both modes run on one shared engine. See [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

> Status: pre-alpha. Follow [docs/ROADMAP.md](docs/ROADMAP.md) for what is built and what is next.

## Quick start

### Tools (all free)

- [Godot 4](https://godotengine.org/download) (latest stable, standard build, GDScript)
- Python 3.11 or newer (check MediaPipe's supported versions before upgrading)
- Git and a GitHub account
- VS Code with these extensions:
  - `godot-tools` (GDScript language server and debugger)
  - Python (Microsoft)
  - Claude Code (sign in with a Claude Pro or Max plan)
  - Codex (sign in with a ChatGPT account; usage limits depend on the plan)

### Run the game

1. Open Godot, choose Import, and select `game/project.godot`.
2. Press Play. Read it mode works with no webcam.

### Run the hand tracker (for Sign it)

```bash
cd tracker
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -e ".[dev]"
python -m signtracker            # real webcam
python -m signtracker.fake --word BLUE   # scripted letters, no webcam
```

The tracker talks to the game over localhost only. Video never leaves your computer.
See [docs/TRACKER_PROTOCOL.md](docs/TRACKER_PROTOCOL.md).

## How we build with AI

We use **Claude Code** and **Codex** inside VS Code.

- Shared instructions for both agents live in [AGENTS.md](AGENTS.md). [CLAUDE.md](CLAUDE.md) imports it and adds Claude-only notes.
- Step-by-step build prompts live in [docs/prompts/](docs/prompts/README.md). Each one is a milestone from the roadmap.
- Shared agent skills live in `.agents/skills/` (Codex reads this folder) and are mirrored to `.claude/skills/` for Claude Code with `python scripts/sync_skills.py`.
- One agent builds, the other agent reviews. Humans approve every merge. Details in [CONTRIBUTING.md](CONTRIBUTING.md).

## Repo map

```
game/        Godot project: engine/, skins/, ui/, content/, tests/
tracker/     Python hand tracking sidecar
scripts/     Content validator, skills sync
docs/        Game design, architecture, events, data formats, protocol, roadmap, ADRs, prompts
.agents/     Shared agent skills
.claude/     Claude Code copy of the skills (generated)
.github/     Issue and PR templates, CI
```

## Accuracy and respect

ASL is a full language with its own grammar. Signcaster teaches vocabulary and fingerspelling, not fluency.
All sign art in this repo starts as placeholder art. Final sign content must be made or checked by Deaf ASL signers
before release. Use the "Sign content review" issue template for anything that shows how a sign is made.

## Team

- Malama
- Mustapha

## License

To be decided before the first public release. Third-party assets and datasets keep their own licenses.
