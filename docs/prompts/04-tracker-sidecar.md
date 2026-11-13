# 04 Tracker sidecar and fake tracker (M4)

| | |
| --- | --- |
| Branch | `feat/tracker-sidecar` |
| Best with | Either agent. Codex is a good fit for a self-contained Python package. |
| Needs | M0 merged (can run in parallel with M3) |

## Prompt

```text
Build the Signcaster hand tracker sidecar and the game's TrackerClient. Follow AGENTS.md.

Read first:
- docs/TRACKER_PROTOCOL.md (all of it)
- docs/ARCHITECTURE.md: "Tracker internals", "Errors and fallbacks", "Privacy and safety"

Goal: the tracker runs, finds a hand with MediaPipe, and talks to the game over localhost UDP. A fake tracker sends scripted letters. The debug skin shows the tracker status.

Python side (tracker/signtracker/):
1. protocol.py: builders and a parser for every message in the protocol doc, plus a small UDP sender and receiver bound to 127.0.0.1. Pure functions where possible.
2. capture.py: open the webcam (index from --camera, default 0), read frames, release cleanly. Report status no_camera if it fails.
3. landmarks.py: wrap MediaPipe Hand Landmarker. The model file lives at tracker/models/hand_landmarker.task and is gitignored; if it is missing, send status model_missing and print where to download it from.
4. __main__.py: CLI with --game-port, --control-port, --camera, --show (opens a preview window with landmarks drawn, for debugging only). Send hello every 2 seconds, hand messages while a hand is visible (respect the rate limits in the protocol doc), and react to config, expect and idle messages. Letters come in M5, so do not send letter messages yet.
5. fake.py: python -m signtracker.fake --word BLUE --delay 0.6 [--loop]. Sends hello, then one letter message per letter.
6. Tests (no camera): protocol round trips, rate limiting, fake tracker message sequence. Ruff clean.

Godot side:
7. game/engine/tracker_client.gd: listen on the game port with PacketPeerUDP, parse JSON safely (ignore bad packets, never crash), track status (connected, no_hand, disconnected after 2 seconds of silence), emit tracker_status_changed, and expose send_config(), send_expect(letters), send_idle().
8. Debug skin: show tracker status and the last message type received.
9. GUT tests for TrackerClient parsing and the 2-second disconnect rule (use Clock).

Rules:
- Never send or save images or frames. Bind only to 127.0.0.1.
- No new dependencies beyond the ones in pyproject.toml.

Before editing, give me a plan and the list of files. Wait for my OK.

When done, tell me exactly how to run the real tracker and the fake tracker on Mac and on Windows, and what I should see in the debug skin.
```

## After the agent finishes

- [ ] Run the fake tracker. The debug skin says "connected". Stop it. After about 2 seconds it says "disconnected".
- [ ] Run the real tracker with `--show` on both laptops. Note the frame rate on each.
- [ ] On the Mac, allow camera access for the terminal or VS Code when macOS asks.
