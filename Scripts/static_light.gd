class_name StaticLight
extends LightBase

@export var isOn : bool = true

func _ready() -> void:
	super()
	lightCone.visible = isOn
	light.visible = isOn

func toggle() -> void:
	isOn = !isOn
	lightCone.visible = isOn
	light.visible = isOn
