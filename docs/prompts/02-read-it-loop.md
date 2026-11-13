# 02 Read it loop with the debug skin (M2)

| | |
| --- | --- |
| Branch | `feat/read-it-loop` |
| Best with | Claude Code (plan mode) |
| Needs | M1 merged |

## Prompt

```text
Make the first playable loop of Signcaster: Read it challenges in the debug skin. Follow AGENTS.md.

Read first:
- docs/GAME_DESIGN.md: "Core loop", "Challenge rules", "Grades and scoring"
- docs/ARCHITECTURE.md: "Challenge lifecycle", "Picking the next challenge" (steps 2 and 4 only, no difficulty yet), "Grading and points", "Input checking"
- docs/EVENTS.md

Goal: I can play a level of 4 Read it challenges with the debug skin. I see the word and placeholder sign cards during study, type the word while a timer runs, and see the grade and points.

Do this:
1. word_bank.gd: load the starter pack from Config, pick words without repeating inside a level. Use a seeded RandomNumberGenerator that tests can control. Spaced repetition comes later, leave a TODO.
2. challenge_manager.gd: implement the state machine from the architecture doc (Idle, Study, Live, Succeeded, Failed, RetryOffered, Reward, LevelDone). Use Clock for time. Emit every lifecycle signal from EVENTS.md at the right moment. For now use one fixed tier: live_seconds 12, bubble_style "stay", direction "read_it".
3. Input checking for Read it exactly as in the architecture doc, including letter_rejected and backspace.
4. Grading and points using game/content/config/scoring.json.
5. game.gd: implement start_session, start_level, submit_typed_letter, delete_typed_letter, skip_study, give_up, retry, set_paused by forwarding to the right autoload.
6. Debug skin (game/skins/debug/): a plain screen with labels for state, word, typed letters, time remaining, grade, points, and buttons for Start level, Skip study, Give up, Retry, Pause. Keyboard letters A to Z and Backspace call Game. The debug skin only listens to EventBus and calls Game.
7. Shared widget game/ui/sign_card.tscn: a card that shows a texture for a letter, with a placeholder texture and the letter drawn small in the corner. Add a note in the scene that real sign art must be reviewed.
8. GUT tests: grading boundaries (exactly 0.5 remaining is fast), combo cap, wrong letters do not advance, backspace, timeout fails, pause freezes the timer, retry replays the same word.

Constraints:
- No difficulty, coins or saving yet.
- No art beyond plain UI. Keep engine and skin separate.

Before editing, list the states and transitions you will implement and which signal fires on each one. Wait for my OK.

When done, run the tests and boundary check, then tell me exactly how to play one level by hand.
```

## After the agent finishes

- [ ] Play 3 levels with the debug skin. Try being fast, slow, wrong and out of time.
- [ ] Pause during a live challenge. The timer must stop.
- [ ] Ask the other agent to run `review-diff`.
