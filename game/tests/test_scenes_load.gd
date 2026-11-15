extends GutTest
## Every skin scene and shared widget loads and instantiates, so a broken scene fails CI.
##
## Scenes are created but never added to the tree, so their _ready() does not run.
## That keeps them from starting a session on the shared ChallengeManager during tests.

const SCENES: PackedStringArray = [
	"res://skins/menu/main_menu.tscn",
	"res://skins/debug/debug_main.tscn",
	"res://skins/qb/qb_main.tscn",
	"res://skins/qb/scenes/huddle_view.tscn",
	"res://skins/qb/scenes/outcome_view.tscn",
	"res://ui/sign_card.tscn",
	"res://ui/memory_bubble.tscn",
	"res://ui/letter_slots.tscn",
	"res://ui/timer_bar.tscn",
]
const PlayCall = preload("res://skins/qb/scripts/play_call.gd")


func test_every_scene_instantiates() -> void:
	for path: String in SCENES:
		var scene: PackedScene = load(path)
		assert_not_null(scene, "%s did not load" % path)
		if scene == null:
			continue
		var node: Node = scene.instantiate()
		assert_not_null(node, "%s did not instantiate" % path)
		if node != null:
			node.free()


func test_main_scene_is_the_menu() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), SCENES[0])


func test_play_call_is_the_same_for_the_same_word() -> void:
	assert_eq(PlayCall.build("MOON"), PlayCall.build("MOON"))
	assert_string_starts_with(PlayCall.build("MOON"), "Moon ")
	assert_string_ends_with(PlayCall.build("CAT"), "!")
