extends RefCounted
## Builds a huddle play call like "Moon 42, on two!" from the word.
## The number and the count come from the letters, so the same word always gets the same call.

const COUNTS: PackedStringArray = ["one", "two", "three"]
const NUMBER_MIN: int = 10
const NUMBER_RANGE: int = 90


## The play call for [param word].
static func build(word: String) -> String:
	var total: int = 0
	for letter: String in word:
		total += letter.unicode_at(0)
	var play_number: int = NUMBER_MIN + total % NUMBER_RANGE
	var count: String = COUNTS[word.length() % COUNTS.size()]
	return "%s %d, on %s!" % [word.capitalize(), play_number, count]
