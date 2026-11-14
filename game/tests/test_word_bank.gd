extends GutTest
## WordBank is loaded with its public API. Behavior tests come with M2 and M7.

const METHODS: PackedStringArray = ["pick_words", "record_result", "get_word"]


func test_has_its_public_api() -> void:
	for method: String in METHODS:
		assert_true(WordBank.has_method(method), "WordBank.%s() is missing" % method)
