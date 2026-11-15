extends GutTest
## TrackerClient: packet parsing, the status rules and the 2 second silence rule.
##
## Each test uses a fresh TrackerClient that is never added to the tree, so it opens no sockets.
## Clock is frozen, so time only moves when a test calls _wait().

const TrackerClientScript = preload("res://engine/tracker_client.gd")
const METHODS: PackedStringArray = [
	"get_status", "is_tracker_connected", "expect", "idle", "send_config", "tick"
]
const START_TIME: float = 50.0

var _client: Node


func before_each() -> void:
	Clock.set_fake_time(START_TIME)
	_client = autofree(TrackerClientScript.new())
	watch_signals(EventBus)


func after_each() -> void:
	Clock.clear_fake_time()


func _packet(text: String) -> PackedByteArray:
	return text.to_utf8_buffer()


func _hear(text: String) -> void:
	var message: Dictionary = _client.parse_packet(_packet(text))
	assert_false(message.is_empty(), "test packet should parse: %s" % text)
	_client.handle_message(message)


func _wait(seconds: float) -> void:
	Clock.advance(seconds)
	_client.tick()


# API and parsing


func test_the_autoload_has_its_public_api() -> void:
	for method: String in METHODS:
		assert_true(TrackerClient.has_method(method), "TrackerClient.%s() is missing" % method)


func test_starts_disconnected() -> void:
	assert_eq(_client.get_status(), "disconnected")
	assert_false(_client.is_tracker_connected())


func test_parses_a_hello() -> void:
	var message: Dictionary = _client.parse_packet(
		_packet('{"v": 1, "type": "hello", "tracker": "fake", "version": "0.1.0", "fps": 0}')
	)
	assert_eq(message.get("type"), "hello")
	assert_eq(message.get("tracker"), "fake")


func test_bad_packets_are_ignored() -> void:
	var bad: Array[String] = [
		"",
		"not json",
		"[1, 2, 3]",
		'{"type": "hello"}',
		'{"v": 2, "type": "hello"}',
		'{"v": "1", "type": "hello"}',
		'{"v": 1, "type": "selfie"}',
		'{"v": 1, "type": "ping"}',
		'{"v": 1, "type": "hello", "pad": "%s"}' % "x".repeat(2100),
	]
	for text: String in bad:
		assert_eq(_client.parse_packet(_packet(text)), {}, "should be ignored: %s" % text.left(40))


func test_broken_bytes_are_ignored() -> void:
	assert_eq(_client.parse_packet(PackedByteArray([0xFF, 0xFE, 0x00, 0x7B])), {})


# Status rules


func test_hello_connects_and_sends_config() -> void:
	_hear('{"v": 1, "type": "hello", "tracker": "fake", "version": "0.1.0", "fps": 0}')
	assert_eq(_client.get_status(), "connected")
	assert_signal_emitted_with_parameters(EventBus, "tracker_status_changed", ["connected"])
	assert_signal_emitted_with_parameters(EventBus, "tracker_message_received", ["hello", ""])
	assert_eq(_client.get_last_sent().get("type"), "config")


func test_no_hand_and_back() -> void:
	_hear('{"v": 1, "type": "hand", "present": false}')
	assert_eq(_client.get_status(), "no_hand")
	_hear('{"v": 1, "type": "hand", "t": 1.0, "handedness": "Right", "present": true}')
	assert_eq(_client.get_status(), "connected")


func test_a_tracker_problem_counts_as_disconnected() -> void:
	_hear('{"v": 1, "type": "hello", "tracker": "mediapipe", "version": "0.1.0", "fps": 0}')
	_hear(
		(
			'{"v": 1, "type": "status", "status": "no_camera", '
			+ '"detail": "Camera index 0 could not be opened"}'
		)
	)
	assert_eq(_client.get_status(), "disconnected")
	assert_signal_emitted_with_parameters(
		EventBus,
		"tracker_message_received",
		["status", "no_camera: Camera index 0 could not be opened"]
	)
	_hear('{"v": 1, "type": "hello", "tracker": "mediapipe", "version": "0.1.0", "fps": 0}')
	assert_eq(_client.get_status(), "disconnected", "A hello alone does not clear the problem")
	_hear('{"v": 1, "type": "status", "status": "ok", "detail": ""}')
	assert_eq(_client.get_status(), "connected")


func test_status_changes_are_only_announced_once() -> void:
	for _i: int in range(3):
		_hear('{"v": 1, "type": "hello", "tracker": "fake", "version": "0.1.0", "fps": 0}')
	assert_signal_emit_count(EventBus, "tracker_status_changed", 1)
	assert_signal_emit_count(EventBus, "tracker_message_received", 3)


func test_letters_keep_the_connection_alive() -> void:
	_hear(
		'{"v": 1, "type": "letter", "t": 1.0, "letter": "B", "confidence": 0.9, "hold_frames": 6}'
	)
	assert_eq(_client.get_status(), "connected")
	assert_signal_emitted_with_parameters(EventBus, "tracker_message_received", ["letter", ""])


# The 2 second rule


func test_silence_under_two_seconds_stays_connected() -> void:
	_hear('{"v": 1, "type": "hello", "tracker": "fake", "version": "0.1.0", "fps": 0}')
	_wait(1.9)
	assert_eq(_client.get_status(), "connected")


func test_two_seconds_of_silence_disconnects() -> void:
	_hear('{"v": 1, "type": "hello", "tracker": "fake", "version": "0.1.0", "fps": 0}')
	_wait(2.0)
	assert_eq(_client.get_status(), "disconnected")
	assert_signal_emitted_with_parameters(EventBus, "tracker_status_changed", ["disconnected"])


func test_each_message_restarts_the_silence_timer() -> void:
	_hear('{"v": 1, "type": "hello", "tracker": "fake", "version": "0.1.0", "fps": 0}')
	_wait(1.5)
	_hear('{"v": 1, "type": "hand", "present": false}')
	_wait(1.5)
	assert_eq(_client.get_status(), "no_hand")


func test_reconnecting_sends_config_again() -> void:
	_hear('{"v": 1, "type": "hello", "tracker": "fake", "version": "0.1.0", "fps": 0}')
	_wait(2.0)
	_hear('{"v": 1, "type": "hello", "tracker": "fake", "version": "0.1.0", "fps": 0}')
	assert_eq(_client.get_status(), "connected")
	assert_eq(_client.get_last_sent().get("type"), "config")


# Messages to the tracker


func test_config_comes_from_tracker_json() -> void:
	var config: Dictionary = _client.build_config()
	assert_eq(config.get("type"), "config")
	assert_eq(config.get("min_confidence"), float(Config.get_tracker()["min_confidence"]))
	assert_eq(config.get("hold_frames"), int(Config.get_tracker()["hold_frames"]))
	assert_false(config.get("mirror"))


func test_tick_sends_a_ping_every_second() -> void:
	_client.tick()
	assert_eq(_client.get_last_sent(), {"v": 1, "type": "ping"})
	_client.expect("c_000001", "BLUE")
	_wait(0.5)
	assert_eq(_client.get_last_sent().get("type"), "expect", "No second ping yet")
	_wait(0.5)
	assert_eq(_client.get_last_sent().get("type"), "ping")


func test_expect_and_idle_messages() -> void:
	_client.expect("c_000007", "CAT")
	assert_eq(
		_client.get_last_sent(),
		{"v": 1, "type": "expect", "challenge_id": "c_000007", "letters": "CAT"}
	)
	_client.idle()
	assert_eq(_client.get_last_sent(), {"v": 1, "type": "idle"})
