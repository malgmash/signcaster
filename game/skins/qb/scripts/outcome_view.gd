extends Control
## The result of a play (touchdown, short gain, sack) and the end of a drive.
##
## qb_main.gd calls the show_ methods and listens to the button signals.
## This script never talks to the engine.

signal retry_pressed
signal next_play_pressed
signal next_drive_pressed
signal menu_pressed

const FAST_BANNER: String = "TOUCHDOWN!"
const SLOW_BANNER: String = "SHORT GAIN"
const FAIL_BANNER: String = "SACKED!"
const DRIVE_BANNER: String = "DRIVE COMPLETE"
const NEAR_MISS_TEXT: String = "1 letter away!"
const FAIL_REASONS: Dictionary = {
	"timeout": "The pocket collapsed before you finished.",
	"gave_up": "You called off the play.",
}
const FAST_COLOR: Color = Color(1.0, 0.85, 0.3)
const SLOW_COLOR: Color = Color(0.75, 0.95, 0.8)
const FAIL_COLOR: Color = Color(1.0, 0.45, 0.4)
const POP_START_SCALE: float = 0.4
const POP_SECONDS: float = 0.3

@onready var _box: VBoxContainer = %Box
@onready var _banner: Label = %Banner
@onready var _detail: Label = %Detail
@onready var _near_miss: Label = %NearMiss
@onready var _hint: Label = %Hint
@onready var _retry: Button = %RetryButton
@onready var _next_play: Button = %NextPlayButton
@onready var _next_drive: Button = %NextDriveButton
@onready var _menu: Button = %MenuButton


func _ready() -> void:
	_retry.pressed.connect(retry_pressed.emit)
	_next_play.pressed.connect(next_play_pressed.emit)
	_next_drive.pressed.connect(next_drive_pressed.emit)
	_menu.pressed.connect(menu_pressed.emit)


## A completed pass. [param fast] means a touchdown, otherwise a short gain.
func show_success(fast: bool, points: int, combo: int) -> void:
	var combo_text: String = "   combo x%d" % combo if combo > 1 else ""
	_show(FAST_BANNER if fast else SLOW_BANNER, FAST_COLOR if fast else SLOW_COLOR)
	_detail.text = "+%d points%s" % [points, combo_text]
	_hint.visible = true


## A sack. Shows "1 letter away!" when only one letter was missing.
func show_fail(reason: String, letters_correct: int, letters_total: int) -> void:
	_show(FAIL_BANNER, FAIL_COLOR)
	_detail.text = FAIL_REASONS.get(reason, "")
	_near_miss.visible = letters_total - letters_correct == 1


## Shows Retry and Next play after a sack.
func offer_retry() -> void:
	_retry.visible = true
	_next_play.visible = true


## True while Retry is on screen.
func is_offering_retry() -> bool:
	return visible and _retry.visible


## The drive is over. [param has_next_drive] shows the Next drive button.
func show_drive_done(points: int, has_next_drive: bool) -> void:
	_show(DRIVE_BANNER, FAST_COLOR)
	_detail.text = "%d points this drive" % points
	_next_drive.visible = has_next_drive
	_menu.visible = true


## Hides the result.
func hide_view() -> void:
	visible = false


func _show(banner: String, color: Color) -> void:
	_banner.text = banner
	_banner.add_theme_color_override("font_color", color)
	_detail.text = ""
	_near_miss.visible = false
	_hint.visible = false
	for button: Button in [_retry, _next_play, _next_drive, _menu]:
		button.visible = false
	visible = true
	_box.pivot_offset = _box.size / 2.0
	_box.scale = Vector2.ONE * POP_START_SCALE
	var pop: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(_box, "scale", Vector2.ONE, POP_SECONDS)
