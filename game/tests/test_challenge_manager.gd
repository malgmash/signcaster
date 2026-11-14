# gdlint: disable=max-public-methods
# GUT runs every public test_ method, and the docs ask for one test file per engine script.
extends GutTest
## ChallengeManager: the lifecycle, Read it input checking, grading, pausing and retry.
##
## Each test gets a fresh ChallengeManager and a frozen Clock, so time only moves when a test
## calls _wait(). Level 1 of each mode uses tier t1 from content/config/difficulty.json.

const ChallengeManagerScript = preload("res://engine/challenge_manager.gd")
const QB_LEVEL: String = "qb.group_1.1"
const WIZARD_LEVEL: String = "wizard.group_1.1"
const START_TIME: float = 100.0
const WORD_SEED: int = 7
const CHALLENGE_KEYS: PackedStringArray = [
	"id",
	"word",
	"word_id",
	"direction",
	"study_seconds",
	"live_seconds",
	"bubble_style",
	"is_review",
	"twist",
]

var _cm: Node


func before_each() -> void:
	Clock.set_fake_time(START_TIME)
	WordBank.set_seed(WORD_SEED)
	_cm = autofree(ChallengeManagerScript.new())
	watch_signals(EventBus)


func after_each() -> void:
	Clock.clear_fake_time()


# Helpers


func _start(mode: String = "qb", level_id: String = QB_LEVEL) -> void:
	_cm.start_session(mode)
	_cm.start_level(level_id)


func _start_live() -> void:
	_start()
	_cm.skip_study()


func _word() -> String:
	return _cm.get_challenge()["word"]


func _id() -> String:
	return _cm.get_challenge()["id"]


func _live_seconds() -> float:
	return _cm.get_challenge()["live_seconds"]


func _type(text: String) -> void:
	for letter: String in text:
		_cm.submit_typed_letter(letter)


func _wait(seconds: float) -> void:
	Clock.advance(seconds)
	_cm.tick()


func _a_wrong_letter() -> String:
	return "Q" if _word()[0] != "Q" else "Z"


func _last_result() -> Dictionary:
	return get_signal_parameters(EventBus, "challenge_succeeded")[1]


# Lifecycle


func test_starts_idle() -> void:
	assert_eq(_cm.get_state(), "idle")


func test_start_session_announces_the_mode() -> void:
	_cm.start_session("qb")
	assert_signal_emitted_with_parameters(EventBus, "session_started", ["qb", "qb"])


func test_start_level_announces_the_level_and_starts_study() -> void:
	_start()
	assert_signal_emitted_with_parameters(EventBus, "level_started", [QB_LEVEL, 0, false])
	assert_signal_emit_count(EventBus, "challenge_created", 1)
	assert_signal_emitted_with_parameters(EventBus, "study_started", [_id(), 6.0])
	assert_eq(_cm.get_state(), "study")


func test_challenge_has_every_documented_key() -> void:
	_start()
	var challenge: Dictionary = _cm.get_challenge()
	for key: String in CHALLENGE_KEYS:
		assert_true(challenge.has(key), "challenge is missing '%s'" % key)
	assert_eq(challenge["id"], "c_000001")
	assert_eq(challenge["direction"], "read_it")
	assert_eq(challenge["live_seconds"], 12.0)
	assert_eq(challenge["bubble_style"], "stay")
	assert_eq(challenge["twist"], "")
	assert_eq(str(challenge["word"]).length(), 3, "t1 uses 3-letter words")


func test_study_timer_ending_starts_live() -> void:
	_start()
	_wait(5.9)
	assert_eq(_cm.get_state(), "study")
	_wait(0.1)
	assert_eq(_cm.get_state(), "live")
	assert_signal_emitted_with_parameters(EventBus, "study_ended", [_id()])
	assert_signal_emitted_with_parameters(EventBus, "live_started", [_id(), 12.0, "stay"])


func test_untimed_study_waits_for_skip() -> void:
	_start("wizard", WIZARD_LEVEL)
	assert_signal_emitted_with_parameters(EventBus, "study_started", [_id(), 0.0])
	_wait(1000.0)
	assert_eq(_cm.get_state(), "study", "Wizard study has no timer")
	_cm.skip_study()
	assert_eq(_cm.get_state(), "live")
	assert_almost_eq(_live_seconds(), 12.0 * 1.6, 0.0001, "Wizard timer_scale is 1.6")


func test_typing_during_study_is_ignored() -> void:
	_start()
	_cm.submit_typed_letter(_word()[0])
	assert_signal_not_emitted(EventBus, "letter_accepted")
	assert_signal_not_emitted(EventBus, "letter_rejected")


