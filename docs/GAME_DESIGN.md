# Game design

What Signcaster is, how it should feel, and the rules every feature must respect.
For how it is built, see ARCHITECTURE.md.

## Pillars

1. **Learn by recalling under pressure.** Study, then remember while the clock runs. Recall is where learning sticks.
2. **Hard but achievable.** Start easy, climb steadily, never feel impossible.
3. **Both directions of the language.** Sign it trains making signs. Read it trains understanding them.
4. **Respectful and accurate.** Sign content is checked by Deaf ASL signers. We teach vocabulary, not fluency, and say so.
5. **Fair and safe.** Cosmetic-only store, no real money for kids, webcam stays on the device.

## Modes

| | QB mode | Wizard mode |
| --- | --- | --- |
| Audience | Teens and adults | Kids |
| Level unit | Play | Wave |
| Level group | Drive (about 4 plays), season (several drives) | Path (about 4 waves), world (several paths) |
| Study scene | Huddle with play card | Spellbook |
| Pressure | Defense rushes, pocket timer drains | Monster walks down the path |
| Fast success | Touchdown or long gain | Spell hits, monster poofs, combo |
| Slow success | Short gain | Spell hits, no combo |
| Fail | Sacked | Monster gets you, cartoon style, instant retry |
| Boss | Two-minute drill (several plays, running clock) | Boss monster (several words in a row) |
| Store | Locker room | Wizard shop |
| Default tuning | Bubble fades, faster rush | Bubble stays, slow monster, short words |

Our football league, teams and players are invented. No real league names, logos or players.

## Core loop

1. **Study.** The word appears as text and as signs at the same time, with a short study timer (kids can take as long as they need).
2. **Pressure.** The live timer starts. The skin shows it as the pass rush or the walking monster.
3. **Recall.** The memory bubble appears over the hero's head and shows one side of the word:
   - Sign it: shows the word, the player signs it letter by letter to the webcam.
   - Read it: shows the signs, the player types the word.
4. **Result.** Grade the answer (fast, slow or fail), pay out coins, update stars and word progress, then the next challenge.

Near misses ("1 letter away!") and an instant retry button keep a fail from feeling final.

## Challenge rules

- A challenge is one word in one direction.
- The player must enter letters in order. A wrong letter in Read it shows red and can be deleted. In Sign it, a wrong letter is ignored and the player keeps signing.
- The live timer only runs while the bubble is up. Pausing freezes it.
- If the tracker is not connected, Sign it challenges become Read it challenges and a small banner explains why.

## Grades and scoring

- `remaining_ratio` = time left divided by the live timer length when the last letter is accepted.
- Fast: `remaining_ratio >= 0.5`. Slow: `remaining_ratio > 0`. Fail: timer ran out or the player gave up.
- Points: `100 x (1 + remaining_ratio) x combo_multiplier`, where combo adds 0.1 per consecutive fast success, capped at 2.0.
- All numbers live in `game/content/config/scoring.json` so we can tune them without code changes.

## Stars per level

- 1 star: finish the level.
- 2 stars: at least 80% of challenges succeeded.
- 3 stars: every challenge succeeded and at least half were fast.

## Difficulty plan

Levels follow a sawtooth curve: each group of levels ramps up to a boss, then the next group starts a little easier than that boss but harder than the last group's start.

### Knobs (change one per level)

| Knob | Early | Later |
| --- | --- | --- |
| Live timer | Long | Short |
| Word length | 3 letters | Up to 8 letters, then whole signs |
| Bubble style | Stays on screen | Fades, then flashes once |
| Direction | Read it only | Sign it, then mixed |
| Twists | None | Audible (word changes mid-play), look-alike decoy signs |

### Adapting to each player

- Track the last 8 challenges.
- Two fails in a row: next live timer is 15% longer (at most 30% longer than the level's base).
- Three fast successes in a row: next live timer is 8% shorter (at most 20% shorter than base).
- Adjustments reset at the start of each drive or path.
- Target: players succeed on roughly 3 out of 4 challenges. This is a design target, tune it with playtests.

### Word review (spaced repetition)

Each word has a box from 1 to 5. Correct moves it up one box, a miss sends it back to box 1.
Box 1 words show up every session, box 5 words rarely. Each level mixes about 70% words from the current pack and 30% review words that are due.

## Rewards and store

- Coins: 10 per success, +5 for fast, +25 for a perfect level. Numbers live in `config/economy.json`.
- One wallet shared by both modes. Each mode has its own store catalog.
- Prices climb across the catalog. Some items unlock by progress (for example, reach drive 5).
- Items are cosmetic only: helmets, jerseys, cleats, stadiums, celebration dances, robes, wands, hats, spell colors, pets.
- New word packs unlock as "playbooks" (QB) or "spellbooks" (Wizard).
- Daily challenge: one short level per day, with a streak counter. A streak freeze is earned by playing, never bought.
- Friends leaderboard is QB mode only and comes after v1.

## Kids rules (Wizard mode)

- No real-money purchases, no loot boxes, no ads.
- Missing a day never removes coins or items.
- No accounts, no names required, nothing personal stored. Progress is saved only on the device.
- Fail animations are silly, never scary.

## Accessibility

- Read it mode needs no webcam, so anyone with a keyboard can play.
- Left-handed signers can mirror the tracker input in settings.
- Colorblind-safe palettes for success and fail states. Never rely on color alone.
- Text size setting. Sound is never required to play.

## Content

- Starter pack: short, common words (3 to 4 letters) for fingerspelling.
- Later packs: whole signs for everyday words. A Family pack focuses on words parents of deaf toddlers need first (eat, more, milk, sleep, mom, dad).
- Every word entry is data only. How a sign is made comes from reviewed sign art or video, never from text an AI wrote.

## Out of scope for v1

- Online multiplayer and leaderboards
- Accounts and cloud saves
- Phone versions
- Full ASL sentences and grammar
