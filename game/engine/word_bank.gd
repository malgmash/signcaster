extends Node
## Word packs, spaced repetition boxes and word picking.
##
## Stub until M2 (picking) and M7 (Leitner boxes). See docs/ARCHITECTURE.md, "Key algorithms".


## Picks [param _count] words for a level, mixing new and review words. TODO(M2, M7)
func pick_words(_tier: Dictionary, _mode: String, _count: int) -> Array[Dictionary]:
	return []


## Records a success or miss so the word moves between boxes. TODO(M7)
func record_result(_word_id: String, _success: bool) -> void:
	pass


## The word entry for [param _word_id], or an empty dictionary if unknown. TODO(M2)
func get_word(_word_id: String) -> Dictionary:
	return {}
