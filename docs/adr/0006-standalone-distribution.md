# ADR 0006: Standalone downloads with a bundled tracker

**Status:** Proposed (the work happens in M12; this becomes Accepted when M12 is merged)
**Date:** 2026-11-14

## Context

Players should go to our itch.io page, download one file for their computer (Windows or macOS), open it and play.
They should never need to install Python or type a terminal command. Read it should work right away. Sign it should work after the player allows camera access once.

ADR 0002 runs the tracker as a separate Python process, so today Sign it needs a Python install and a manual start.

Both of us build on Windows. Nobody on the team has a Mac, but players on both platforms should be able to play.

## Decision

**Packaging**
- Package the tracker with PyInstaller in `--onedir` mode. PyInstaller is a build-only dependency, in a `build` extra in `tracker/pyproject.toml`. It never ships to players.
- Bundle the MediaPipe hand landmarker `.task` file and our trained letter model inside the tracker build.
- Commit the trained letter model to git (model weights only, never recordings) so CI can bundle it. This needs a `.gitignore` change, and the file must stay under 5 MB.

**What each download contains**
- **Windows:** one `.zip` with `Signcaster.exe`, `Signcaster.pck`, a `tracker/` folder, `LICENSES/` and `README.txt`.
- **macOS (Apple Silicon):** one `Signcaster.app`, delivered as a `.zip`. The tracker goes in `Contents/Helpers/` (macOS code signing rejects programs stored in `Resources/`), and the whole app is signed ad hoc.
- Each download includes third-party license notices in `LICENSES/`: Godot, MediaPipe, OpenCV, numpy and Python.

**Where builds come from**
- **Windows:** built locally on our laptops with `scripts/build_release.py`.
- **macOS:** built only by a GitHub Actions workflow on a macOS runner, when a version tag is pushed. PyInstaller cannot build for a different operating system, so CI is the only Mac we have. The repo is public, so the runner minutes are free.
- Until an outside tester confirms it on a real Mac, the macOS build is labelled "experimental". There is no Intel Mac build for now.

**Launcher**
- `game/engine/tracker_launcher.gd` is owned by `TrackerClient`. It is not a new autoload.
- It looks for a tracker in this order:
  1. A tracker that is already running (a `hello` arrives within 2 seconds).
  2. The bundled tracker, at a fixed path relative to the game executable.
  3. `tracker/.venv`, but only in editor or debug builds.
- It never searches PATH and never uses a shell. The only arguments it passes are port numbers it has validated.
- If the tracker cannot start, the game stays in Read it and emits `sign_it_unavailable` with a reason. The skin shows a friendly message.

**Orphan safety**
- The game sends a `ping` message to the tracker every second.
- A tracker started with `--exit-when-orphaned` quits after 5 seconds without a ping. This way a crashed game never leaves the camera on.
- Both are added in M4, so the protocol is ready before packaging.

**Camera opt-in**
- The tracker does not start until the player has seen a camera explainer screen and chosen "Use my camera". This is stored as `settings.camera_consent`, which defaults to `false`.
- Choosing "Not now" means Read it only, and the camera never opens.
- On macOS, the app's `Info.plist` carries the camera usage description, so the system asks the player once.

**Release builds**
- Debug-only inputs are wrapped in `OS.is_debug_build()`.
- The release export excludes `skins/debug/` and starts on the menu.

**Not in scope**
- No auto-updater, no accounts and no network calls. The only connection stays the localhost tracker socket (ADR 0004).

## Why

- **PyInstaller** is mature and has a community hook for MediaPipe. It needs no C compiler, and builds take about a minute. `--onedir` avoids most of the antivirus false positives that `--onefile` builds get.
- **Keeping the tracker a separate process** keeps everything ADR 0002 gave us: crash isolation, a swappable tracker and the fake tracker for tests.
- **Starting the tracker only after opt-in** means the operating system's camera prompt appears right after our own explanation, never out of nowhere, and a player who says no never has the camera turned on.

## Trade-offs

- **Download size.** The estimate is 120 to 200 MB per platform, mostly MediaPipe and OpenCV. The target is under 300 MB, and the build script reports the real size.
- **Unsigned apps show warnings.** On Windows, players click "More info" then "Run anyway" at SmartScreen. On macOS 15 and later, they use System Settings, Privacy & Security, Open Anyway. Without paid Apple signing, macOS may also ask for camera permission again after each update. Removing these warnings needs a paid Apple Developer account and a Windows code signing certificate, which we will decide on later.
- **Nobody on the team can test the macOS build.** It depends on an outside tester.
- **A committed model** puts a binary file in git.

## Alternatives considered

- **Nuitka:** compiles Python to C and may trigger fewer antivirus warnings. But it needs a C compiler, builds are much slower, and MediaPipe's data files need more manual setup.
- **Asking players to install Python:** breaks the whole goal.
- **A GDExtension tracker, or moving the game to the browser:** rejected in ADR 0002 for the same reasons as before.
- **A universal macOS build with Intel support:** MediaPipe does not ship universal wheels, so this would need a second runner and a second download.
