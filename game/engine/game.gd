extends Node
## The public API for skins. Skins call these methods and listen to EventBus, nothing else.
##
## Every method here must match docs/EVENTS.md, "Public methods on Game".
## tests/test_game.gd reads the doc and fails if the two drift apart.
## Most methods forward to the engine autoload that owns the rule.


## Starts a session in [param _mode] ("qb" or "wizard"). TODO(M2)
func start_session(_mode: String) -> void:
	pass


## Begins the level [param level_id].
func start_level(level_id: String) -> void:
	ChallengeManager.start_level(level_id)


## Read it input: one typed letter.
func submit_typed_letter(letter: String) -> void:
	ChallengeManager.submit_typed_letter(letter)


## Read it backspace.
func delete_typed_letter() -> void:
	ChallengeManager.delete_typed_letter()


## The player is ready before the study timer ends.
func skip_study() -> void:
	ChallengeManager.skip_study()


## Ends the challenge as a fail.
func give_up() -> void:
	ChallengeManager.give_up()


## Retries the last failed challenge.
func retry() -> void:
	ChallengeManager.retry()


## Pauses or resumes the game.
func set_paused(paused: bool) -> void:
	ChallengeManager.set_paused(paused)


## Buys a store item.
func buy_item(item_id: String) -> void:
	Store.buy(item_id)


## Equips a cosmetic item.
func equip_item(item_id: String) -> void:
	Store.equip(item_id)
