extends HBoxContainer
## One slot per letter of the word. Accepted letters fill in; a wrong letter shakes the row.
##
## A dumb widget: skins call its methods, it never talks to the engine.

const EMPTY_TEXT: String = ""
const SHAKE_PIXELS: float = 10.0
const SHAKE_STEP_SECONDS: float = 0.04
const SHAKE_STEPS: int = 3
const FLASH_SECONDS: float = 0.35
## Letter height as a share of the slot height.
const FONT_SHARE: float = 0.6
const CORNER_RADIUS: int = 6

## Size of each slot.
@export var slot_size: Vector2 = Vector2(48, 56)
@export var slot_color: Color = Color(0.1, 0.12, 0.16, 0.85)
@export var filled_color: Color = Color(0.2, 0.55, 0.3, 0.95)
@export var reject_color: Color = Color(0.85, 0.2, 0.2, 0.95)

var _slots: Array[Label] = []
var _shake: Tween = null


## Builds [param length] empty slots.
func setup(length: int) -> void:
	# Remove first, so old slots never sit next to new ones for a frame.
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_slots.clear()
	for _i: int in range(length):
		var slot: Label = Label.new()
		slot.custom_minimum_size = slot_size
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_theme_font_size_override("font_size", int(slot_size.y * FONT_SHARE))
		slot.add_theme_stylebox_override("normal", _box(slot_color))
		add_child(slot)
		_slots.append(slot)


## Shows [param letter] in slot [param index].
func set_letter(index: int, letter: String) -> void:
	if index < 0 or index >= _slots.size():
		return
	_slots[index].text = letter
	_slots[index].add_theme_stylebox_override("normal", _box(filled_color))


## Empties slot [param index] and every slot after it.
func clear_from(index: int) -> void:
	for i: int in range(maxi(index, 0), _slots.size()):
		_slots[i].text = EMPTY_TEXT
		_slots[i].add_theme_stylebox_override("normal", _box(slot_color))


## A wrong letter for slot [param index]: flash it red and shake the row.
func reject(index: int) -> void:
	if index >= 0 and index < _slots.size():
		var slot: Label = _slots[index]
		slot.add_theme_stylebox_override("normal", _box(reject_color))
		get_tree().create_timer(FLASH_SECONDS).timeout.connect(_unflash.bind(slot))
	_start_shake()


func _unflash(slot: Label) -> void:
	if is_instance_valid(slot) and slot.text == EMPTY_TEXT:
		slot.add_theme_stylebox_override("normal", _box(slot_color))


func _start_shake() -> void:
	if _shake != null and _shake.is_valid():
		return
	var home: float = position.x
	_shake = create_tween()
	for _i: int in range(SHAKE_STEPS):
		_shake.tween_property(self, "position:x", home + SHAKE_PIXELS, SHAKE_STEP_SECONDS)
		_shake.tween_property(self, "position:x", home - SHAKE_PIXELS, SHAKE_STEP_SECONDS)
	_shake.tween_property(self, "position:x", home, SHAKE_STEP_SECONDS)


func _box(color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(CORNER_RADIUS)
	return box
