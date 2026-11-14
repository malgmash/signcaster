extends GutTest
## Config loads the real content, and reports files that are missing, broken or the wrong version.

const ConfigScript = preload("res://engine/config.gd")
const REAL_CONTENT: String = "res://content"
const BAD_CONTENT: String = "res://tests/fixtures/bad_content"
const NO_CONTENT: String = "res://tests/fixtures/does_not_exist"
## 3 config files, 2 store catalogs and the word_packs folder.
const FILES_IN_A_FULL_LOAD: int = 6


func _new_config() -> Node:
	return autofree(ConfigScript.new())


func test_autoload_loaded_the_real_content() -> void:
	assert_eq(Config.get_load_errors(), PackedStringArray())
	assert_false(Config.get_word_packs().is_empty())


func test_real_content_has_every_file() -> void:
	var config: Node = _new_config()
	assert_true(config.load_from(REAL_CONTENT))
	assert_true(config.get_difficulty().has("tiers"))
	assert_true(config.get_scoring().has("base_points"))
	assert_true(config.get_economy().has("coins_per_success"))
	for mode: String in ConfigScript.MODES:
		assert_eq(config.get_store_catalog(mode).get("mode"), mode)


func test_every_word_pack_has_words() -> void:
	var config: Node = _new_config()
	config.load_from(REAL_CONTENT)
	for pack: Dictionary in config.get_word_packs():
		assert_false(pack.get("words", []).is_empty(), "Pack '%s' has no words" % pack.get("id"))


func test_unknown_mode_gives_an_empty_catalog() -> void:
	var config: Node = _new_config()
	config.load_from(REAL_CONTENT)
	assert_eq(config.get_store_catalog("pirate"), {})


func test_bad_content_reports_each_problem() -> void:
	var config: Node = _new_config()
	assert_false(config.load_from(BAD_CONTENT))
	assert_eq(config.get_load_errors().size(), 3)
	assert_push_error("economy.json is missing")
	assert_push_error("scoring.json has version 2")
	assert_push_error("broken.json is not valid JSON")


func test_bad_content_still_loads_the_good_files() -> void:
	var config: Node = _new_config()
	config.load_from(BAD_CONTENT)
	assert_push_error_count(3)
	assert_eq(config.get_word_packs().size(), 1, "tiny.json should load, broken.json should not")
	assert_eq(config.get_scoring(), {}, "A file with the wrong version is not used")


func test_missing_content_folder_reports_every_file() -> void:
	var config: Node = _new_config()
	assert_false(config.load_from(NO_CONTENT))
	assert_eq(config.get_load_errors().size(), FILES_IN_A_FULL_LOAD)
	assert_push_error_count(FILES_IN_A_FULL_LOAD)
