extends PanelContainer
## The memory bubble over the hero's head. Shows the word (Sign it) or a row of signs (Read it).
##
## A dumb widget: skins call its methods, it never talks to the engine.
## Styles: "stay" stays visible, "fade" fades out, "flash" shows briefly then hides.

const SignCardScene: PackedScene = preload("res://ui/sign_card.tscn")
const STYLE_FADE: String = "fade"
const STYLE_FLASH: String = "flash"
const FLASH_HIDE_SECONDS: float = 0.15

## How long "fade" takes to disappear.
## TODO(M7): this is a difficulty number; it should come from the engine with the challenge.
@export var fade_seconds: float = 2.5
## How long "flash" stays up before it hides.
@export var flash_seconds: float = 0.8
## Size of each sign card inside the bubble.
@export var card_size: Vector2 = Vector2(56, 70)

var _tween: Tween = null
# True between show_* and hide_bubble(), so un-pausing only brings back a bubble that was up.
var _shown: bool = false

@onready var _word: Label = $Content/Word
@onready var _signs: HBoxContainer = $Content/Signs


## Shows [param word] as text (Sign it: the player signs it).
func show_word(word: String) -> void:
	_clear_signs()
	_word.text = word
	_word.visible = true
	_signs.visible = false
	_appear()


## Shows one sign card per letter of [param word], with no letters (Read it: the player types it).
func show_signs(word: String) -> void:
	_clear_signs()
	for letter: String in word:
		var card: Control = SignCardScene.instantiate()
		card.custom_minimum_size = card_size
		card.letter = letter
		card.show_letter = false
		_signs.add_child(card)
	_word.visible = false
	_signs.visible = true
	_appear()


## Switches to [param style]: "stay", "fade" or "flash".
func set_style(style: String) -> void:
	_stop_tween()
	modulate.a = 1.0
	if style == STYLE_FADE:
		_tween = create_tween()
		_tween.tween_property(self, "modulate:a", 0.0, fade_seconds)
	elif style == STYLE_FLASH:
		_tween = create_tween()
		_tween.tween_interval(flash_seconds)
		_tween.tween_property(self, "modulate:a", 0.0, FLASH_HIDE_SECONDS)


## Hides the bubble right away.
func hide_bubble() -> void:
	_stop_tween()
	_shown = false
	visible = false


## While paused the bubble is hidden and its fade stops, so a pause is never extra study time.
func set_paused(paused: bool) -> void:
	if _tween != null and _tween.is_valid():
		if paused:
			_tween.pause()
		else:
			_tween.play()
	visible = _shown and not paused


func _appear() -> void:
	_stop_tween()
	modulate.a = 1.0
	_shown = true
	visible = true


func _stop_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _clear_signs() -> void:
	for card: Node in _signs.get_children():
		_signs.remove_child(card)
		card.queue_free()
