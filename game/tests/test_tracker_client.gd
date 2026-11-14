extends GutTest
## TrackerClient is loaded with its public API. Behavior tests come with M4 and M6.

const METHODS: PackedStringArray = ["get_status", "is_tracker_connected", "expect", "idle"]


func test_has_its_public_api() -> void:
	for method: String in METHODS:
		assert_true(TrackerClient.has_method(method), "TrackerClient.%s() is missing" % method)


func test_starts_disconnected() -> void:
	assert_eq(TrackerClient.get_status(), "disconnected")
	assert_false(TrackerClient.is_tracker_connected())
