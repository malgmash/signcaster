extends GutTest
## SaveSystem is loaded with its public API. Behavior tests come with M10.

const METHODS: PackedStringArray = ["load_save", "save_now", "get_data"]


func test_has_its_public_api() -> void:
	for method: String in METHODS:
		assert_true(SaveSystem.has_method(method), "SaveSystem.%s() is missing" % method)
