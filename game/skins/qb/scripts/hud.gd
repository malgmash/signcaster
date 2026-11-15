extends HBoxContainer
## The QB heads-up display: "Drive 1   Play 2 of 4" and the points for this drive.
## qb_main.gd calls these methods; this script never talks to the engine.

@onready var _drive_label: Label = $DriveLabel
@onready var _points_label: Label = $PointsLabel


## Shows the drive number and which play of the drive this is (both start at 1).
func set_play(drive: int, play: int, plays_in_drive: int) -> void:
	_drive_label.text = "Drive %d    Play %d of %d" % [drive, play, plays_in_drive]


## Shows the points earned this drive.
func set_points(points: int) -> void:
	_points_label.text = "Points %d" % points
