# Data formats

All game content is JSON under `game/content/`. The save file is JSON in Godot's user data folder.
Every file has a `version` number. Bump it when the shape changes and add a migration in `SaveSystem` or `Config`.

Run `python scripts/validate_content.py` after editing any content file. CI runs it too.

## Content files

```
game/content/
  word_packs/starter.json
  store/qb_catalog.json
  store/wizard_catalog.json
  config/difficulty.json
  config/scoring.json
  config/economy.json
```

## Word pack (`word_packs/*.json`)

```json
{
  "version": 1,
  "id": "starter",
  "title": "Starter pack",
  "kind": "fingerspell",
  "unlock": { "type": "default" },
  "words": [
    {
      "id": "starter.blue",
      "word": "BLUE",
      "kid_safe": true,
      "media": { "word_sign": null },
      "review_status": "placeholder"
    }
  ]
}
```

| Field | Rules |
| --- | --- |
| `id` | Lowercase, unique across all packs. Word ids are `<pack id>.<word in lowercase>`. |
| `kind` | `"fingerspell"` (spelled letter by letter) or `"word_sign"` (a whole sign, later milestone). |
| `unlock.type` | `"default"`, `"level"` (needs `level_id`) or `"stars"` (needs `stars`). |
| `word` | Uppercase A to Z only, 2 to 8 letters for fingerspell packs. |
| `kid_safe` | Must be `true` for any word that can appear in Wizard mode. |
| `media.word_sign` | Path to reviewed sign media (video or animation) or `null`. Fingerspelled words use the shared alphabet art. |
| `review_status` | `"placeholder"`, `"needs_review"` or `"reviewed"`. Only `"reviewed"` content ships in a release build. |

Text descriptions of how to make a sign are not allowed in content files. Sign media must be human-made and reviewed.

## Store catalog (`store/*_catalog.json`)

```json
{
  "version": 1,
  "mode": "qb",
  "items": [
    {
      "id": "qb.helmet.gold",
      "name": "Gold helmet",
      "slot": "helmet",
      "price": 500,
      "unlock": null,
      "art": "res://skins/qb/store/helmet_gold.png"
    },
    {
      "id": "qb.stadium.night",
      "name": "Night stadium",
      "slot": "stadium",
      "price": 1200,
      "unlock": { "type": "level", "level_id": "qb.drive_5" },
      "art": "res://skins/qb/store/stadium_night.png"
    }
  ]
}
```

| Field | Rules |
| --- | --- |
| `mode` | `"qb"` or `"wizard"`. Item ids are `<mode>.<slot>.<name>`, for example `qb.helmet.gold`. |
| `slot` | QB: `helmet`, `jersey`, `cleats`, `stadium`, `celebration`, `football`. Wizard: `robe`, `wand`, `hat`, `spell_color`, `pet`, `boots`. |
| `price` | Whole coins, 0 or more. Price 0 means a starting item that every player owns. Each slot needs one. |
| `unlock` | `null`, `{ "type": "level", "level_id": ... }` or `{ "type": "stars", "stars": N }`. |
| `art` | A `res://` path inside the skin folder. Missing art is allowed during development (validator warns). |

Items never carry gameplay stats. The validator rejects keys like `speed`, `time_bonus` or `multiplier`.

## Difficulty config (`config/difficulty.json`)

```json
{
  "version": 1,
  "challenges_per_level": 4,
  "modes": {
    "qb": { "study_seconds": 6, "timer_scale": 1.0, "default_bubble": "fade", "max_new_words_per_level": 3 },
    "wizard": { "study_seconds": 0, "timer_scale": 1.6, "default_bubble": "stay", "max_new_words_per_level": 2 }
  },
  "tiers": [
    { "id": "t1", "live_seconds": 12, "word_length": [3, 3], "bubble_style": "stay", "directions": ["read_it"], "twist": null, "is_boss": false }
  ],
  "groups": [
    { "id": "group_1", "tiers": ["t1", "t2", "t3", "t4_boss"] }
  ],
  "adaptive": {
    "window": 8,
    "fails_to_ease": 2, "ease_factor": 1.15, "max_ease": 1.3,
    "fasts_to_harden": 3, "harden_factor": 0.92, "max_harden": 0.8
  },
  "review": { "boxes": 5, "review_share": 0.3, "due_every_sessions": [1, 2, 4, 8, 16] }
}
```

- Level ids are built as `<mode>.<group id>.<index>`, for example `qb.group_1.4`. Skins rename groups for display (drive, path).
- `bubble_style` in a tier overrides the mode default. `null` means use the mode default.
- `directions` lists what the tier may pick from. The engine converts `sign_it` to `read_it` when the tracker is unavailable.
- `timer_scale` multiplies `live_seconds` for the whole mode (kids get more time).
- A tier may set `challenges` to override `challenges_per_level` (used for boss levels).

## Scoring config (`config/scoring.json`)

```json
{
  "version": 1,
  "fast_threshold": 0.5,
  "base_points": 100,
  "combo_step": 0.1,
  "combo_cap": 2.0,
  "stars": { "two_star_success_rate": 0.8, "three_star_fast_rate": 0.5 }
}
```

## Economy config (`config/economy.json`)

```json
{
  "version": 1,
  "coins_per_success": 10,
  "fast_bonus": 5,
  "perfect_level_bonus": 25,
  "daily_challenge_bonus": 20,
  "streak_freeze_every_days": 7,
  "max_streak_freezes": 2
}
```

## Save file (`user://save.json`)

```json
{
  "version": 1,
  "session_count": 12,
  "wallet": { "coins": 1240 },
  "owned_items": ["qb.jersey.retro", "wizard.wand.crystal"],
  "equipped": { "qb.jersey": "qb.jersey.retro", "wizard.wand": "wizard.wand.crystal" },
  "words": {
    "starter.blue": { "box": 3, "last_seen_session": 11, "seen": 9, "correct": 7 }
  },
  "levels": {
    "qb.group_1.1": { "best_stars": 3, "best_points": 640 }
  },
  "streak": { "days": 4, "last_play_date": "2026-11-12", "freezes": 1 },
  "settings": {
    "mirror_hands": false,
    "text_scale": 1.0,
    "sfx_volume": 0.8,
    "music_volume": 0.6,
    "colorblind_palette": false,
    "tracker_port": 47800
  }
}
```

- No names, emails, photos or ages. Ever.
- `equipped` keys are `<mode>.<slot>`.
- Write with a temp file and rename, so a crash never corrupts the save.
- Unknown keys are kept when loading and saving (forward compatibility).
