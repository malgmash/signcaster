extends Control
## The debug skin: plain labels and buttons for playing the engine without art.
##
## Like every skin, it only listens to EventBus and calls Game. It never calls other autoloads,
## so it works out what to show (including the state label) from the signals alone.

const SignCardScene: PackedScene = preload("res://ui/sign_card.tscn")
const MENU_SCENE: String = "res://skins/menu/main_menu.tscn"
## The debug skin only plays the first group for now. Real skins get level ids from the menu.
const LEVEL_ID_FORMAT: String = "%s.group_1.%d"
const READ_IT: String = "read_it"
const HIDDEN_LETTER: String = "?"
const EMPTY_SLOT: String = "_"
const REJECTED_COLOR: Color = Color(0.95, 0.35, 0.35)
const NORMAL_COLOR: Color = Color(0.85, 0.85, 0.88)

var _session_mode: String = ""
var _challenge: Dictionary = {}
var _typed: String = ""
var _state: String = ""
var _engine_signals: Dictionary = {}
var _tracker_status: String = "disconnected"
var _tracker_last: String = "none"
var _tracker_detail: String = ""

@onready var _mode_picker: OptionButton = %ModePicker
@onready var _level_picker: SpinBox = %LevelPicker
@onready var _pause_button: Button = %PauseButton
@onready var _state_label: Label = %StateLabel
@onready var _word_label: Label = %WordLabel
@onready var _cards: HBoxContainer = %Cards
@onready var _typed_label: Label = %TypedLabel
@onready var _time_bar: ProgressBar = %TimeBar
@onready var _time_label: Label = %TimeLabel
@onready var _result_label: Label = %ResultLabel
@onready var _event_label: Label = %EventLabel
@onready var _tracker_label: Label = %TrackerLabel


func _ready() -> void:
	%StartButton.pressed.connect(_on_start_pressed)
	%SkipButton.pressed.connect(Game.skip_study)
	%GiveUpButton.pressed.connect(Game.give_up)
	%RetryButton.pressed.connect(Game.retry)
	%NextButton.pressed.connect(Game.next_challenge)
	_pause_button.toggled.connect(Game.set_paused)
	_connect_engine()


func _connect_engine() -> void:
	_engine_signals = {
		EventBus.session_started: _on_session_started,
		EventBus.level_started: _on_level_started,
		EventBus.level_completed: _on_level_completed,
		EventBus.challenge_created: _on_challenge_created,
		EventBus.study_started: _on_study_started,
		EventBus.live_started: _on_live_started,
		EventBus.timer_ticked: _on_timer_ticked,
		EventBus.letter_accepted: _on_letter_accepted,
		EventBus.letter_rejected: _on_letter_rejected,
		EventBus.letter_removed: _on_letter_removed,
		EventBus.challenge_succeeded: _on_challenge_succeeded,
		EventBus.challenge_failed: _on_challenge_failed,
		EventBus.retry_offered: _on_retry_offered,
		EventBus.paused_changed: _on_paused_changed,
		EventBus.tracker_status_changed: _on_tracker_status_changed,
		EventBus.tracker_message_received: _on_tracker_message_received,
	}
	for engine_signal: Signal in _engine_signals:
		engine_signal.connect(_engine_signals[engine_signal])


func _exit_tree() -> void:
	for engine_signal: Signal in _engine_signals:
		if engine_signal.is_connected(_engine_signals[engine_signal]):
			engine_signal.disconnect(_engine_signals[engine_signal])
	Game.set_paused(false)


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	# Get the viewport now: F9 changes scene, which takes this node out of the tree at once.
	var viewport: Viewport = get_viewport()
	# unicode is the character the keyboard layout produced, so non-QWERTY keyboards work too.
	var typed: String = char(key.unicode).to_upper() if key.unicode > 0 else ""
	if key.keycode == KEY_F9:
		get_tree().change_scene_to_file(MENU_SCENE)
	elif key.keycode == KEY_BACKSPACE:
		Game.delete_typed_letter()
	elif typed.length() == 1 and typed >= "A" and typed <= "Z":
		Game.submit_typed_letter(typed)
	else:
		return
	viewport.set_input_as_handled()


func _on_start_pressed() -> void:
	var mode: String = _mode_picker.get_item_text(_mode_picker.selected)
	if mode != _session_mode:
		Game.start_session(mode)
	Game.start_level(LEVEL_ID_FORMAT % [mode, int(_level_picker.value)])
	# The level SpinBox keeps keyboard focus after a click, which would swallow typed letters.
	get_viewport().gui_release_focus()


# Engine signals


func _on_session_started(mode: String, _skin_id: String) -> void:
	_session_mode = mode
	_show_event("Session started: %s" % mode)


