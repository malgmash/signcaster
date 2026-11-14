extends GutTest
## Store is loaded with its public API. Behavior tests come with M8.

const METHODS: PackedStringArray = ["get_catalog", "buy", "equip", "is_owned", "get_equipped"]


func test_has_its_public_api() -> void:
	for method: String in METHODS:
		assert_true(Store.has_method(method), "Store.%s() is missing" % method)
