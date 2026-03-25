class_name StaticLight
extends LightBase

@export var isOn : bool = true
@export var isActivated : bool = false

func _ready() -> void:
	super()
	lightCone.visible = isOn
	light.visible = isOn

func toggle() -> void:
	isOn = !isOn
	isActivated = !isActivated
	lightCone.visible = isOn
	light.visible = isOn
