extends Node2D
## The field seen from behind the QB: turf, our line, the rushing defense and the ball.
##
## Placeholder shapes only. qb_main.gd calls these methods; this script never talks to the engine.
## Rush progress goes from 0.0 (snap) to 1.0 (time is up, the defense reaches the QB).

const PlayerToken = preload("res://skins/qb/scripts/player_token.gd")

const FIELD_SIZE: Vector2 = Vector2(1280, 720)
const END_ZONE_BOTTOM: float = 110.0
const YARD_LINE_TOP: float = 140.0
const YARD_LINE_STEP: float = 60.0
const YARD_LINE_WIDTH: float = 3.0
const SCRIMMAGE_Y: float = 362.0
const SCRIMMAGE_WIDTH: float = 4.0
const STRIPE_HEIGHT: float = 60.0

const TURF_COLOR: Color = Color(0.16, 0.42, 0.2)
const TURF_STRIPE_COLOR: Color = Color(0.18, 0.46, 0.22)
const END_ZONE_COLOR: Color = Color(0.1, 0.32, 0.16)
const LINE_COLOR: Color = Color(1, 1, 1, 0.55)
const SCRIMMAGE_COLOR: Color = Color(0.35, 0.6, 1.0, 0.8)

# Our team (invented): green with white trim. The defense (invented): blue with silver trim.
const OFFENSE_COLOR: Color = Color(0.05, 0.62, 0.33)
const OFFENSE_TRIM: Color = Color(0.97, 0.97, 0.97)
const DEFENSE_COLOR: Color = Color(0.18, 0.38, 0.72)
const DEFENSE_TRIM: Color = Color(0.78, 0.8, 0.85)

const QB_SPOT: Vector2 = Vector2(640, 610)
const QB_NUMBER: int = 7
const LINEMEN_SPOTS: Array[Vector2] = [
	Vector2(520, 388), Vector2(580, 388), Vector2(640, 388), Vector2(700, 388), Vector2(760, 388)
]
const LINEMEN_NUMBERS: Array[int] = [72, 65, 50, 61, 77]
const LINE_GIVE: Vector2 = Vector2(0, 45)
const DEFENDER_STARTS: Array[Vector2] = [
	Vector2(330, 300), Vector2(500, 290), Vector2(780, 290), Vector2(950, 300)
]
const DEFENDER_NUMBERS: Array[int] = [91, 55, 52, 99]
## Where each defender ends up around the QB when time runs out.
const SACK_OFFSETS: Array[Vector2] = [
	Vector2(-44, -18), Vector2(-16, -40), Vector2(16, -40), Vector2(44, -18)
]

const BALL_RADIUS: Vector2 = Vector2(9, 6)
const BALL_POINTS: int = 16
const BALL_COLOR: Color = Color(0.55, 0.3, 0.15)
const BALL_HAND_OFFSET: Vector2 = Vector2(18, -6)
const DEEP_TARGET: Vector2 = Vector2(700, 70)
const SHORT_TARGET: Vector2 = Vector2(760, 300)
const DEEP_SECONDS: float = 0.9
const SHORT_SECONDS: float = 0.55
const BALL_PEAK_SCALE: float = 2.2

const SACK_SECONDS: float = 0.25
const QB_FALL_DEGREES: float = 80.0
const SHAKE_PIXELS: float = 8.0
const SHAKE_STEP_SECONDS: float = 0.05
const SHAKE_STEPS: int = 3

# About 40 particles, one shot, so it stays light on integrated graphics.
const CONFETTI_AMOUNT: int = 40
const CONFETTI_LIFETIME: float = 1.4
const CONFETTI_SPREAD_DEGREES: float = 70.0
const CONFETTI_SPEED_MIN: float = 180.0
const CONFETTI_SPEED_MAX: float = 320.0
const CONFETTI_GRAVITY: Vector2 = Vector2(0, 420)
const CONFETTI_SIZE_MIN: float = 3.0
const CONFETTI_SIZE_MAX: float = 5.0
const CONFETTI_COLOR: Color = Color(1.0, 0.85, 0.3)
const CONFETTI_HUE_SPREAD: float = 0.5

var _qb: Node2D
var _linemen: Array[Node2D] = []
var _defenders: Array[Node2D] = []
var _ball: Polygon2D
var _confetti: CPUParticles2D
var _tweens: Array[Tween] = []


func _ready() -> void:
	for i: int in range(LINEMEN_SPOTS.size()):
		_linemen.append(_add_player(OFFENSE_COLOR, OFFENSE_TRIM, LINEMEN_NUMBERS[i]))
	for i: int in range(DEFENDER_STARTS.size()):
		_defenders.append(_add_player(DEFENSE_COLOR, DEFENSE_TRIM, DEFENDER_NUMBERS[i]))
	_qb = _add_player(OFFENSE_COLOR, OFFENSE_TRIM, QB_NUMBER)
	_ball = _make_ball()
	add_child(_ball)
	_confetti = _make_confetti()
	add_child(_confetti)
	reset_formation()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, FIELD_SIZE), TURF_COLOR)
	var y: float = END_ZONE_BOTTOM
	var striped: bool = false
	while y < FIELD_SIZE.y:
		if striped:
			draw_rect(Rect2(0, y, FIELD_SIZE.x, STRIPE_HEIGHT), TURF_STRIPE_COLOR)
		striped = not striped
		y += STRIPE_HEIGHT
	draw_rect(Rect2(0, 0, FIELD_SIZE.x, END_ZONE_BOTTOM), END_ZONE_COLOR)
	var line_y: float = YARD_LINE_TOP
	while line_y < FIELD_SIZE.y:
		draw_line(Vector2(0, line_y), Vector2(FIELD_SIZE.x, line_y), LINE_COLOR, YARD_LINE_WIDTH)
		line_y += YARD_LINE_STEP
	draw_line(
		Vector2(0, SCRIMMAGE_Y),
		Vector2(FIELD_SIZE.x, SCRIMMAGE_Y),
		SCRIMMAGE_COLOR,
		SCRIMMAGE_WIDTH
	)


