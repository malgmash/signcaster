extends ProgressBar
## A timer bar that turns from green to amber to red as time runs out.
##
## A dumb widget: skins call set_ratio() with the engine's remaining_ratio.

const CORNER_RADIUS: int = 4

## Below this ratio the bar turns amber.
@export var warn_below: float = 0.5
## Below this ratio the bar turns red.
@export var danger_below: float = 0.25
@export var safe_color: Color = Color(0.3, 0.75, 0.35)
@export var warn_color: Color = Color(0.95, 0.7, 0.2)
@export var danger_color: Color = Color(0.9, 0.25, 0.2)

var _fill: StyleBoxFlat = StyleBoxFlat.new()


func _ready() -> void:
	min_value = 0.0
	max_value = 1.0
	step = 0.0
	show_percentage = false
	_fill.set_corner_radius_all(CORNER_RADIUS)
	add_theme_stylebox_override("fill", _fill)
	set_ratio(1.0)


## Shows [param ratio] of the time left, from 1.0 (full) to 0.0 (empty).
func set_ratio(ratio: float) -> void:
	value = ratio
	if ratio < danger_below:
		_fill.bg_color = danger_color
	elif ratio < warn_below:
		_fill.bg_color = warn_color
	else:
		_fill.bg_color = safe_color
