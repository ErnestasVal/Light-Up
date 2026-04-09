extends IndicatorBase

@export var off_image : CompressedTexture2D
@export var on_image : CompressedTexture2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_reset()
	super()

func _on_activated_object():
	texture = on_image

func _reset():
	texture = off_image