func test_timer_ticks_with_the_remaining_ratio() -> void:
	_start_live()
	_wait(3.0)
	assert_signal_emitted_with_parameters(EventBus, "timer_ticked", [_id(), 0.75])


# Grading


func test_exactly_half_the_time_left_is_fast() -> void:
	_start_live()
	_wait(6.0)
	_type(_word())
	var result: Dictionary = _last_result()
	assert_eq(result["grade"], "fast")
	assert_eq(result["remaining_ratio"], 0.5)
	assert_eq(result["time_used"], 6.0)
	assert_eq(result["points"], 150)
	assert_eq(result["combo"], 1)


func test_just_under_half_the_time_left_is_slow() -> void:
	_start_live()
	_wait(6.01)
	_type(_word())
	var result: Dictionary = _last_result()
	assert_eq(result["grade"], "slow")
	assert_eq(result["combo"], 0)


func test_points_match_the_example_in_events_md() -> void:
	# 0.62 of 12 seconds left, one fast success before this one.
	var result: Dictionary = _cm.grade_result(7.44, 12.0, 1)
	assert_eq(result["points"], 178)
	assert_eq(result["combo"], 2)


func test_combo_multiplier_is_capped() -> void:
	# Full time left gives 100 x 2. The multiplier climbs 0.1 per fast and stops at 2.0.
	assert_eq(_cm.grade_result(12.0, 12.0, 9)["points"], 380)
	assert_eq(_cm.grade_result(12.0, 12.0, 10)["points"], 400)
	assert_eq(_cm.grade_result(12.0, 12.0, 50)["points"], 400)


func test_fast_streak_carries_to_the_next_challenge() -> void:
	_start_live()
	_type(_word())
	_cm.next_challenge()
	_cm.skip_study()
	_type(_word())
	var result: Dictionary = _last_result()
	assert_eq(result["combo"], 2)
	assert_eq(result["points"], 220, "100 x (1 + 1.0) x 1.1")


func test_a_fail_resets_the_streak() -> void:
	_start_live()
	_type(_word())
	_cm.next_challenge()
	_cm.skip_study()
	_cm.give_up()
	_cm.next_challenge()
	_cm.skip_study()
	_type(_word())
	assert_eq(_last_result()["combo"], 1)


# Input checking


func test_wrong_letter_is_rejected_and_not_added() -> void:
	_start_live()
	var wrong: String = _a_wrong_letter()
	_cm.submit_typed_letter(wrong)
	assert_signal_emitted_with_parameters(EventBus, "letter_rejected", [_id(), wrong, 0])
	assert_signal_not_emitted(EventBus, "letter_accepted")
	_type(_word())
	assert_signal_emit_count(EventBus, "letter_accepted", _word().length())
	assert_signal_emitted(EventBus, "challenge_succeeded")


func test_lowercase_letters_count() -> void:
	_start_live()
	_cm.submit_typed_letter(_word()[0].to_lower())
	assert_signal_emitted_with_parameters(EventBus, "letter_accepted", [_id(), _word()[0], 0])


func test_non_letters_are_ignored() -> void:
	_start_live()
	_type("3 !")
	assert_signal_not_emitted(EventBus, "letter_rejected")


func test_backspace_removes_the_last_accepted_letter() -> void:
	_start_live()
	_type(_word().left(2))
	_cm.delete_typed_letter()
	assert_signal_emitted_with_parameters(EventBus, "letter_removed", [_id(), 1])
	_cm.submit_typed_letter(_word()[1])
	assert_signal_emitted_with_parameters(EventBus, "letter_accepted", [_id(), _word()[1], 1])


func test_backspace_with_nothing_typed_does_nothing() -> void:
	_start_live()
	_cm.delete_typed_letter()
	assert_signal_not_emitted(EventBus, "letter_removed")


# Failing


func test_timeout_fails_the_challenge() -> void:
	_start_live()
	_type(_word()[0])
	_wait(12.0)
	assert_signal_emitted_with_parameters(EventBus, "timer_ticked", [_id(), 0.0])
	assert_signal_emitted_with_parameters(
		EventBus, "challenge_failed", [_id(), "timeout", 1, _word().length()]
	)
	assert_signal_emitted_with_parameters(EventBus, "retry_offered", [_id()])
	assert_eq(_cm.get_state(), "retry_offered")


func test_letters_after_time_ran_out_fail_instead_of_succeeding() -> void:
	_start_live()
	Clock.advance(12.5)  # No tick yet, as if the frame had not run.
	_type(_word())
	assert_signal_emitted(EventBus, "challenge_failed")
	assert_signal_not_emitted(EventBus, "challenge_succeeded")


