# 05 Letter recording and classifier (M5)

| | |
| --- | --- |
| Branch | `feat/letter-classifier` |
| Best with | Claude Code for the plan, either for the code |
| Needs | M4 merged |

## Prompt

```text
Add fingerspelling letter recognition to the Signcaster tracker. Follow AGENTS.md.

Read first:
- docs/TRACKER_PROTOCOL.md: "letter" message and "Recognition pipeline"
- docs/ARCHITECTURE.md: "Tracker internals"

Goal: the tracker recognizes static fingerspelled letters from landmarks and sends letter messages through a smoother. Start with 5 letters, then the full static alphabet (J and Z need motion and come later).

Do this:
1. features.py (pure functions): normalize 21 landmarks (wrist at origin, scale by palm size, optional mirror for left-handed signers), then build a feature vector of normalized coordinates plus finger joint angles. Unit test each step with hand-made point sets.
2. tools/record.py: a recording tool that saves landmarks only (never images) to tracker/data/<signer_id>/<letter>.npz. Before recording, print a consent line and require the person to type "yes". Show a countdown, record N samples per letter, and allow redo. signer_id is a nickname, not a real name.
3. tools/train.py: train a small classifier with scikit-learn (start with k-nearest neighbors and logistic regression, keep the better one). Split train and test BY SIGNER so we measure how it works on a new person, not just the person who recorded it. Print accuracy per letter and a confusion matrix. Save the model to tracker/models/letters.joblib.
4. smoothing.py (pure, heavily tested): accept a letter only when the same top prediction holds for hold_frames frames with confidence >= min_confidence; do not repeat it until release_frames frames of a different shape or no hand. Values come from the config message.
5. classifier.py: load the model, predict probabilities, return the top letter and confidence.
6. Wire it into __main__.py so letter messages are sent. Respect mirror and expect hints exactly as the protocol doc says: the hint may only break ties, never invent a letter.
7. Add scikit-learn and joblib to pyproject.toml (this is the approved dependency change for this milestone).

Rules:
- Do not write descriptions of how letters are signed. We record real people signing, checked by someone who knows ASL.
- Recorded data and models are gitignored.

Before editing, give me a plan and tell me how many samples per letter and how many signers we need for a first useful test. Wait for my OK.

When done, give me the exact recording and training commands, and how to read the accuracy report.
```

## After the agent finishes

- [ ] Record 5 letters with at least two different signers (you and your friend).
- [ ] Train. Look at the per-signer accuracy, not only the total.
- [ ] Run the tracker with `--show` and sign slowly. Note which letters get confused.
- [ ] Before training the full alphabet, have someone fluent in ASL check your recorded handshapes.
