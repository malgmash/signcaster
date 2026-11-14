extends Node
## Tiers, level groups and rubber-banding.
##
## Stub until M2 (tiers) and M7 (rubber-banding). See docs/ARCHITECTURE.md, "Rubber-banding".

## A factor that leaves the live timer unchanged.
const NEUTRAL_FACTOR: float = 1.0


## Level ids for [param _mode], like "qb.group_1.1", in play order. TODO(M2)
func get_level_ids(_mode: String) -> PackedStringArray:
	return PackedStringArray()


## The tier settings for [param _level_id]. TODO(M2)
func get_tier(_level_id: String) -> Dictionary:
	return {}


## Live seconds for a tier after the mode's timer scale and the rubber-band factor. TODO(M2, M7)
func live_seconds_for(_tier: Dictionary, _mode: String) -> float:
	return 0.0


## Records a challenge grade ("fast", "slow" or "fail") for rubber-banding. TODO(M7)
func record_result(_grade: String) -> void:
	pass


## Resets rubber-banding at the start of a group. TODO(M7)
func reset_group() -> void:
	pass


## The current rubber-band factor applied to live seconds. TODO(M7)
func get_factor() -> float:
	return NEUTRAL_FACTOR
