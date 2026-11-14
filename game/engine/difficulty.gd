extends Node
## Tiers, level groups and rubber-banding.
##
## Tier lookup since M2. Rubber-banding comes in M7. See docs/ARCHITECTURE.md, "Rubber-banding".
## Level ids look like "qb.group_1.4": mode, group id, then the 1-based level number in the group.

## A factor that leaves the live timer unchanged.
const NEUTRAL_FACTOR: float = 1.0
const LEVEL_ID_PARTS: int = 3


## Level ids for [param mode], like "qb.group_1.1", in play order.
func get_level_ids(mode: String) -> PackedStringArray:
	var ids: PackedStringArray = []
	if get_mode_settings(mode).is_empty():
		return ids
	for group: Dictionary in _groups():
		var tier_ids: Array = group.get("tiers", [])
		for number: int in range(1, tier_ids.size() + 1):
			ids.append("%s.%s.%d" % [mode, group.get("id", ""), number])
	return ids


## The position of [param level_id] in get_level_ids() for its mode, or -1 if unknown.
func get_level_index(level_id: String) -> int:
	var mode: String = level_id.get_slice(".", 0)
	return get_level_ids(mode).find(level_id)


## The tier settings for [param level_id], or an empty dictionary if the id is unknown.
func get_tier(level_id: String) -> Dictionary:
	var parts: PackedStringArray = level_id.split(".")
	if parts.size() != LEVEL_ID_PARTS or get_mode_settings(parts[0]).is_empty():
		return {}
	# Only the plain spelling ("1", not "01" or "+1"), so get_tier and get_level_ids agree.
	if not parts[2].is_valid_int() or str(parts[2].to_int()) != parts[2]:
		return {}
	for group: Dictionary in _groups():
		if group.get("id", "") != parts[1]:
			continue
		var tier_ids: Array = group.get("tiers", [])
		var number: int = parts[2].to_int()
		if number < 1 or number > tier_ids.size():
			return {}
		return _tier_by_id(str(tier_ids[number - 1]))
	return {}


## The per-mode settings from difficulty.json (study seconds, timer scale, ...), or {}.
func get_mode_settings(mode: String) -> Dictionary:
	var modes: Dictionary = Config.get_difficulty().get("modes", {})
	return modes.get(mode, {})


## How many challenges a level of [param tier] has. A tier's "challenges" overrides the default.
func challenges_for(tier: Dictionary) -> int:
	var default_count: int = int(Config.get_difficulty().get("challenges_per_level", 0))
	return int(tier.get("challenges", default_count))


## The bubble style for [param tier] in [param mode]. A null tier style means the mode default.
func bubble_style_for(tier: Dictionary, mode: String) -> String:
	var style: Variant = tier.get("bubble_style")
	if style == null:
		return str(get_mode_settings(mode).get("default_bubble", ""))
	return str(style)


## Study seconds for [param mode]. 0 means untimed study.
func study_seconds_for(mode: String) -> float:
	return float(get_mode_settings(mode).get("study_seconds", 0.0))


## Live seconds for a tier after the mode's timer scale and the rubber-band factor.
func live_seconds_for(tier: Dictionary, mode: String) -> float:
	var base: float = float(tier.get("live_seconds", 0.0))
	var scale: float = float(get_mode_settings(mode).get("timer_scale", NEUTRAL_FACTOR))
	return base * scale * get_factor()


## Records a challenge grade ("fast", "slow" or "fail") for rubber-banding. TODO(M7)
func record_result(_grade: String) -> void:
	pass


## Resets rubber-banding at the start of a group. TODO(M7)
func reset_group() -> void:
	pass


## The current rubber-band factor applied to live seconds. TODO(M7)
func get_factor() -> float:
	return NEUTRAL_FACTOR


func _groups() -> Array:
	return Config.get_difficulty().get("groups", [])


func _tier_by_id(tier_id: String) -> Dictionary:
	for tier: Dictionary in Config.get_difficulty().get("tiers", []):
		if tier.get("id", "") == tier_id:
			return tier
	return {}
