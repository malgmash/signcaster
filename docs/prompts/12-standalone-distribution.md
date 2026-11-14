# 12 Standalone downloads (M12)

| | |
| --- | --- |
| Branch | several small branches, one per PR listed in the prompt |
| Best with | Claude Code in plan mode (many files). Split the PRs between both agents, never two agents on one branch. |
| Needs | M6 merged (a working tracker, a trained letter model and Sign it in the game). It can run alongside M7 to M10. |
| You do by hand first | Install the Godot 4.7.2 export templates (Editor, Manage Export Templates). Find a friend with an Apple Silicon Mac who can test a build. |

This milestone replaces sections B and E of `11-polish-release.md`. The decisions behind it are in `docs/adr/0006-standalone-distribution.md`.

## Prompt

```text
Make Signcaster easy to download and play: one download per platform, no Python, no setup. Follow AGENTS.md.

Read first:
- docs/adr/0006-standalone-distribution.md (the decisions for this milestone, all approved)
- docs/ARCHITECTURE.md ("Tracker internals", "Platform notes", "Errors and fallbacks", "Privacy and safety")
- docs/adr/0002-python-tracker-sidecar.md
- docs/TRACKER_PROTOCOL.md (check that the ping message and --exit-when-orphaned from M4 exist)
- docs/ROADMAP.md

Goal: a player goes to our itch.io page, downloads one file for their computer (Windows, or macOS on Apple Silicon), opens it, and plays. Read it works right away. Sign it works after they allow camera access once. They never install Python or run a terminal command.

Both of us build on Windows and nobody on the team has a Mac. Windows releases are built locally. The macOS release is built only by GitHub Actions.

Do this, as separate PRs in this order:
1. Tracker packaging: add PyInstaller (already approved, in a "build" extra) and a spec file for a --onedir build that includes the MediaPipe .task model and our trained letter model. Commit the letter model (weights only) and update .gitignore. Load bundled files through a helper that works both in the venv and in the frozen build.
2. Launcher: game/engine/tracker_launcher.gd, owned by TrackerClient, following the search order and rules in ADR 0006. Stop the tracker when the game quits. If it cannot start, stay in Read it and show a friendly message, not an error. Explain the security considerations of launching a process.
3. Camera opt-in: a short screen in the menu skin that explains why we need the camera and that video never leaves the computer, with "Use my camera" and "Not now". The tracker starts only after "Use my camera". Save settings.camera_consent through SaveSystem. On macOS, set the camera usage description in the export preset.
4. Export presets and build script: Godot export presets for Windows and macOS (Apple Silicon). Release exports exclude skins/debug and start on the menu. Debug-only inputs are removed from release builds. scripts/build_release.py runs the content validator, a check that every shipped sign is "reviewed" (with a --test-build flag that allows placeholder content), GUT, pytest and ruff. It then builds the tracker, exports the game, assembles the folders from ADR 0006, signs the macOS app ad hoc, and writes zips to build/release/ with their sizes.
5. Release workflow: .github/workflows/release.yml builds on windows-latest and macos-latest when a v* tag is pushed, and attaches both zips to a GitHub Release. Never upload to itch.io.
6. Docs: mark ADR 0006 Accepted and add the real download sizes. Update ARCHITECTURE.md ("Platform notes", "Tracker internals", "Errors and fallbacks"), EVENTS.md (sign_it_unavailable reasons) and DATA_FORMATS.md (camera_consent). Add docs/RELEASE.md with a player install guide (the Windows SmartScreen warning, and Open Anyway on macOS 15 and later), a maintainer release checklist and a checklist for the Mac tester. Tick M12 in ROADMAP.md.

Rules:
- Keep all privacy rules: the tracker binds to 127.0.0.1 only and never saves or sends video.
- No auto-updater, accounts or network calls.
- Download size target: under 300 MB per platform. Report the real size.

Before editing each PR, give me a plan (files, folder layout inside each download, anything I must do by hand) and wait for my OK.

When done, tell me exactly how to build a Windows release on our HP laptops, how to trigger the macOS build in GitHub Actions, and how a player installs each one.
```

## After the agent finishes

- [ ] On a Windows laptop that has never had Python or the repo, download the zip from the GitHub Release, unzip it, and play Read it.
- [ ] Choose "Use my camera" and finish a Sign it challenge. Then quit the game and check that the tracker process is gone (Task Manager).
- [ ] Force-close the game (Task Manager, End task) and check that the tracker exits on its own within a few seconds.
- [ ] Send the macOS zip to the Mac tester with the checklist from RELEASE.md.
- [ ] Both downloads are under 300 MB.