func test_give_up_fails_with_its_reason() -> void:
	_start_live()
	_type(_word()[0])
	_cm.give_up()
	assert_signal_emitted_with_parameters(
		EventBus, "challenge_failed", [_id(), "gave_up", 1, _word().length()]
	)
	assert_eq(_cm.get_state(), "retry_offered")


# Pause


func test_pause_freezes_the_live_timer() -> void:
	_start_live()
	_wait(3.0)
	_cm.set_paused(true)
	_wait(100.0)
	assert_eq(_cm.get_state(), "live", "No timeout while paused")
	_cm.set_paused(false)
	_wait(3.0)
	assert_signal_emitted_with_parameters(EventBus, "timer_ticked", [_id(), 0.5])
	assert_signal_emit_count(EventBus, "paused_changed", 2)


func test_pause_freezes_the_study_timer() -> void:
	_start()
	_cm.set_paused(true)
	_wait(60.0)
	assert_eq(_cm.get_state(), "study")


func test_typing_while_paused_is_ignored() -> void:
	_start_live()
	_cm.set_paused(true)
	_type(_word())
	assert_signal_not_emitted(EventBus, "letter_accepted")


func test_pausing_twice_emits_once() -> void:
	_cm.set_paused(true)
	_cm.set_paused(true)
	assert_signal_emit_count(EventBus, "paused_changed", 1)


# Retry and moving on


func test_retry_replays_the_same_word() -> void:
	_start_live()
	var first_id: String = _id()
	var first_word: String = _word()
	_cm.give_up()
	_cm.retry()
	assert_eq(_cm.get_state(), "study")
	assert_eq(_id(), first_id)
	assert_eq(_word(), first_word)
	assert_signal_emit_count(EventBus, "challenge_created", 1, "A retry is not a new challenge")
	assert_signal_emit_count(EventBus, "study_started", 2)


func test_retry_after_a_timeout_replays_the_same_word() -> void:
	_start_live()
	var first_word: String = _word()
	_wait(12.0)
	_cm.retry()
	assert_eq(_cm.get_state(), "study")
	assert_eq(_word(), first_word)


func test_retry_only_works_after_a_fail() -> void:
	_start_live()
	_type(_word())
	_cm.retry()
	assert_eq(_cm.get_state(), "reward")


func test_declining_a_retry_moves_on() -> void:
	_start_live()
	_cm.give_up()
	_cm.next_challenge()
	assert_signal_emit_count(EventBus, "challenge_created", 2)
	assert_eq(_id(), "c_000002")


func test_next_challenge_is_ignored_while_live() -> void:
	_start_live()
	_cm.next_challenge()
	assert_eq(_cm.get_state(), "live")
	assert_signal_emit_count(EventBus, "challenge_created", 1)


func test_a_full_level_ends_with_level_completed() -> void:
	_start()
	var words: Dictionary = {}
	for _i: int in range(4):
		words[_word()] = true
		_cm.skip_study()
		_type(_word())
		_cm.next_challenge()
	assert_eq(words.size(), 4, "No word repeats inside a level")
	assert_signal_emit_count(EventBus, "challenge_succeeded", 4)
	assert_signal_emitted_with_parameters(EventBus, "level_completed", [QB_LEVEL, 0, 0, false])
	assert_eq(_cm.get_state(), "level_done")


# Bad calls


func test_start_level_needs_a_session() -> void:
	_cm.start_level(QB_LEVEL)
	assert_push_error("start_session")
	assert_signal_not_emitted(EventBus, "level_started")


func test_start_level_is_ignored_mid_challenge() -> void:
	_start_live()
	var id_before: String = _id()
	_cm.start_level(QB_LEVEL)
	assert_eq(_cm.get_state(), "live")
	assert_eq(_id(), id_before)
	assert_signal_emit_count(EventBus, "level_started", 1)


func test_start_level_works_once_the_challenge_has_ended() -> void:
	_start_live()
	_cm.give_up()
	_cm.start_level(QB_LEVEL)
	assert_signal_emit_count(EventBus, "level_started", 2)
	assert_eq(_cm.get_state(), "study")


func test_unknown_level_is_reported() -> void:
	_cm.start_session("qb")
	_cm.start_level("qb.group_9.1")
	assert_push_error("not a qb level")


func test_level_from_the_other_mode_is_reported() -> void:
	_cm.start_session("qb")
	_cm.start_level(WIZARD_LEVEL)
	assert_push_error("not a qb level")


func test_unknown_mode_is_reported() -> void:
	_cm.start_session("chess")
	assert_push_error("unknown mode")
	assert_signal_not_emitted(EventBus, "session_started")
