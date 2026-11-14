extends GutTest
## ChallengeManager is loaded with its public API. Behavior tests come with M2.

const METHODS: PackedStringArray = [
	"start_level",
	"next_challenge",
	"skip_study",
	"submit_typed_letter",
	"delete_typed_letter",
	"on_signed_letter",
	"give_up",
	"retry",
	"set_paused",
	"get_state",
]


func test_has_its_public_api() -> void:
	for method: String in METHODS:
		assert_true(
			ChallengeManager.has_method(method), "ChallengeManager.%s() is missing" % method
		)


func test_starts_idle() -> void:
	assert_eq(ChallengeManager.get_state(), "idle")
