extends Node
## UDP client for the hand tracker on localhost. Tracks the connection and talks to the tracker.
##
## See docs/TRACKER_PROTOCOL.md. Two sockets on purpose: one listens on the game port, the other
## sends to the tracker's control port. Bad packets are dropped, never trusted, never crash.
## Status rules:
## - "connected" after any tracker message, "no_hand" while the tracker says no hand is visible.
## - "disconnected" after 2 s of silence, or while the tracker reports a problem (no_camera...),
##   because then Sign it cannot work even though the tracker is alive.
## Signed letters reach ChallengeManager in M6.

const HOST: String = "127.0.0.1"
const GAME_PORT: int = 47800
const CONTROL_PORT: int = 47801
const PROTOCOL_VERSION: int = 1
const MAX_PACKET_BYTES: int = 2048
## From the protocol doc: 2 s of silence means the tracker is gone.
const SILENCE_SECONDS: float = 2.0
## From ADR 0006: the tracker quits after 5 s without a ping, so ping every second.
const PING_SECONDS: float = 1.0
const TRACKER_TYPES: PackedStringArray = ["hello", "hand", "letter", "status"]
const TRACKER_OK: String = "ok"

const STATUS_CONNECTED: String = "connected"
const STATUS_NO_HAND: String = "no_hand"
const STATUS_DISCONNECTED: String = "disconnected"

var _listener: PacketPeerUDP = null
var _sender: PacketPeerUDP = null
var _status: String = STATUS_DISCONNECTED
var _heard: bool = false
var _last_heard_at: float = 0.0
var _hand_present: bool = true
var _problem: String = ""
var _next_ping_at: float = 0.0
var _last_sent: Dictionary = {}


func _ready() -> void:
	_listener = PacketPeerUDP.new()
	var error: Error = _listener.bind(GAME_PORT, HOST)
	if error != OK:
		# Another copy of the game may hold the port. Sign it falls back to Read it.
		push_warning("TrackerClient: could not listen on %s:%d (%s)" % [HOST, GAME_PORT, error])
		_listener = null
	_sender = PacketPeerUDP.new()
	_sender.set_dest_address(HOST, CONTROL_PORT)


func _exit_tree() -> void:
	if _listener != null:
		_listener.close()
	if _sender != null:
		_sender.close()


func _process(_delta: float) -> void:
	_receive()
	tick()


## "connected", "no_hand" or "disconnected".
func get_status() -> String:
	return _status


## True while the tracker is heard and has no problem. Not named is_connected, which Object has.
func is_tracker_connected() -> bool:
	return _status != STATUS_DISCONNECTED


## The message from a datagram, or an empty dictionary if it is too big, broken or unknown.
func parse_packet(packet: PackedByteArray) -> Dictionary:
	if packet.size() > MAX_PACKET_BYTES:
		return {}
	var json: JSON = JSON.new()
	if json.parse(packet.get_string_from_utf8()) != OK:
		return {}
	var message: Variant = json.data
	if typeof(message) != TYPE_DICTIONARY:
		return {}
	# JSON numbers arrive as floats, so 1.0 counts as version 1.
	var version: Variant = message.get("v")
	if not (version is int or version is float) or version != PROTOCOL_VERSION:
		return {}
	if not TRACKER_TYPES.has(str(message.get("type", ""))):
		return {}
	return message


## Applies one parsed tracker message: updates the status and tells the skins.
func handle_message(message: Dictionary) -> void:
	var was_silent: bool = not _heard
	_heard = true
	_last_heard_at = Clock.now()
	var kind: String = str(message.get("type", ""))
	var detail: String = ""
	if kind == "hand":
		_hand_present = bool(message.get("present", false))
	elif kind == "status":
		detail = _apply_status(message)
	# TODO(M6): forward "letter" messages to ChallengeManager.on_signed_letter().
	EventBus.tracker_message_received.emit(kind, detail)
	if was_silent:
		send_config()
	_update_status()


## Checks for silence and sends the ping. Called every frame; tests call it after Clock.advance().
func tick() -> void:
	var now: float = Clock.now()
	if _heard and now - _last_heard_at >= SILENCE_SECONDS:
		_heard = false
		_problem = ""
		_hand_present = true
		_update_status()
	if now >= _next_ping_at:
		_next_ping_at = now + PING_SECONDS
		_send({"type": "ping"})


## Sends the recognition settings from content/config/tracker.json.
func send_config() -> void:
	_send(build_config())


## The config message for the tracker.
func build_config() -> Dictionary:
	var tuning: Dictionary = Config.get_tracker()
	return {
		"type": "config",
		# TODO(M10): mirror comes from settings.left_handed, debug_landmarks from a debug toggle.
		"mirror": false,
		"debug_landmarks": false,
		"min_confidence": float(tuning.get("min_confidence", 0.0)),
		"hold_frames": int(tuning.get("hold_frames", 0)),
		"release_frames": int(tuning.get("release_frames", 0)),
	}


## Tells the tracker which letters a live Sign it challenge expects (a hint only).
func expect(challenge_id: String, letters: String) -> void:
	_send({"type": "expect", "challenge_id": challenge_id, "letters": letters})


## Tells the tracker no Sign it challenge is live, so it can slow down.
func idle() -> void:
	_send({"type": "idle"})


## The last message built for the tracker, for the debug skin and tests.
func get_last_sent() -> Dictionary:
	return _last_sent


func _apply_status(message: Dictionary) -> String:
	var value: String = str(message.get("status", ""))
	var text: String = str(message.get("detail", ""))
	_problem = "" if value == TRACKER_OK else value
	return value if text.is_empty() else "%s: %s" % [value, text]


func _update_status() -> void:
	var status: String = STATUS_CONNECTED
	if not _heard or not _problem.is_empty():
		status = STATUS_DISCONNECTED
	elif not _hand_present:
		status = STATUS_NO_HAND
	if status == _status:
		return
	_status = status
	EventBus.tracker_status_changed.emit(status)


func _receive() -> void:
	if _listener == null:
		return
	while _listener.get_available_packet_count() > 0:
		var message: Dictionary = parse_packet(_listener.get_packet())
		if not message.is_empty():
			handle_message(message)


func _send(fields: Dictionary) -> void:
	var message: Dictionary = {"v": PROTOCOL_VERSION}
	message.merge(fields)
	_last_sent = message
	if _sender != null:
		_sender.put_packet(JSON.stringify(message).to_utf8_buffer())
