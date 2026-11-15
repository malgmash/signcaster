# signtracker

The hand tracker that runs next to the game. It reads the webcam, finds your hand with MediaPipe, reads the letter, and tells the game over localhost UDP (docs/TRACKER_PROTOCOL.md).
Video never leaves this program: no frames are saved or sent, and it only talks to 127.0.0.1.

Commands below are for Windows PowerShell. On a Mac, use `python3` to create the venv and `.venv/bin/python` instead of `.venv\Scripts\python`.

## Setup (once per laptop)

```powershell
cd tracker
python -m venv .venv
.venv\Scripts\python -m pip install -e ".[dev]"
curl.exe -L -o models\hand_landmarker.task https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/latest/hand_landmarker.task
```

`.[dev]` includes scikit-learn, which only training needs. The game's players will never need it.

## Run

| What | Command |
| --- | --- |
| Tracker with a preview window | `.venv\Scripts\python -m signtracker --show` |
| Fake tracker, no webcam | `.venv\Scripts\python -m signtracker.fake --word BLUE --loop` |
| Tests | `.venv\Scripts\python -m pytest` |

In the preview, the green dots are the hand points and the top left shows the current guess and how sure the model is. Q or Esc closes it.
Accepted letters print in the console as `letter D 0.93`.
Before a letter model exists, the preview says so and the game sees `model_missing`.

## Record letters

```powershell
.venv\Scripts\python tools\record.py --signer malama --letters ADGMO
```

- It explains what is saved and asks you to type `yes`. Only hand points (numbers) are saved, never images, in `tracker/data/<signer>/`.
- Use a nickname, not a real name. Left-handed signers add `--hand left`.
- For each letter: a 3 second countdown, then it records 50 samples (about 5 seconds). Then K keeps the take, R redoes it, Q quits. Kept takes are saved right away.
- The window shows only the letter's name. Sign it the way you were taught. Someone who knows ASL should check the recordings before we train the full alphabet.
- **Between takes, change something:** move a bit closer or farther, shift where your hand is in the frame, tilt slightly, change the light. Four varied takes beat one long one.
- To delete your recordings, delete your folder in `tracker/data/`.

First useful test: A D G M O, 4 takes each, by at least 2 people. A third person makes the score much more trustworthy.

## Train

```powershell
.venv\Scripts\python tools\train.py
```

It prints a report and saves `models/letters.npz`. Then restart the tracker to load it.

### Reading the report

- **Held-out samples:** every score comes from a model that never saw that person. The tool trains on everyone else, tests on one signer, and repeats for each signer. That's how well it will work for a new player.
- **Per held-out signer:** if one person scores much lower, the model learned the other person's style rather than the letter. More signers fixes that.
- **Per letter:** low scores show which letters need more or better takes.
- **Confusion matrix:** rows are the letter signed, columns the letter the model said. Numbers off the diagonal are mix-ups. A big number in row D, column G means D was often read as G.
- **With only one signer**, the tool warns you: the score then tests the same person on other frames, so it looks better than it really is.
- **k-NN vs logistic regression:** both are scored. Only logistic regression is saved, because a k-NN model is a copy of every recording, and the model file must be safe to share.
