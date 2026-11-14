# Roadmap

About 12 weeks part time. Each milestone has a matching prompt in `docs/prompts/`.
Do them in order. M12 is the exception: it can run alongside M7 to M10 once M6 is merged, and must be done before the M11 release.
Check the box when the milestone is merged and playtested.

| # | Milestone | Prompt | Suggested owner | Done |
| --- | --- | --- | --- | --- |
| M0 | Repo and project setup | `00-repo-setup.md` | Either | [ ] |
| M1 | Engine skeleton | `01-engine-skeleton.md` | Person A | [ ] |
| M2 | Read it loop with the debug skin | `02-read-it-loop.md` | Person A | [ ] |
| M3 | QB skin, first drive | `03-qb-skin-v1.md` | Person B | [ ] |
| M4 | Tracker sidecar and fake tracker | `04-tracker-sidecar.md` | Person A | [ ] |
| M5 | Letter recording and classifier | `05-letter-classifier.md` | Person A | [ ] |
| M6 | Sign it in the game | `06-sign-it-integration.md` | Person A and B | [ ] |
| M7 | Progression and difficulty | `07-progression-difficulty.md` | Person A | [ ] |
| M8 | Coins, stars and the QB store | `08-economy-store.md` | Person B | [ ] |
| M9 | Wizard skin and wizard shop | `09-wizard-skin.md` | Person B | [ ] |
| M10 | Saves, daily challenge, streaks | `10-save-daily-streaks.md` | Person A | [ ] |
| M11 | Whole-word signs, polish, release | `11-polish-release.md` | Both | [ ] |
| M12 | Standalone downloads (Windows and macOS) | `12-standalone-distribution.md` | Either | [ ] |

## Milestone goals and acceptance

### M0 Repo and project setup (week 1)
Godot project in `game/`, GUT installed, tracker package skeleton, CI green, content validator passing.
**Done when:** a fresh clone opens in Godot, `python scripts/validate_content.py` passes, CI passes on a PR.

### M1 Engine skeleton (week 1 to 2)
All autoloads exist with typed stubs, `EventBus` has every signal from EVENTS.md, `Config` loads content, `Clock` is injectable.
**Done when:** GUT runs headless with at least one test per autoload.

### M2 Read it loop (week 2)
`WordBank`, `ChallengeManager` and grading work end to end with the debug skin. Type the word before time runs out.
**Done when:** you can play a 4-challenge level with the debug skin and see points and grades. Tests cover grading and input checking.

### M3 QB skin, first drive (weeks 3 to 4)
Huddle with play card, snap, memory bubble, pocket timer, touchdown and sack. Placeholder art is fine.
**Done when:** a full drive of 4 plays is playable and feels like football. Both of us playtest it.

### M4 Tracker sidecar (week 5)
`signtracker` sends `hello`, `hand` and `status` messages. Fake tracker sends scripted letters. `TrackerClient` shows status in the debug skin.
**Done when:** the debug skin shows "connected" with the fake tracker and "disconnected" when it stops.
Also add the game's `ping` message and the tracker's `--exit-when-orphaned` flag from ADR 0006, so M12 can package the tracker safely.

### M5 Letter classifier (weeks 5 to 6)
Recording tool (landmarks only), training script, smoother, first model for a small set of letters, then the full static alphabet.
**Done when:** live letters appear in the tracker console with a simple accuracy report from held-out samples.

### M6 Sign it in the game (week 6)
Sign it challenges work in the QB skin with the real tracker and the fake tracker. Fallback to Read it when disconnected.
**Done when:** a drive can be finished by signing. Unplugging the tracker mid-drive switches to Read it gracefully.

### M7 Progression and difficulty (weeks 7 to 8)
Tiers, groups, boss levels, rubber-banding, spaced repetition, near-miss messages, instant retry.
**Done when:** a 4-group season plays with a clear sawtooth feel. Tests cover rubber-banding and Leitner boxes.

### M8 Coins, stars and the QB store (weeks 8 to 9)
Wallet, stars per level, locker room store, equip items on the QB.
**Done when:** coins earned in play buy an item that visibly changes the QB. Validator rejects gameplay stats on items.

### M9 Wizard skin (weeks 9 to 10)
Spellbook, monster path, wizard shop, kid tuning. No engine changes except bug fixes.
**Done when:** Wizard mode plays a full path using the same engine. If engine changes were needed, they are listed in the PR.

### M10 Saves, daily challenge, streaks (week 10 to 11)
Atomic saves, migrations, daily challenge, streak and earned streak freezes.
**Done when:** progress survives restarts and a corrupted save is handled safely.

### M11 Polish and release (weeks 11 to 12)
Whole-word signs for reviewed words, Mac Vision helper (optional), settings menu, accessibility options, ASL playtests, itch.io build.
**Done when:** a build is on itch.io and every shipped sign is marked `reviewed`.

### M12 Standalone downloads (any time after M6, before the M11 release)
One download per platform with no Python and no setup. The tracker is bundled with PyInstaller. The game launches it after the player opts in to the camera, and a crashed game never leaves it running. Windows builds come from `scripts/build_release.py`, macOS builds from GitHub Actions. See ADR 0006.
**Done when:** a player on Windows with no Python downloads the zip from a GitHub Release, plays Read it at once and Sign it after the camera opt-in. CI produces the macOS build, which stays "experimental" until an outside tester confirms it on a real Mac. Both downloads are under 300 MB.
