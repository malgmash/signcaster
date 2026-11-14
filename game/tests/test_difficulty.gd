extends GutTest
## Difficulty is loaded with its public API. Behavior tests come with M2 and M7.

const METHODS: PackedStringArray = [
	"get_level_ids", "get_tier", "live_seconds_for", "record_result", "reset_group", "get_factor"
]


func test_has_its_public_api() -> void:
	for method: String in METHODS:
		assert_true(Difficulty.has_method(method), "Difficulty.%s() is missing" % method)


func test_rubber_band_factor_starts_neutral() -> void:
	assert_eq(Difficulty.get_factor(), 1.0)
