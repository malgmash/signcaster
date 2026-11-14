extends Node
## Word packs, spaced repetition boxes and word picking.
##
## Picking since M2. Leitner boxes come in M7.
## See docs/ARCHITECTURE.md, "Picking the next challenge".

## The mode whose words must all be kid_safe.
const KIDS_MODE: String = "wizard"
## Packs with this unlock type are open from the start.
const DEFAULT_UNLOCK: String = "default"

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


## Makes word picking repeatable. For tests.
func set_seed(new_seed: int) -> void:
	_rng.seed = new_seed


## Picks up to [param count] different words that fit [param tier] in [param mode].
## Returns fewer if the packs do not have enough matching words.
func pick_words(tier: Dictionary, mode: String, count: int) -> Array[Dictionary]:
	# TODO(M7): mix in about 30% due review words and respect max_new_words_per_level.
	var pool: Array[Dictionary] = _matching_words(tier, mode)
	_shuffle(pool)
	return pool.slice(0, mini(count, pool.size()))


## Records a success or miss so the word moves between boxes. TODO(M7)
func record_result(_word_id: String, _success: bool) -> void:
	pass


## The word entry for [param word_id], or an empty dictionary if unknown.
func get_word(word_id: String) -> Dictionary:
	for pack: Dictionary in Config.get_word_packs():
		for entry: Dictionary in pack.get("words", []):
			if entry.get("id", "") == word_id:
				return entry
	return {}


func _matching_words(tier: Dictionary, mode: String) -> Array[Dictionary]:
	var lengths: Array = tier.get("word_length", [])
	if lengths.size() != 2:
		push_error("WordBank: tier '%s' has no word_length range" % tier.get("id", "?"))
		return []
	var shortest: int = int(lengths[0])
	var longest: int = int(lengths[1])
	var words: Array[Dictionary] = []
	for pack: Dictionary in Config.get_word_packs():
		if pack.get("unlock", {}).get("type", "") != DEFAULT_UNLOCK:
			continue
		for entry: Dictionary in pack.get("words", []):
			var length: int = str(entry.get("word", "")).length()
			if length < shortest or length > longest:
				continue
			if mode == KIDS_MODE and not entry.get("kid_safe", false):
				continue
			words.append(entry)
	return words


# Fisher-Yates with our own generator, so set_seed() controls the order.
func _shuffle(items: Array[Dictionary]) -> void:
	for i: int in range(items.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var swap: Dictionary = items[i]
		items[i] = items[j]
		items[j] = swap
