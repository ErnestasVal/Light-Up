class_name LightBase
extends Node3D

@export var lightColor : Color = 'fff2cc'
@export var angle : float = 15
@export var range : float = 5
@export var energy : float = 2

@onready var light : SpotLight3D = $LightHead/SpotLight3D
@onready var lightCone : Node3D = $LightHead/LightCone
@onready var lightHead : MeshInstance3D = %LightHead

func _ready() -> void:
	setLightValues()
	lightCone.setChangedValues()

func setLightValues() -> void:
	light.light_color = lightColor
	light.spot_range = range
	light.spot_angle = angle
	light.light_energy = energy
