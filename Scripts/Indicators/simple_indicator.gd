extends IndicatorBase

@export var off_image : CompressedTexture2D
@export var on_image : CompressedTexture2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_reset()
	super()

func _on_activated_object():
	super()
	setImage()

func _reset():
	super()
	setImage()

func setImage():
	if isOn:
		texture = on_image
	else:
		texture = off_image
