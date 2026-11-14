extends GutTest
## WordBank: picking words for a level from the starter pack.
## Spaced repetition tests come with M7.

const METHODS: PackedStringArray = ["pick_words", "record_result", "get_word"]
const THREE_LETTERS: Dictionary = {"id": "test", "word_length": [3, 3]}
const THREE_OR_FOUR: Dictionary = {"id": "test", "word_length": [3, 4]}


func before_each() -> void:
	WordBank.set_seed(1)


func _words(picked: Array[Dictionary]) -> PackedStringArray:
	var words: PackedStringArray = []
	for entry: Dictionary in picked:
		words.append(entry["word"])
	return words


func test_has_its_public_api() -> void:
	for method: String in METHODS:
		assert_true(WordBank.has_method(method), "WordBank.%s() is missing" % method)


func test_picks_the_requested_number_without_repeats() -> void:
	var words: PackedStringArray = _words(WordBank.pick_words(THREE_OR_FOUR, "qb", 6))
	assert_eq(words.size(), 6)
	for word: String in words:
		assert_eq(words.count(word), 1, "%s was picked twice" % word)


func test_respects_the_word_length_range() -> void:
	for word: String in _words(WordBank.pick_words(THREE_LETTERS, "qb", 4)):
		assert_eq(word.length(), 3, "%s is not 3 letters" % word)


func test_returns_fewer_when_not_enough_words_fit() -> void:
	var picked: Array[Dictionary] = WordBank.pick_words(THREE_LETTERS, "qb", 100)
	assert_lt(picked.size(), 100)
	assert_gt(picked.size(), 0)


func test_the_same_seed_gives_the_same_words() -> void:
	var first: PackedStringArray = _words(WordBank.pick_words(THREE_OR_FOUR, "qb", 4))
	WordBank.set_seed(1)
	var second: PackedStringArray = _words(WordBank.pick_words(THREE_OR_FOUR, "qb", 4))
	assert_eq(first, second)


func test_wizard_mode_only_picks_kid_safe_words() -> void:
	for entry: Dictionary in WordBank.pick_words(THREE_OR_FOUR, "wizard", 100):
		assert_true(entry.get("kid_safe", false), "%s is not kid_safe" % entry["word"])


func test_get_word_finds_an_entry_by_id() -> void:
	assert_eq(WordBank.get_word("starter.blue")["word"], "BLUE")
	assert_eq(WordBank.get_word("starter.nope"), {})


func test_tier_without_a_length_range_is_reported() -> void:
	assert_eq(WordBank.pick_words({"id": "broken"}, "qb", 4), [])
	assert_push_error("no word_length")
