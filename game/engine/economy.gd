extends Node
## Coins, stars and bonuses. One wallet shared by both modes.
##
## Stub until M8. See docs/GAME_DESIGN.md, "Rewards and store" and "Stars per level".


## The current coin balance. TODO(M8)
func get_balance() -> int:
	return 0


## Pays out coins for a successful challenge and returns the amount. TODO(M8)
func award_challenge(_grade: String) -> int:
	return 0


## Pays out the end-of-level bonus and returns the amount. TODO(M8)
func award_level(_perfect: bool) -> int:
	return 0


## Spends [param _amount] coins. Returns false if the wallet is too low. TODO(M8)
func spend(_amount: int, _reason: String) -> bool:
	return false


## Stars (1 to 3) for a finished level from its results. TODO(M8)
func stars_for(_successes: int, _fasts: int, _total: int) -> int:
	return 0
