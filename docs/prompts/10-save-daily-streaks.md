# 10 Saves, daily challenge, streaks (M10)

| | |
| --- | --- |
| Branch | `feat/save-daily` |
| Best with | Either agent. Ask the other one to review the save code carefully. |
| Needs | M9 merged |

## Prompt

```text
Add saving, a daily challenge and streaks to Signcaster. Follow AGENTS.md.

Read first:
- docs/DATA_FORMATS.md: "Save file"
- docs/GAME_DESIGN.md: "Rewards and store" (daily challenge and streaks), "Kids rules"
- docs/ARCHITECTURE.md: "Errors and fallbacks", "Performance budgets" (save write)
- docs/adr/0004-privacy-and-fair-play.md

Goal: progress survives restarts on both laptops, a corrupt save never crashes the game, and there is a daily challenge with a streak.

Do this:
1. save_system.gd: load and save user://save.json exactly in the documented shape. Atomic write (write to a temp file, then rename). Keep unknown keys. Version field with a migrate() function and a test for migrating a version 1 file.
2. Corrupt or unreadable save: rename it to save.bad.json, start fresh, emit an event the skins can show as a friendly message.
3. Save at safe moments only: level complete, purchase, equip, settings change, quit. Never while a challenge is live.
4. Wire Economy, Store, WordBank (boxes, seen, correct), level stars and settings into the save.
5. Daily challenge: one short level per calendar day built from due review words, with a coin bonus from economy.json. The date comes from Clock so tests can change it.
6. Streak: increase on consecutive days, earn a freeze every N days (max from config), a freeze covers exactly one missed day, missing a day never removes coins or items. Emit streak_updated.
7. Main menu: daily challenge button with the streak count for both modes.
8. Tests: atomic write leaves the old save intact if writing fails, corrupt file handling, unknown keys survive a round trip, streak cases (consecutive days, one missed day with and without a freeze, two missed days, time zone midnight edge).

Rules:
- The save file holds no names, emails, ages or photos.

Before editing, give me a plan and the list of streak test cases. Wait for my OK.

When done, tell me where the save file lives on macOS and Windows and how to reset it for testing.
```

## After the agent finishes

- [ ] Play, quit, reopen. Coins, items and stars are still there.
- [ ] Put garbage in the save file. The game starts and explains what happened.
- [ ] Change the fake date in a debug build to test streaks.
