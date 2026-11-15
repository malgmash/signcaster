# Tracker protocol

The hand tracker (`tracker/`, Python package `signtracker`) runs as a separate process next to the game.
They talk over UDP on localhost using one JSON object per datagram. Nothing leaves the computer.

```
tracker  --(UDP 127.0.0.1:47800)-->  game   (results)
game     --(UDP 127.0.0.1:47801)-->  tracker (control)
```

Ports are configurable (`settings.tracker_port` in the save file, `--game-port` and `--control-port` on the tracker).

## Rules

- Bind to `127.0.0.1` only. Never `0.0.0.0`.
- Never send images, video frames or raw camera data. Only landmarks, letters and status.
- Every message has `"v": 1` (protocol version) and `"type"`.
- Messages are small (under 2 KB). The tracker sends at most 30 messages per second.
- If the game hears nothing for 2 seconds, it sets tracker status to `"disconnected"`.
- Each side uses one socket to listen and a separate one to send. On Windows, a UDP socket that sent to a closed port reports an error on its next receive, so mixing the two jobs breaks listening while the other side is not running yet.

## Tracker to game

### hello (on start, then every second as a heartbeat)

The heartbeat is half the game's 2 second silence limit, so one late packet never looks like a disconnect.

```json
{ "v": 1, "type": "hello", "tracker": "mediapipe", "version": "0.1.0", "fps": 30 }
```

`tracker` is `"mediapipe"`, `"apple_vision"` or `"fake"`.

### hand (every processed frame while a hand is visible)

```json
{ "v": 1, "type": "hand", "t": 1731430000.123, "handedness": "Right", "present": true, "landmarks": [[0.51, 0.62, -0.01], "... 21 points total"] }
```

- `landmarks` is optional (only sent when the game asks for it with `debug_landmarks`). 21 points, each `[x, y, z]`, x and y normalized 0 to 1.
- When no hand is visible, send `{ "v": 1, "type": "hand", "present": false }` at most 5 times per second.

### letter (when the smoother accepts a letter)

```json
{ "v": 1, "type": "letter", "t": 1731430000.456, "letter": "B", "confidence": 0.93, "hold_frames": 6 }
```

- Sent once per accepted letter. The tracker will not send the same letter again until it sees another letter or no hand for `release_frames` frames in a row (from `config`, default 4).
- Letters are uppercase A to Z.
- Double letters (the OO in MOON) are not detected yet: the shape does not change, so the release rule never fires. Planned for M6.

### status (when something changes)

```json
{ "v": 1, "type": "status", "status": "no_camera", "detail": "Camera index 0 could not be opened" }
```

`status` is one of `"ok"`, `"no_camera"`, `"model_missing"`, `"low_light"`, `"error"`.

- While a problem lasts, the tracker repeats its `status` just before each `hello`, so a game that starts later still learns about it, and never shows "connected" for a moment first.
- The game treats any status other than `"ok"` as `"disconnected"`: the tracker is alive, but Sign it cannot work.
- `model_missing` covers both model files: the MediaPipe hand model and the trained letter model (`models/letters.npz`). Without a letter model the camera still runs, so `--show` can check the hand dots, but no letters are sent.

## Game to tracker

### config (on connect and when settings change)

```json
{ "v": 1, "type": "config", "mirror": false, "debug_landmarks": false, "min_confidence": 0.8, "hold_frames": 6, "release_frames": 4 }
```

A field with a bad value (text where a number belongs, `null`, NaN) is ignored and the tracker keeps its current value.

### expect (optional hint when a Sign it challenge goes live)

```json
{ "v": 1, "type": "expect", "challenge_id": "c_000042", "letters": "BLUE" }
```

The tracker may use this only to break ties between look-alike letters. It must still report what it sees,
never what it expects.

The exact rule (`pick` in `signtracker/classifier.py`): the hint swaps the top two guesses only when they are within 0.10 of each other, the second one is in `letters` and the first one is not. The answer is always one of the top two, and the reported confidence is that letter's own probability. A new `expect` also resets the smoother, so a word can start with the letter the last word ended on.

### idle (when no Sign it challenge is live)

```json
{ "v": 1, "type": "idle" }
```

The tracker may lower its frame rate while idle to save battery.

### ping (every second)

```json
{ "v": 1, "type": "ping" }
```

The game sends this every second while it runs. A tracker started with `--exit-when-orphaned` quits after 5 seconds without a ping, counting from its own start, so a crashed or closed game never leaves the camera on (see docs/adr/0006-standalone-distribution.md).

`config` fields the game leaves out keep the tracker's current value. The values come from `game/content/config/tracker.json`.

## Recognition pipeline (inside the tracker)

1. Capture a webcam frame (target 30 fps).
2. Hand landmarks: MediaPipe Hand Landmarker (21 points). On the Mac, an Apple Vision helper can replace this step later.
3. Normalize (`features.py`): undo the frame's aspect ratio, translate so the wrist is the origin, scale by palm size, mirror if the player signs left-handed.
4. Features: the 63 normalized coordinates plus 15 finger joint bend angles.
5. Classify (`classifier.py`): logistic regression weights from `models/letters.npz` give a probability for each letter, then the `expect` tie rule. J and Z need motion, so they will use a short window of frames later.
6. Smooth (`smoothing.py`): accept a letter only when the same top letter holds for `hold_frames` frames with confidence at least `min_confidence`, then block it until `release_frames`.
7. Send a `letter` message and print it in the tracker console.

## Fake tracker

`python -m signtracker.fake --word BLUE --delay 0.6 [--loop]` sends a `hello`, then the letters of the word with a delay between them, keeping the heartbeat going.
Use it to test Sign it without a webcam, in CI, and when the real model is not trained yet.