func _on_level_started(level_id: String, level_index: int, is_boss: bool) -> void:
	_result_label.text = " "
	var boss: String = " (boss)" if is_boss else ""
	_show_event("Level %s started, index %d%s" % [level_id, level_index, boss])


func _on_level_completed(level_id: String, stars: int, coins: int, _perfect: bool) -> void:
	_set_state("level done")
	_result_label.text = (
		"Level %s done. Stars %d, coins %d (both come in M8)." % [level_id, stars, coins]
	)


func _on_challenge_created(challenge: Dictionary) -> void:
	_challenge = challenge
	_show_event(
		(
			"Challenge %s (%d of %d): %s"
			% [
				challenge["id"],
				int(challenge["index_in_level"]) + 1,
				int(challenge["level_size"]),
				challenge["direction"],
			]
		)
	)


func _on_study_started(_challenge_id: String, seconds: float) -> void:
	_typed = ""
	_set_state("study (untimed, press Skip study)" if seconds == 0.0 else "study")
	_word_label.text = _challenge["word"]
	_build_cards()
	_refresh_typed()
	_time_bar.value = 1.0
	_time_label.text = (
		"Study: %s" % ("as long as you like" if seconds == 0.0 else "%.0f s" % seconds)
	)


func _on_live_started(_challenge_id: String, seconds: float, bubble_style: String) -> void:
	_set_state("live, bubble %s" % bubble_style)
	if _challenge["direction"] == READ_IT:
		_word_label.text = HIDDEN_LETTER.repeat(str(_challenge["word"]).length())
	_time_label.text = "Time left: %.1f s" % seconds


func _on_timer_ticked(_challenge_id: String, remaining_ratio: float) -> void:
	_time_bar.value = remaining_ratio
	_time_label.text = "Time left: %.1f s" % (remaining_ratio * float(_challenge["live_seconds"]))


func _on_letter_accepted(_challenge_id: String, letter: String, _index: int) -> void:
	_typed += letter
	_refresh_typed()
	_show_event("Accepted %s" % letter)


func _on_letter_rejected(_challenge_id: String, letter: String, index: int) -> void:
	_show_event("Wrong letter %s for slot %d" % [letter, index + 1], REJECTED_COLOR)


func _on_letter_removed(_challenge_id: String, index: int) -> void:
	_typed = _typed.left(index)
	_refresh_typed()
	_show_event("Removed slot %d" % (index + 1))


func _on_challenge_succeeded(_challenge_id: String, result: Dictionary) -> void:
	_set_state("succeeded, press Next")
	_word_label.text = _challenge["word"]
	_result_label.text = (
		"%s! %d points, combo %d, %.0f%% time left"
		% [
			str(result["grade"]).to_upper(),
			result["points"],
			result["combo"],
			float(result["remaining_ratio"]) * 100.0
		]
	)


func _on_challenge_failed(_challenge_id: String, reason: String, correct: int, total: int) -> void:
	_set_state("failed")
	_word_label.text = _challenge["word"]
	_result_label.text = "Failed (%s), %d of %d letters." % [reason, correct, total]


func _on_retry_offered(_challenge_id: String) -> void:
	_set_state("failed, press Retry or Next")


func _on_paused_changed(paused: bool) -> void:
	_pause_button.set_pressed_no_signal(paused)
	_pause_button.text = "Resume" if paused else "Pause"
	_refresh_state_label(paused)


func _on_tracker_status_changed(status: String) -> void:
	_tracker_status = status
	if status == "disconnected":
		_tracker_detail = ""
	_refresh_tracker()


func _on_tracker_message_received(message_type: String, detail: String) -> void:
	_tracker_last = message_type
	if message_type == "status":
		_tracker_detail = detail
	_refresh_tracker()


# Drawing


func _refresh_tracker() -> void:
	var problem: String = "" if _tracker_detail.is_empty() else ", %s" % _tracker_detail
	_tracker_label.text = "Tracker: %s (last: %s%s)" % [_tracker_status, _tracker_last, problem]


func _build_cards() -> void:
	for card: Node in _cards.get_children():
		card.queue_free()
	for letter: String in str(_challenge["word"]):
		var card: Node = SignCardScene.instantiate()
		card.letter = letter
		_cards.add_child(card)


func _refresh_typed() -> void:
	var word_length: int = str(_challenge.get("word", "")).length()
	var slots: PackedStringArray = []
	for letter: String in _typed + EMPTY_SLOT.repeat(word_length - _typed.length()):
		slots.append(letter)
	_typed_label.text = " ".join(slots)


func _set_state(state: String) -> void:
	_state = state
	_refresh_state_label(_pause_button.button_pressed)


func _refresh_state_label(paused: bool) -> void:
	_state_label.text = "State: %s%s" % [_state, " (paused)" if paused else ""]


func _show_event(text: String, color: Color = NORMAL_COLOR) -> void:
	_event_label.text = text
	_event_label.add_theme_color_override("font_color", color)
