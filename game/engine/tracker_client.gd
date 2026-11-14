extends Node
## UDP client for the hand tracker on localhost. Feeds signed letters to ChallengeManager.
##
## Stub until M4 (connection) and M6 (Sign it). See docs/TRACKER_PROTOCOL.md.

const STATUS_DISCONNECTED: String = "disconnected"


## "connected", "no_hand" or "disconnected". TODO(M4)
func get_status() -> String:
	return STATUS_DISCONNECTED


## True while the tracker is sending heartbeats. Not named is_connected, which Object has. TODO(M4)
func is_tracker_connected() -> bool:
	return false


## Tells the tracker which letters a live Sign it challenge expects. TODO(M6)
func expect(_challenge_id: String, _letters: String) -> void:
	pass


## Tells the tracker no Sign it challenge is live. TODO(M6)
func idle() -> void:
	pass
