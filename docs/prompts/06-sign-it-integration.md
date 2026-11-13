# 06 Sign it in the game (M6)

| | |
| --- | --- |
| Branch | `feat/sign-it` |
| Best with | Either agent |
| Needs | M3 and M5 merged |

## Prompt

```text
Connect signed letters to Signcaster challenges. Follow AGENTS.md.

Read first:
- docs/ARCHITECTURE.md: "A Sign it challenge, step by step", "Input checking", "Errors and fallbacks"
- docs/EVENTS.md: tracker_status_changed, sign_it_unavailable, letter_accepted
- docs/GAME_DESIGN.md: "Challenge rules"

Goal: a QB drive can be finished by signing. If the tracker disconnects, Sign it challenges turn into Read it challenges with a clear banner.

Do this:
1. ChallengeManager: support direction "sign_it". On live_started, call TrackerClient.send_expect(word); when the challenge ends, send_idle().
2. TrackerClient forwards letter messages to ChallengeManager.on_signed_letter(letter). Only the next expected letter is accepted; others are ignored (no letter_rejected for signing).
3. Fallback: if the tracker is not connected when a sign_it challenge is created, use read_it and emit sign_it_unavailable once per session. If it disconnects during a live sign_it challenge, switch that challenge to read_it, keep the remaining time and the letters already accepted.
4. Temporary direction rule until M7: alternate read_it and sign_it when the tracker is connected.
5. QB skin: in sign_it the memory bubble shows the word; add a small webcam status window (no video, just an icon, tracker status and the letters accepted so far). Show the fallback banner on sign_it_unavailable.
6. Tests: signed letters advance only in order, wrong signed letters are ignored, the mid-challenge fallback keeps time and progress, expect and idle are sent at the right moments (mock TrackerClient).

Rules:
- The game never shows or receives video. The webcam window is an icon and status only.

Before editing, give me a plan. Wait for my OK.

When done, tell me how to test with the fake tracker (python -m signtracker.fake --word ... --loop) and with the real tracker.
```

## After the agent finishes

- [ ] Finish a drive by signing with the real tracker on each laptop.
- [ ] Kill the tracker mid-play. The challenge continues as Read it without losing time.
- [ ] Measure: how long from holding a letter still to seeing it accepted? Budget is under 300 ms.
