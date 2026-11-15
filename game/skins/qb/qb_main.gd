extends Control
## The QB skin. Turns EventBus signals into football and the player's input into Game calls.
##
## This is the only QB script that touches EventBus or Game. The field and the views only
## have methods and their own button signals. See docs/ARCHITECTURE.md, "Skins".

const MENU_SCENE: String = "res://skins/menu/main_menu.tscn"
const DEBUG_SCENE: String = "res://skins/debug/debug_main.tscn"
const MODE: String = "qb"
## TODO(M7): ask the engine for level ids (Game.get_level_ids) instead of building them here.
const LEVEL_ID_FORMAT: String = "qb.group_1.%d"
const DRIVES_IN_SEASON: int = 4
const SIGN_IT: String = "sign_it"
## How long a touchdown or gain stays up before the next huddle starts by itself.
const AUTO_NEXT_SECONDS: float = 2.0

var _drive: int = 1
var _drive_points: int = 0
var _challenge: Dictionary = {}
var _auto_next_pending: bool = false
# Each celebration gets a new number, so an old timer can never skip a later play.
var _auto_next_token: int = 0
var _paused: bool = false
var _drive_done: bool = false
var _engine_signals: Dictionary = {}

@onready var _field: Node2D = $Field
@onready var _bubble: PanelContainer = %MemoryBubble
@onready var _slots: HBoxContainer = %LetterSlots
@onready var _pocket: ProgressBar = %PocketTimer
@onready var _hud: HBoxContainer = %Hud
@onready var _huddle: Control = %HuddleView
@onready var _outcome: Control = %OutcomeView
@onready var _pause_overlay: Control = %PauseOverlay


func _ready() -> void:
	_connect_views()
	_engine_signals = {
		EventBus.level_started: _on_level_started,
		EventBus.challenge_created: _on_challenge_created,
		EventBus.study_started: _on_study_started,
		EventBus.live_started: _on_live_started,
		EventBus.timer_ticked: _on_timer_ticked,
		EventBus.bubble_style_changed: _on_bubble_style_changed,
		EventBus.letter_accepted: _on_letter_accepted,
		EventBus.letter_rejected: _on_letter_rejected,
		EventBus.letter_removed: _on_letter_removed,
		EventBus.challenge_succeeded: _on_challenge_succeeded,
		EventBus.challenge_failed: _on_challenge_failed,
		EventBus.retry_offered: _on_retry_offered,
		EventBus.level_completed: _on_level_completed,
		EventBus.paused_changed: _on_paused_changed,
	}
	for engine_signal: Signal in _engine_signals:
		engine_signal.connect(_engine_signals[engine_signal])
	Game.start_session(MODE)
	_start_drive(1)


func _exit_tree() -> void:
	for engine_signal: Signal in _engine_signals:
		if engine_signal.is_connected(_engine_signals[engine_signal]):
			engine_signal.disconnect(_engine_signals[engine_signal])
	# A pause must not stick around after we leave.
	Game.set_paused(false)


func _connect_views() -> void:
	_huddle.ready_pressed.connect(Game.skip_study)
	_outcome.retry_pressed.connect(Game.retry)
	_outcome.next_play_pressed.connect(Game.next_challenge)
	_outcome.next_drive_pressed.connect(_on_next_drive_pressed)
	_outcome.menu_pressed.connect(_go_to.bind(MENU_SCENE))
	%ResumeButton.pressed.connect(Game.set_paused.bind(false))
	%PauseMenuButton.pressed.connect(_go_to.bind(MENU_SCENE))


func _unhandled_input(event: InputEvent) -> void:
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	var left_click: bool = (
		mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	)
	if left_click and _auto_next_pending:
		_auto_next()
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	# Get the viewport now: F9 changes scene, which takes this node out of the tree at once.
	var viewport: Viewport = get_viewport()
	if _handle_key(key):
		viewport.set_input_as_handled()


# Returns true if the key did something.
func _handle_key(key: InputEventKey) -> bool:
	match key.keycode:
		KEY_ESCAPE:
			Game.set_paused(not _paused)
		KEY_F9:
			_go_to(DEBUG_SCENE)
		KEY_BACKSPACE:
			Game.delete_typed_letter()
		KEY_SPACE, KEY_ENTER:
			_on_continue_key()
		_:
			return _handle_letter(key)
	return true


