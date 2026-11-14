extends Node
## Loads, migrates and writes the save file (user://save.json).
##
## Stub until M10. See docs/DATA_FORMATS.md, "Save file".


## Reads the save file, migrating or resetting it if needed. TODO(M10)
func load_save() -> void:
	pass


## Writes the save file safely: temp file first, then rename. TODO(M10)
func save_now() -> void:
	pass


## The whole save as a dictionary. Treat it as read-only outside SaveSystem. TODO(M10)
func get_data() -> Dictionary:
	return {}
