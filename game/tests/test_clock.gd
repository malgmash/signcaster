extends GutTest
## Clock can be frozen and moved by tests, and it is the only engine script that reads Time.

const ClockScript = preload("res://engine/clock.gd")
const ENGINE_DIR: String = "res://engine"
## Far beyond any real test run, so real time is always smaller.
const FAR_FUTURE_SECONDS: float = 1.0e9
const TOLERANCE_SECONDS: float = 0.5


func _new_clock() -> Node:
	return autofree(ClockScript.new())


func test_fake_time_freezes_now() -> void:
	var clock: Node = _new_clock()
	clock.set_fake_time(10.0)
	assert_true(clock.is_fake())
	assert_eq(clock.now(), 10.0)
	assert_eq(clock.now(), 10.0, "Fake time must not move on its own")


func test_advance_moves_fake_time() -> void:
	var clock: Node = _new_clock()
	clock.set_fake_time(10.0)
	clock.advance(2.5)
	assert_eq(clock.now(), 12.5)


func test_advance_without_fake_time_starts_from_real_time() -> void:
	var clock: Node = _new_clock()
	var before: float = clock.now()
	clock.advance(5.0)
	assert_true(clock.is_fake())
	assert_almost_eq(clock.now(), before + 5.0, TOLERANCE_SECONDS)


func test_clear_returns_to_real_time() -> void:
	var clock: Node = _new_clock()
	clock.set_fake_time(FAR_FUTURE_SECONDS)
	clock.clear_fake_time()
	assert_false(clock.is_fake())
	assert_lt(clock.now(), FAR_FUTURE_SECONDS)


func test_only_clock_reads_engine_time() -> void:
	var pattern: RegEx = RegEx.create_from_string("\\bTime\\.")
	var checked: int = 0
	for file_name: String in DirAccess.get_files_at(ENGINE_DIR):
		if file_name.get_extension() != "gd" or file_name == "clock.gd":
			continue
		checked += 1
		var source: String = FileAccess.get_file_as_string(ENGINE_DIR.path_join(file_name))
		assert_null(pattern.search(source), "%s uses Time directly. Use Clock." % file_name)
	assert_gt(checked, 0, "No engine scripts were checked")