func _handle_letter(key: InputEventKey) -> bool:
	var typed: String = char(key.unicode).to_upper() if key.unicode > 0 else ""
	if typed.length() != 1 or typed < "A" or typed > "Z":
		return false
	# R retries after a sack; during a play every letter is part of the word.
	if typed == "R" and _outcome.is_offering_retry():
		Game.retry()
	else:
		Game.submit_typed_letter(typed)
	return true


# Space and Enter: snap from the huddle, skip the celebration, or move on.
func _on_continue_key() -> void:
	if _huddle.visible:
		Game.skip_study()
	elif _auto_next_pending:
		_auto_next()
	elif _drive_done:
		_on_next_drive_pressed()
	elif _outcome.visible:
		Game.next_challenge()


func _start_drive(drive: int) -> void:
	_drive = drive
	_drive_done = false
	Game.start_level(LEVEL_ID_FORMAT % drive)


func _on_next_drive_pressed() -> void:
	if _drive < DRIVES_IN_SEASON:
		_start_drive(_drive + 1)
	else:
		_go_to(MENU_SCENE)


func _go_to(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)


func _auto_next() -> void:
	if not _auto_next_pending:
		return
	_auto_next_pending = false
	Game.next_challenge()


# While paused, the celebration waits for Space or a click instead.
func _on_auto_next_timeout(token: int) -> void:
	if token == _auto_next_token and not _paused:
		_auto_next()


# Engine signals


func _on_level_started(_level_id: String, _level_index: int, _is_boss: bool) -> void:
	_drive_points = 0
	_hud.set_points(0)


func _on_challenge_created(challenge: Dictionary) -> void:
	_challenge = challenge
	_hud.set_play(_drive, int(challenge["index_in_level"]) + 1, int(challenge["level_size"]))


func _on_study_started(_challenge_id: String, seconds: float) -> void:
	_auto_next_pending = false
	_outcome.hide_view()
	_bubble.hide_bubble()
	_slots.visible = false
	_pocket.visible = false
	_field.reset_formation()
	_huddle.show_huddle(_challenge["word"], seconds)


func _on_live_started(_challenge_id: String, _seconds: float, bubble_style: String) -> void:
	_huddle.hide_view()
	var word: String = _challenge["word"]
	if _challenge["direction"] == SIGN_IT:
		_bubble.show_word(word)
	else:
		_bubble.show_signs(word)
	_bubble.set_style(bubble_style)
	_slots.setup(word.length())
	_slots.visible = true
	_pocket.set_ratio(1.0)
	_pocket.visible = true


func _on_timer_ticked(_challenge_id: String, remaining_ratio: float) -> void:
	_pocket.set_ratio(remaining_ratio)
	_field.set_rush(1.0 - remaining_ratio)


func _on_bubble_style_changed(_challenge_id: String, bubble_style: String) -> void:
	_bubble.set_style(bubble_style)


func _on_letter_accepted(_challenge_id: String, letter: String, index: int) -> void:
	_slots.set_letter(index, letter)


func _on_letter_rejected(_challenge_id: String, _letter: String, index: int) -> void:
	_slots.reject(index)


func _on_letter_removed(_challenge_id: String, index: int) -> void:
	_slots.clear_from(index)


func _on_challenge_succeeded(_challenge_id: String, result: Dictionary) -> void:
	var fast: bool = result["grade"] == "fast"
	_bubble.hide_bubble()
	_pocket.visible = false
	_field.throw(fast)
	_drive_points += int(result["points"])
	_hud.set_points(_drive_points)
	_outcome.show_success(fast, int(result["points"]), int(result["combo"]))
	_auto_next_pending = true
	_auto_next_token += 1
	var timer: SceneTreeTimer = get_tree().create_timer(AUTO_NEXT_SECONDS)
	timer.timeout.connect(_on_auto_next_timeout.bind(_auto_next_token))


func _on_challenge_failed(
	_challenge_id: String, reason: String, letters_correct: int, letters_total: int
) -> void:
	_bubble.hide_bubble()
	_pocket.visible = false
	_field.sack()
	_outcome.show_fail(reason, letters_correct, letters_total)


func _on_retry_offered(_challenge_id: String) -> void:
	_outcome.offer_retry()


func _on_level_completed(_level_id: String, _stars: int, _coins: int, _perfect: bool) -> void:
	_auto_next_pending = false
	_drive_done = true
	_slots.visible = false
	_outcome.show_drive_done(_drive_points, _drive < DRIVES_IN_SEASON)


func _on_paused_changed(paused: bool) -> void:
	_paused = paused
	_pause_overlay.visible = paused
	_huddle.set_paused(paused)
	_bubble.set_paused(paused)
