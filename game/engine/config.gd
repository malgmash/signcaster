extends Node
## Loads the JSON content in res://content and hands it out through typed getters.
##
## scripts/validate_content.py checks the shape of every file. Config only checks that each
## file exists, parses, and has a version this code understands (docs/DATA_FORMATS.md).
## Treat the returned dictionaries as read-only.

const CONTENT_DIR: String = "res://content"
const SUPPORTED_VERSION: int = 1
const MODES: PackedStringArray = ["qb", "wizard"]

var _difficulty: Dictionary = {}
var _scoring: Dictionary = {}
var _economy: Dictionary = {}
var _catalogs: Dictionary = {}
var _word_packs: Array[Dictionary] = []
var _load_errors: PackedStringArray = []


func _ready() -> void:
	load_from(CONTENT_DIR)


## Loads every content file under [param content_dir]. Returns true if nothing went wrong.
func load_from(content_dir: String) -> bool:
	_load_errors.clear()
	_difficulty = _load_json(content_dir.path_join("config/difficulty.json"))
	_scoring = _load_json(content_dir.path_join("config/scoring.json"))
	_economy = _load_json(content_dir.path_join("config/economy.json"))
	_catalogs = {}
	for mode: String in MODES:
		_catalogs[mode] = _load_json(content_dir.path_join("store/%s_catalog.json" % mode))
	_word_packs = _load_word_packs(content_dir.path_join("word_packs"))
	return _load_errors.is_empty()


## The difficulty config: modes, tiers, groups, adaptive and review settings.
func get_difficulty() -> Dictionary:
	return _difficulty


## The scoring config: thresholds, points and star rules.
func get_scoring() -> Dictionary:
	return _scoring


## The economy config: coin rewards and streak freezes.
func get_economy() -> Dictionary:
	return _economy


## Every word pack, sorted by file name.
func get_word_packs() -> Array[Dictionary]:
	return _word_packs


## The store catalog for [param mode] ("qb" or "wizard"), or an empty dictionary.
func get_store_catalog(mode: String) -> Dictionary:
	return _catalogs.get(mode, {})


## Problems found by the last load. Empty means all content loaded.
func get_load_errors() -> PackedStringArray:
	return _load_errors.duplicate()


func _load_word_packs(folder: String) -> Array[Dictionary]:
	var packs: Array[Dictionary] = []
	if not DirAccess.dir_exists_absolute(folder):
		_report("%s is missing" % folder)
		return packs
	var files: PackedStringArray = DirAccess.get_files_at(folder)
	files.sort()
	for file_name: String in files:
		if file_name.get_extension() != "json":
			continue
		var pack: Dictionary = _load_json(folder.path_join(file_name))
		if not pack.is_empty():
			packs.append(pack)
	if packs.is_empty():
		_report("%s has no word packs" % folder)
	return packs


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_report("%s is missing" % path)
		return {}
	var json: JSON = JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		var line: int = json.get_error_line()
		_report("%s is not valid JSON (line %d: %s)" % [path, line, json.get_error_message()])
		return {}
	if not json.data is Dictionary:
		_report("%s must contain a JSON object" % path)
		return {}
	var data: Dictionary = json.data
	var version: Variant = data.get("version")
	if not (version is float or version is int) or int(version) != SUPPORTED_VERSION:
		_report("%s has version %s, expected %d" % [path, str(version), SUPPORTED_VERSION])
		return {}
	return data


func _report(message: String) -> void:
	_load_errors.append(message)
	push_error("Config: %s" % message)
