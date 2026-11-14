extends Node
## The challenge state machine: study, live, result. Timers, input checking and grading.
##
## See docs/ARCHITECTURE.md, "Challenge lifecycle", "Grading and points" and "Input checking".
## Every transition emits the matching EventBus signal from docs/EVENTS.md.
## Time comes only from Clock, so tests can step it with Clock.advance() and tick().

const STATE_IDLE: String = "idle"
const STATE_STUDY: String = "study"
const STATE_LIVE: String = "live"
const STATE_SUCCEEDED: String = "succeeded"
const STATE_FAILED: String = "failed"
const STATE_RETRY_OFFERED: String = "retry_offered"
const STATE_REWARD: String = "reward"
const STATE_LEVEL_DONE: String = "level_done"

const DIRECTION_READ_IT: String = "read_it"
const REASON_TIMEOUT: String = "timeout"
const REASON_GAVE_UP: String = "gave_up"
const GRADE_FAST: String = "fast"
const GRADE_SLOW: String = "slow"
const GRADE_FAIL: String = "fail"
const ID_FORMAT: String = "c_%06d"
const LETTERS: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

var _state: String = STATE_IDLE
var _mode: String = ""
var _level_id: String = ""
var _level_words: Array[Dictionary] = []
var _word_index: int = -1
var _challenge: Dictionary = {}
var _typed: String = ""
var _challenges_made: int = 0
var _fast_streak: int = 0

var _paused: bool = false
var _phase_started_at: float = 0.0
var _paused_total: float = 0.0
var _paused_at: float = 0.0


func _process(_delta: float) -> void:
	tick()


## Starts a session in [param mode] ("qb" or "wizard").
func start_session(mode: String) -> void:
	if not Config.MODES.has(mode):
		push_error("ChallengeManager: unknown mode '%s'" % mode)
		return
	_mode = mode
	_challenges_made = 0
	_level_id = ""
	_state = STATE_IDLE
	# TODO(M8): pass the equipped skin variant once skins have them.
	EventBus.session_started.emit(mode, mode)


## Begins the level [param level_id] and its first challenge.
func start_level(level_id: String) -> void:
	if _mode.is_empty():
		push_error("ChallengeManager: call start_session() before start_level()")
		return
	# Starting over mid-challenge would leave the skin showing a timer that never ends.
	if _state == STATE_STUDY or _state == STATE_LIVE:
		push_warning("ChallengeManager: give up or finish the challenge before start_level()")
		return
	var tier: Dictionary = Difficulty.get_tier(level_id)
	if tier.is_empty() or level_id.get_slice(".", 0) != _mode:
		push_error("ChallengeManager: '%s' is not a %s level" % [level_id, _mode])
		return
	_level_words = WordBank.pick_words(tier, _mode, Difficulty.challenges_for(tier))
	if _level_words.is_empty():
		push_error("ChallengeManager: no words fit level '%s'" % level_id)
		return
	_level_id = level_id
	_word_index = -1
	_fast_streak = 0
	_state = STATE_IDLE
	var is_boss: bool = tier.get("is_boss", false)
	EventBus.level_started.emit(level_id, Difficulty.get_level_index(level_id), is_boss)
	_advance()


## Goes to the next challenge after a result, or finishes the level after the last one.
func next_challenge() -> void:
	if _state != STATE_REWARD and _state != STATE_RETRY_OFFERED:
		return
	# A declined retry passes through Reward on its way on (see the lifecycle diagram).
	_state = STATE_REWARD
	_advance()


## Ends the study phase early and starts the live timer.
func skip_study() -> void:
	if _state == STATE_STUDY and not _paused:
		_start_live()


## Checks a typed letter against the next expected letter (Read it).
func submit_typed_letter(letter: String) -> void:
	if not _accepts_typing():
		return
	var typed: String = letter.to_upper()
	if typed.length() != 1 or not LETTERS.contains(typed):
		return
	if _time_left() <= 0.0:
		_fail(REASON_TIMEOUT)
		return
	var word: String = _challenge["word"]
	var index: int = _typed.length()
	if typed != word[index]:
		EventBus.letter_rejected.emit(_challenge["id"], typed, index)
		return
	_typed += typed
	EventBus.letter_accepted.emit(_challenge["id"], typed, index)
	if _typed.length() == word.length():
		_succeed()


## Removes the last accepted letter (Read it only).
func delete_typed_letter() -> void:
	if not _accepts_typing() or _typed.is_empty():
		return
	_typed = _typed.left(-1)
	EventBus.letter_removed.emit(_challenge["id"], _typed.length())


## Checks a letter from the tracker. Wrong letters are ignored (Sign it). TODO(M6)
func on_signed_letter(_letter: String) -> void:
	pass


## Ends the live challenge as a fail with reason "gave_up".
func give_up() -> void:
	if _state == STATE_LIVE:
		_fail(REASON_GAVE_UP)


## Restarts the last failed challenge from its study phase, with the same word.
func retry() -> void:
	if _state == STATE_RETRY_OFFERED:
		_start_study()


## Freezes or resumes the study and live timers. Input is ignored while paused.
func set_paused(paused: bool) -> void:
	if paused == _paused:
		return
	if paused:
		_paused_at = Clock.now()
	else:
		_paused_total += Clock.now() - _paused_at
	_paused = paused
	EventBus.paused_changed.emit(paused)


