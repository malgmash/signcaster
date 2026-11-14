extends PanelContainer
## A card that shows the sign for one letter. A dumb widget: set letter and texture, nothing else.
##
## With no texture it shows a plain placeholder. Real sign art must be reviewed by Deaf ASL
## signers before it is used (label the PR needs-asl-review). Never draw or describe signs here.

## The letter this card stands for, drawn small in the corner.
@export var letter: String = "":
	set(value):
		letter = value
		_refresh()

## The sign art for the letter. Null shows the placeholder.
@export var texture: Texture2D = null:
	set(value):
		texture = value
		_refresh()

@onready var _art: TextureRect = $Art
@onready var _placeholder: Label = $Placeholder
@onready var _corner: Label = $Corner


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	_art.texture = texture
	_placeholder.visible = texture == null
	_corner.text = letter
