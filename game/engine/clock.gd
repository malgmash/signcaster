extends Node
## Wraps engine time so tests can control it.
##
## Engine code reads time only through Clock, never through Godot's Time directly.
## tests/test_clock.gd checks that rule.

const MSEC_PER_SECOND: float = 1000.0

var _fake_time: float = 0.0
var _use_fake: bool = false


## Seconds since the game started, or the fake time while a test controls time.
func now() -> float:
	if _use_fake:
		return _fake_time
	return Time.get_ticks_msec() / MSEC_PER_SECOND


## Freezes time at [param seconds] until clear_fake_time() is called. For tests.
func set_fake_time(seconds: float) -> void:
	_fake_time = seconds
	_use_fake = true


## Moves time forward by [param seconds]. Starts fake time from the real time if needed.
func advance(seconds: float) -> void:
	if not _use_fake:
		set_fake_time(now())
	_fake_time += seconds


## Goes back to real engine time.
func clear_fake_time() -> void:
	_use_fake = false


## True while a test controls time.
func is_fake() -> bool:
	return _use_fake
