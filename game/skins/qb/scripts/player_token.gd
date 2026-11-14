extends Node2D
## A placeholder player: a jersey-colored circle with a trim ring and a number.
## Real art replaces this later. Our league is made up: no real team colors with logos or names.

const TRIM_WIDTH: float = 3.0
const NUMBER_FONT_SIZE: int = 16

@export var jersey_color: Color = Color.WHITE:
	set(value):
		jersey_color = value
		queue_redraw()
@export var trim_color: Color = Color.WHITE:
	set(value):
		trim_color = value
		queue_redraw()
@export var number: int = 0:
	set(value):
		number = value
		queue_redraw()
@export var radius: float = 22.0:
	set(value):
		radius = value
		queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius + TRIM_WIDTH, trim_color)
	draw_circle(Vector2.ZERO, radius, jersey_color)
	var font: Font = ThemeDB.fallback_font
	var text: String = str(number)
	var text_size: Vector2 = font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE
	)
	var baseline: Vector2 = Vector2(-text_size.x / 2.0, text_size.y / 4.0)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE, trim_color)
