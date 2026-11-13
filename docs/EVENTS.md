# Event bus contract

The `EventBus` autoload (`game/engine/event_bus.gd`) is the only way the engine talks to skins.
Skins listen to these signals and call public methods on the `Game` autoload. Nothing else.

Rules:

- Signal names are past tense. Arguments are typed.
- Adding a signal is fine. Renaming a signal or changing its arguments is a breaking change: update this file, both skins and the debug skin in the same PR.
- `challenge` dictionaries always contain the keys listed under "Challenge dictionary" below.

## Session and level

| Signal | Arguments | Emitted when |
| --- | --- | --- |
| `session_started` | `mode: String, skin_id: String` | A mode is chosen from the main menu |
| `level_started` | `level_id: String, level_index: int, is_boss: bool` | A play or wave group begins |
| `level_completed` | `level_id: String, stars: int, coins_earned: int, perfect: bool` | All challenges in the level are done |
| `session_ended` | `reason: String` | Player quits to menu (`"quit"`) or closes the game (`"exit"`) |

## Challenge lifecycle

| Signal | Arguments | Emitted when |
| --- | --- | --- |
| `challenge_created` | `challenge: Dictionary` | Engine picks the next word and direction |
| `study_started` | `challenge_id: String, seconds: float` | Study phase begins (`seconds` is 0 for untimed study) |
| `study_ended` | `challenge_id: String` | Study phase ends |
| `live_started` | `challenge_id: String, seconds: float, bubble_style: String` | Pressure timer starts and the memory bubble appears |
| `timer_ticked` | `challenge_id: String, remaining_ratio: float` | Every frame while live (1.0 at start, 0.0 at the end) |
| `bubble_style_changed` | `challenge_id: String, bubble_style: String` | Bubble fades or flashes during the live phase |
| `letter_accepted` | `challenge_id: String, letter: String, index: int` | A correct next letter is entered (typed or signed) |
| `letter_rejected` | `challenge_id: String, letter: String, index: int` | A wrong letter is typed (Read it only) |
| `word_changed` | `challenge_id: String, new_word: String` | An audible twist swaps the word mid-challenge |
| `challenge_succeeded` | `challenge_id: String, result: Dictionary` | Last letter accepted before time runs out |
| `challenge_failed` | `challenge_id: String, reason: String, letters_correct: int, letters_total: int` | Timer ran out (`"timeout"`) or player gave up (`"gave_up"`) |
| `retry_offered` | `challenge_id: String` | After a fail, the skin may show the retry button |

## Economy and store

| Signal | Arguments | Emitted when |
| --- | --- | --- |
| `coins_changed` | `balance: int, delta: int, reason: String` | Any change to the wallet |
| `stars_changed` | `level_id: String, stars: int` | A level's best star count goes up |
| `item_purchased` | `item_id: String` | Purchase succeeded |
| `purchase_failed` | `item_id: String, reason: String` | `"not_enough_coins"`, `"locked"`, `"already_owned"` |
| `item_equipped` | `slot: String, item_id: String` | Player equips an item |
| `streak_updated` | `days: int, freezes: int` | Daily challenge streak changes |

## Tracker and system

| Signal | Arguments | Emitted when |
| --- | --- | --- |
| `tracker_status_changed` | `status: String` | `"connected"`, `"no_hand"`, `"disconnected"` |
| `sign_it_unavailable` | `reason: String` | Sign it challenges are being converted to Read it |
| `difficulty_adjusted` | `knob: String, value: float` | Rubber-banding changes a knob (for debug overlay) |
| `paused_changed` | `paused: bool` | Game paused or resumed |
| `save_reset` | `reason: String` | The save file was unreadable, was kept as save.bad.json, and a fresh save started |

## Challenge dictionary

```gdscript
{
    "id": "c_000042",             # unique per session
    "word": "BLUE",               # uppercase A to Z
    "word_id": "starter.blue",    # id from the word pack
    "direction": "sign_it",       # "sign_it" or "read_it"
    "study_seconds": 6.0,         # 0.0 means untimed
    "live_seconds": 9.0,
    "bubble_style": "stay",       # "stay", "fade" or "flash"
    "is_review": false,           # true if picked by spaced repetition
    "twist": "",                  # "", "audible" or "decoy"
}
```

## Result dictionary (challenge_succeeded)

```gdscript
{
    "grade": "fast",              # "fast" or "slow"
    "remaining_ratio": 0.62,
    "time_used": 3.4,
    "points": 178,
    "combo": 2,
    "coins": 15,
}
```

## Public methods on `Game` (skins may call these)

| Method | Purpose |
| --- | --- |
| `start_session(mode: String) -> void` | `"qb"` or `"wizard"` |
| `start_level(level_id: String) -> void` | Begin a level |
| `submit_typed_letter(letter: String) -> void` | Read it input |
| `delete_typed_letter() -> void` | Read it backspace |
| `skip_study() -> void` | Player is ready before the study timer ends |
| `give_up() -> void` | Ends the challenge as a fail |
| `retry() -> void` | Retry the last failed challenge |
| `set_paused(paused: bool) -> void` | Pause or resume |
| `buy_item(item_id: String) -> void` | Store purchase |
| `equip_item(item_id: String) -> void` | Equip a cosmetic |

Signed letters do not go through `Game`. The `TrackerClient` autoload feeds them to `ChallengeManager` directly.
