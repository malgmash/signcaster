extends Control
## The huddle (study phase): teammates in a ring, the play call, and the play card with the
## word and its signs. Ready skips the rest of the study time.
##
## qb_main.gd calls show_huddle() and hide_view(); this script never talks to the engine.

signal ready_pressed

const PlayCall = preload("res://skins/qb/scripts/play_call.gd")
const PlayerToken = preload("res://skins/qb/scripts/player_token.gd")
const SignCardScene: PackedScene = preload("res://ui/sign_card.tscn")

const RING_PLAYERS: int = 7
const RING_RADIUS: float = 95.0
## The first number is the QB, at the top of the ring.
const RING_NUMBERS: Array[int] = [7, 72, 65, 50, 61, 77, 88]
const RING_COLOR: Color = Color(0.05, 0.62, 0.33)
const RING_TRIM: Color = Color(0.97, 0.97, 0.97)
const FADE_IN_SECONDS: float = 0.25

var _study_tween: Tween = null

@onready var _ring: Node2D = $Ring
@onready var _call_label: Label = %CallLabel
@onready var _word_label: Label = %WordLabel
@onready var _signs: HBoxContainer = %Signs
@onready var _study_bar: ProgressBar = %StudyBar


func _ready() -> void:
	%ReadyButton.pressed.connect(ready_pressed.emit)
	for i: int in range(RING_PLAYERS):
		var token: Node2D = PlayerToken.new()
		token.jersey_color = RING_COLOR
		token.trim_color = RING_TRIM
		token.number = RING_NUMBERS[i]
		token.position = Vector2.from_angle(TAU * i / RING_PLAYERS - PI / 2.0) * RING_RADIUS
		_ring.add_child(token)


## Shows the huddle for [param word]. [param seconds] is the study time, 0 for untimed.
func show_huddle(word: String, seconds: float) -> void:
	_call_label.text = PlayCall.build(word)
	_word_label.text = word
	for card: Node in _signs.get_children():
		card.queue_free()
	for letter: String in word:
		var card: Control = SignCardScene.instantiate()
		card.letter = letter
		_signs.add_child(card)
	_run_study_bar(seconds)
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, FADE_IN_SECONDS)


## Hides the huddle.
func hide_view() -> void:
	_stop_study_bar()
	visible = false


func _run_study_bar(seconds: float) -> void:
	_stop_study_bar()
	_study_bar.value = 1.0
	_study_bar.visible = seconds > 0.0
	if seconds > 0.0:
		_study_tween = create_tween()
		_study_tween.tween_property(_study_bar, "value", 0.0, seconds)


func _stop_study_bar() -> void:
	if _study_tween != null and _study_tween.is_valid():
		_study_tween.kill()
	_study_tween = null
