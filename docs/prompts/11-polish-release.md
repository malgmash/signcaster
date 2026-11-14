# 11 Polish and release (M11)

| | |
| --- | --- |
| Branch | several small branches, one per item below |
| Best with | Split the list between both agents. Never two agents on one branch. |
| Needs | M10 merged |

Do these as separate prompts and PRs. Each block is its own prompt.

## A. Settings and accessibility

```text
Add a settings menu to Signcaster. Follow AGENTS.md. Read docs/GAME_DESIGN.md "Accessibility" and docs/DATA_FORMATS.md "Save file" (settings).
Settings: mirror hands (sends config to the tracker), text size, sound and music volume, colorblind-safe palette (success and fail never rely on color alone), tracker port. Save through SaveSystem.
Plan first and wait for my OK. Add tests for settings round trips.
```

## B. One-click launcher

> Replaced by M12 (`12-standalone-distribution.md`, ADR 0006). Kept for reference. Do not run this one.

```text
Make Signcaster start the tracker automatically. Follow AGENTS.md. Read docs/adr/0002-python-tracker-sidecar.md.
When the game starts, if no tracker hello arrives within 2 seconds, try to launch the tracker as a child process using the Python in tracker/.venv (Mac and Windows paths), and stop it when the game quits. If launching fails, keep playing in Read it and show how to start it by hand.
Plan first and wait for my OK. Explain the security considerations of launching a process.
```

## C. Whole-word signs (reviewed words only)

```text
Add whole-word sign challenges for word packs of kind "word_sign". Follow AGENTS.md. Read docs/DATA_FORMATS.md "Word pack", docs/TRACKER_PROTOCOL.md "Recognition pipeline" and docs/GAME_DESIGN.md "Content".
Read it: show the reviewed sign media (video or animation) from media.word_sign. Sign it: propose how to extend the tracker with a sequence model over about one second of landmarks, and what data we need (consider the Kaggle Isolated Sign Language Recognition dataset and check its license).
Only words with review_status "reviewed" may appear. Plan first, including the license check, and wait for my OK. Do not write descriptions of how signs are made.
```

## D. Mac Vision helper (optional, M5 Mac only)

```text
Design an optional macOS helper app in Swift that uses Apple's Vision framework hand pose detection and speaks the exact protocol in docs/TRACKER_PROTOCOL.md (tracker name "apple_vision"), reusing our trained letter model if possible. Follow AGENTS.md.
First write a design note comparing it with MediaPipe on the M5 (speed, battery, accuracy, setup effort). Wait for my OK before writing code.
```

## E. Release build on itch.io

> Replaced by M12 (`12-standalone-distribution.md`, ADR 0006), which covers export presets, the reviewed-sign check, cheat keys and RELEASE.md. Kept for reference. Do not run this one.

```text
Prepare a Signcaster release. Follow AGENTS.md.
1. Godot export presets for macOS and Windows.
2. A release checklist in docs/RELEASE.md: version bump, every shipped sign marked reviewed (write a script that checks this), credits from game/assets_credits.md, privacy note for the store page, how to open an unsigned app on macOS, camera permission notes.
3. Remove debug-only cheat keys from release builds.
Plan first and wait for my OK. Do not upload anything; I will do that by hand.
```

## After each one

- [ ] Review with the other agent.
- [ ] Play the whole game start to finish before tagging a release.
- [ ] ASL playtest with Deaf signers before the first public build.
