extends Control
## The main menu: pick a mode. Wizard mode is off until M9. F9 opens the debug skin.
##
## The QB skin starts its own session, so the menu only changes scenes.

const QB_SCENE: String = "res://skins/qb/qb_main.tscn"
const DEBUG_SCENE: String = "res://skins/debug/debug_main.tscn"


func _ready() -> void:
	%QbButton.pressed.connect(_go_to.bind(QB_SCENE))
	%QuitButton.pressed.connect(get_tree().quit)
	%QbButton.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_F9:
		get_viewport().set_input_as_handled()
		_go_to(DEBUG_SCENE)


func _go_to(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