## Everyone back to the line, the QB standing with the ball.
func reset_formation() -> void:
	_stop_tweens()
	position = Vector2.ZERO
	_qb.position = QB_SPOT
	_qb.rotation = 0.0
	_ball.position = QB_SPOT + BALL_HAND_OFFSET
	_ball.scale = Vector2.ONE
	_ball.visible = true
	set_rush(0.0)


## Moves the rush: 0.0 at the snap, 1.0 when the defense reaches the QB.
func set_rush(progress: float) -> void:
	var t: float = clampf(progress, 0.0, 1.0)
	for i: int in range(_linemen.size()):
		_linemen[i].position = LINEMEN_SPOTS[i] + LINE_GIVE * t
	for i: int in range(_defenders.size()):
		_defenders[i].position = DEFENDER_STARTS[i].lerp(QB_SPOT + SACK_OFFSETS[i], t)


## The pass: deep for a touchdown (with confetti), short for a small gain.
func throw(deep: bool) -> void:
	var target: Vector2 = DEEP_TARGET if deep else SHORT_TARGET
	var seconds: float = DEEP_SECONDS if deep else SHORT_SECONDS
	var flight: Tween = _new_tween()
	flight.tween_property(_ball, "position", target, seconds)
	var arc: Tween = _new_tween()
	arc.tween_property(_ball, "scale", Vector2.ONE * BALL_PEAK_SCALE, seconds / 2.0)
	arc.tween_property(_ball, "scale", Vector2.ONE, seconds / 2.0)
	if deep:
		flight.tween_callback(_burst_confetti.bind(target))


## The sack: the defense closes in, the QB goes down, the field shakes.
func sack() -> void:
	var close: Tween = _new_tween().set_parallel(true)
	for i: int in range(_defenders.size()):
		close.tween_property(_defenders[i], "position", QB_SPOT + SACK_OFFSETS[i], SACK_SECONDS)
	close.tween_property(_qb, "rotation_degrees", QB_FALL_DEGREES, SACK_SECONDS)
	var shake: Tween = _new_tween()
	shake.tween_interval(SACK_SECONDS)
	for _i: int in range(SHAKE_STEPS):
		shake.tween_property(self, "position", Vector2(SHAKE_PIXELS, 0), SHAKE_STEP_SECONDS)
		shake.tween_property(self, "position", Vector2(-SHAKE_PIXELS, 0), SHAKE_STEP_SECONDS)
	shake.tween_property(self, "position", Vector2.ZERO, SHAKE_STEP_SECONDS)


func _add_player(jersey: Color, trim: Color, jersey_number: int) -> Node2D:
	var token: Node2D = PlayerToken.new()
	token.jersey_color = jersey
	token.trim_color = trim
	token.number = jersey_number
	add_child(token)
	return token


func _make_ball() -> Polygon2D:
	var ball: Polygon2D = Polygon2D.new()
	var points: PackedVector2Array = []
	for i: int in range(BALL_POINTS):
		var angle: float = TAU * i / BALL_POINTS
		points.append(Vector2(cos(angle) * BALL_RADIUS.x, sin(angle) * BALL_RADIUS.y))
	ball.polygon = points
	ball.color = BALL_COLOR
	return ball


func _make_confetti() -> CPUParticles2D:
	var confetti: CPUParticles2D = CPUParticles2D.new()
	confetti.emitting = false
	confetti.one_shot = true
	confetti.amount = CONFETTI_AMOUNT
	confetti.lifetime = CONFETTI_LIFETIME
	confetti.explosiveness = 1.0
	confetti.direction = Vector2.UP
	confetti.spread = CONFETTI_SPREAD_DEGREES
	confetti.initial_velocity_min = CONFETTI_SPEED_MIN
	confetti.initial_velocity_max = CONFETTI_SPEED_MAX
	confetti.gravity = CONFETTI_GRAVITY
	confetti.scale_amount_min = CONFETTI_SIZE_MIN
	confetti.scale_amount_max = CONFETTI_SIZE_MAX
	confetti.color = CONFETTI_COLOR
	confetti.hue_variation_min = -CONFETTI_HUE_SPREAD
	confetti.hue_variation_max = CONFETTI_HUE_SPREAD
	return confetti


func _burst_confetti(at: Vector2) -> void:
	_confetti.position = at
	_confetti.restart()


func _new_tween() -> Tween:
	var tween: Tween = create_tween()
	_tweens.append(tween)
	return tween


func _stop_tweens() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
