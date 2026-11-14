extends Node
## The only channel from the engine to skins. Signals only, no logic.
##
## Every signal here must match docs/EVENTS.md exactly: same names, argument names and types.
## tests/test_event_bus.gd reads the doc and fails if the two drift apart.

# The engine emits these from other autoloads, so Godot cannot see them being used here.
@warning_ignore_start("unused_signal")

# Session and level

## A mode was chosen from the main menu.
signal session_started(mode: String, skin_id: String)
## A play or wave group begins.
signal level_started(level_id: String, level_index: int, is_boss: bool)
## All challenges in the level are done.
signal level_completed(level_id: String, stars: int, coins_earned: int, perfect: bool)
## The player quit to the menu ("quit") or closed the game ("exit").
signal session_ended(reason: String)

# Challenge lifecycle

## The engine picked the next word and direction. See EVENTS.md for the dictionary keys.
signal challenge_created(challenge: Dictionary)
## The study phase began. [param seconds] is 0 for untimed study.
signal study_started(challenge_id: String, seconds: float)
## The study phase ended.
signal study_ended(challenge_id: String)
## The pressure timer started and the memory bubble appeared.
signal live_started(challenge_id: String, seconds: float, bubble_style: String)
## Every frame while live. 1.0 at the start, 0.0 at the end.
signal timer_ticked(challenge_id: String, remaining_ratio: float)
## The bubble faded or flashed during the live phase.
signal bubble_style_changed(challenge_id: String, bubble_style: String)
## A correct next letter was entered, typed or signed.
signal letter_accepted(challenge_id: String, letter: String, index: int)
## A wrong letter was typed (Read it only).
signal letter_rejected(challenge_id: String, letter: String, index: int)
## An audible twist swapped the word mid-challenge.
signal word_changed(challenge_id: String, new_word: String)
## The last letter was accepted before time ran out. See EVENTS.md for the result keys.
signal challenge_succeeded(challenge_id: String, result: Dictionary)
## The timer ran out ("timeout") or the player gave up ("gave_up").
signal challenge_failed(
	challenge_id: String, reason: String, letters_correct: int, letters_total: int
)
## After a fail, the skin may show the retry button.
signal retry_offered(challenge_id: String)

# Economy and store

## Any change to the wallet.
signal coins_changed(balance: int, delta: int, reason: String)
## A level's best star count went up.
signal stars_changed(level_id: String, stars: int)
## A purchase succeeded.
signal item_purchased(item_id: String)
## A purchase failed: "not_enough_coins", "locked" or "already_owned".
signal purchase_failed(item_id: String, reason: String)
## The player equipped an item.
signal item_equipped(slot: String, item_id: String)
## The daily challenge streak changed.
signal streak_updated(days: int, freezes: int)

# Tracker and system

## "connected", "no_hand" or "disconnected".
signal tracker_status_changed(status: String)
## Sign it challenges are being converted to Read it.
signal sign_it_unavailable(reason: String)
## Rubber-banding changed a knob (for the debug overlay).
signal difficulty_adjusted(knob: String, value: float)
## The game was paused or resumed.
signal paused_changed(paused: bool)
## The save file was unreadable, was kept as save.bad.json, and a fresh save started.
signal save_reset(reason: String)

@warning_ignore_restore("unused_signal")
