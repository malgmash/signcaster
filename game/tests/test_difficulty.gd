extends GutTest
## Difficulty: level ids and tier lookup from content/config/difficulty.json.
## Rubber-banding tests come with M7.

const METHODS: PackedStringArray = [
	"get_level_ids",
	"get_level_index",
	"get_tier",
	"get_mode_settings",
	"challenges_for",
	"bubble_style_for",
	"study_seconds_for",
	"live_seconds_for",
	"record_result",
	"reset_group",
	"get_factor",
]


func test_has_its_public_api() -> void:
	for method: String in METHODS:
		assert_true(Difficulty.has_method(method), "Difficulty.%s() is missing" % method)


func test_rubber_band_factor_starts_neutral() -> void:
	assert_eq(Difficulty.get_factor(), 1.0)


func test_level_ids_follow_the_documented_format() -> void:
	var ids: PackedStringArray = Difficulty.get_level_ids("qb")
	assert_eq(ids.size(), 4)
	assert_eq(ids[0], "qb.group_1.1")
	assert_eq(ids[3], "qb.group_1.4")
	assert_eq(Difficulty.get_level_index("qb.group_1.3"), 2)


func test_get_tier_finds_the_tier_for_a_level() -> void:
	assert_eq(Difficulty.get_tier("qb.group_1.1")["id"], "t1")
	assert_eq(Difficulty.get_tier("wizard.group_1.4")["id"], "t4_boss")


func test_unknown_levels_have_no_tier() -> void:
	var unknown: PackedStringArray = [
		"qb.group_1.5", "qb.group_1.0", "qb.group_1.01", "chess.group_1.1", "qb.group_1", ""
	]
	for level_id: String in unknown:
		assert_eq(Difficulty.get_tier(level_id), {}, "'%s' should be unknown" % level_id)
		assert_eq(Difficulty.get_level_index(level_id), -1, "'%s' should have no index" % level_id)


func test_unknown_mode_has_no_levels() -> void:
	assert_eq(Difficulty.get_level_ids("chess"), PackedStringArray())


func test_boss_tier_overrides_the_challenge_count() -> void:
	assert_eq(Difficulty.challenges_for(Difficulty.get_tier("qb.group_1.1")), 4)
	assert_eq(Difficulty.challenges_for(Difficulty.get_tier("qb.group_1.4")), 6)


func test_timer_scale_applies_per_mode() -> void:
	var tier: Dictionary = Difficulty.get_tier("qb.group_1.1")
	assert_eq(Difficulty.live_seconds_for(tier, "qb"), 12.0)
	assert_almost_eq(Difficulty.live_seconds_for(tier, "wizard"), 19.2, 0.0001)


func test_null_bubble_style_falls_back_to_the_mode_default() -> void:
	assert_eq(Difficulty.bubble_style_for({"bubble_style": null}, "qb"), "fade")
	assert_eq(Difficulty.bubble_style_for({"bubble_style": "flash"}, "qb"), "flash")


func test_study_seconds_come_from_the_mode() -> void:
	assert_eq(Difficulty.study_seconds_for("qb"), 6.0)
	assert_eq(Difficulty.study_seconds_for("wizard"), 0.0)
