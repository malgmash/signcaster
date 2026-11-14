extends Node
## The challenge state machine: study, live, result. Timers, input checking and grading.
##
## Stub until M2. See docs/ARCHITECTURE.md, "Challenge lifecycle" and "Input checking".

const STATE_IDLE: String = "idle"


## Begins the level [param _level_id] and its first challenge. TODO(M2)
func start_level(_level_id: String) -> void:
	pass


## Picks the next word and direction and starts its study phase. TODO(M2)
func next_challenge() -> void:
	pass


## Ends the study phase early and starts the live timer. TODO(M2)
func skip_study() -> void:
	pass


## Checks a typed letter against the next expected letter (Read it). TODO(M2)
func submit_typed_letter(_letter: String) -> void:
	pass


## Removes the last accepted letter (Read it only). TODO(M2)
func delete_typed_letter() -> void:
	pass


## Checks a letter from the tracker. Wrong letters are ignored (Sign it). TODO(M6)
func on_signed_letter(_letter: String) -> void:
	pass


## Ends the live challenge as a fail with reason "gave_up". TODO(M2)
func give_up() -> void:
	pass


## Restarts the last failed challenge from its study phase. TODO(M7)
func retry() -> void:
	pass


## Freezes or resumes the live timer. TODO(M2)
func set_paused(_paused: bool) -> void:
	pass


## The current state name, for the debug skin. TODO(M2)
func get_state() -> String:
	return STATE_IDLE