## Runs the timers. Called every frame; tests call it after Clock.advance().
func tick() -> void:
	if _paused:
		return
	if _state == STATE_STUDY:
		var study_seconds: float = _challenge["study_seconds"]
		if study_seconds > 0.0 and _phase_elapsed() >= study_seconds:
			_start_live()
	elif _state == STATE_LIVE:
		var time_left: float = _time_left()
		var live_seconds: float = _challenge["live_seconds"]
		EventBus.timer_ticked.emit(_challenge["id"], maxf(time_left, 0.0) / live_seconds)
		if time_left <= 0.0:
			_fail(REASON_TIMEOUT)


## Grades a success. [param prior_fasts] is the fast streak before this challenge.
## Returns the result dictionary from EVENTS.md.
func grade_result(time_left: float, live_seconds: float, prior_fasts: int) -> Dictionary:
	var scoring: Dictionary = Config.get_scoring()
	var ratio: float = time_left / live_seconds
	var is_fast: bool = ratio >= float(scoring["fast_threshold"])
	var multiplier: float = minf(
		1.0 + float(scoring["combo_step"]) * prior_fasts, float(scoring["combo_cap"])
	)
	return {
		"grade": GRADE_FAST if is_fast else GRADE_SLOW,
		"remaining_ratio": ratio,
		"time_used": live_seconds - time_left,
		"points": roundi(float(scoring["base_points"]) * (1.0 + ratio) * multiplier),
		"combo": prior_fasts + 1 if is_fast else 0,
		"coins": 0,  # TODO(M8): Economy pays coins_per_success and fast_bonus.
	}


## The current state name, for the debug skin and tests.
func get_state() -> String:
	return _state


## The current challenge dictionary (see EVENTS.md), or {} before the first one.
func get_challenge() -> Dictionary:
	return _challenge


## True while the timers are frozen.
func is_paused() -> bool:
	return _paused


func _advance() -> void:
	_word_index += 1
	if _word_index >= _level_words.size():
		_state = STATE_LEVEL_DONE
		# TODO(M8): stars, coins and perfect come from Economy.
		EventBus.level_completed.emit(_level_id, 0, 0, false)
		return
	_challenge = _make_challenge(_level_words[_word_index])
	_state = STATE_IDLE
	EventBus.challenge_created.emit(_challenge)
	_start_study()


func _make_challenge(entry: Dictionary) -> Dictionary:
	var tier: Dictionary = Difficulty.get_tier(_level_id)
	_challenges_made += 1
	var twist: Variant = tier.get("twist")
	return {
		"id": ID_FORMAT % _challenges_made,
		"word": str(entry["word"]),
		"word_id": str(entry["id"]),
		# TODO(M6): pick from tier.directions and fall back to read_it without the tracker.
		"direction": DIRECTION_READ_IT,
		"study_seconds": Difficulty.study_seconds_for(_mode),
		"live_seconds": Difficulty.live_seconds_for(tier, _mode),
		"bubble_style": Difficulty.bubble_style_for(tier, _mode),
		"is_review": false,  # TODO(M7): true when WordBank picked it for review.
		"twist": "" if twist == null else str(twist),
	}


func _start_study() -> void:
	_typed = ""
	_state = STATE_STUDY
	_restart_phase_clock()
	EventBus.study_started.emit(_challenge["id"], _challenge["study_seconds"])


func _start_live() -> void:
	EventBus.study_ended.emit(_challenge["id"])
	_state = STATE_LIVE
	_restart_phase_clock()
	EventBus.live_started.emit(
		_challenge["id"], _challenge["live_seconds"], _challenge["bubble_style"]
	)


func _succeed() -> void:
	var result: Dictionary = grade_result(_time_left(), _challenge["live_seconds"], _fast_streak)
	_fast_streak = result["combo"]
	_state = STATE_SUCCEEDED
	_record(result["grade"], true)
	EventBus.challenge_succeeded.emit(_challenge["id"], result)
	_state = STATE_REWARD


func _fail(reason: String) -> void:
	_fast_streak = 0
	_state = STATE_FAILED
	_record(GRADE_FAIL, false)
	var word: String = _challenge["word"]
	EventBus.challenge_failed.emit(_challenge["id"], reason, _typed.length(), word.length())
	_state = STATE_RETRY_OFFERED
	EventBus.retry_offered.emit(_challenge["id"])


# Both are no-ops until M7. Wired now so M7 only has to fill them in.
func _record(grade: String, success: bool) -> void:
	Difficulty.record_result(grade)
	WordBank.record_result(_challenge["word_id"], success)


func _accepts_typing() -> bool:
	return _state == STATE_LIVE and not _paused and _challenge["direction"] == DIRECTION_READ_IT


func _restart_phase_clock() -> void:
	_phase_started_at = Clock.now()
	_paused_total = 0.0
	# If the game is paused as a phase starts, that pause only counts from the phase start.
	_paused_at = _phase_started_at


func _phase_elapsed() -> float:
	var paused_now: float = Clock.now() - _paused_at if _paused else 0.0
	return Clock.now() - _phase_started_at - _paused_total - paused_now


func _time_left() -> float:
	return float(_challenge["live_seconds"]) - _phase_elapsed()
