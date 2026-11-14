extends GutTest
## Economy is loaded with its public API. Behavior tests come with M8.

const METHODS: PackedStringArray = [
	"get_balance", "award_challenge", "award_level", "spend", "stars_for"
]


func test_has_its_public_api() -> void:
	for method: String in METHODS:
		assert_true(Economy.has_method(method), "Economy.%s() is missing" % method)
