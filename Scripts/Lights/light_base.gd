class_name LightBase
extends Node3D

@export var lightColor : Color = 'fff2cc'
@export var angle : float = 15
@export var light_range : float = 5
@export var energy : float = 5
@export var modification_presets: Array[Vector2] = []

var default_light_color : Color
var default_light_range : float
var default_angle : float
var modification_index : int = -1

@onready var light : SpotLight3D = %SpotLight3D
@onready var lightCone : LightCone = %LightCone
@onready var lightHead : MeshInstance3D = %LightHead
@onready var player : PlayerCharacter = get_tree().get_first_node_in_group("PlayerCharacter")
@onready var interaction_area : Area3D = _get_interaction_area()

func _ready() -> void:
	add_to_group("light_sources")
	setLightValues()
	default_light_color = lightColor
	default_light_range = light_range
	default_angle = angle


func _process(_delta: float) -> void:
	_handle_modify_input()

func setLightValues() -> void:
	light.light_color = lightColor
	light.spot_range = light_range
	light.spot_angle = angle
	light.light_energy = energy
	lightCone.setChangedValues()


func can_modify() -> bool:
	return modification_presets.size() >= 1


func cycle_modification_preset() -> void:
	if not can_modify():
		return

	var total_states := modification_presets.size() + 1
	modification_index = (modification_index + 1) % total_states

	if modification_index == 0:
		light_range = default_light_range
		angle = default_angle
	else:
		var preset := modification_presets[modification_index - 1]
		angle = preset.x
		light_range = preset.y
	setLightValues()


func _handle_modify_input() -> void:
	if player == null or player.has_picked_up_object:
		return

	if not Input.is_action_just_pressed("modify"):
		return

	if not can_modify():
		return

	if not _is_closest_modifiable_light():
		return

	cycle_modification_preset()


func _is_closest_modifiable_light() -> bool:
	if player == null or not is_instance_valid(player.hitbox_area):
		return false

	var closest = null
	var closest_dist = INF

	for area in player.hitbox_area.get_overlapping_areas():
		var obj = area.get_parent()
		if obj is LightBase and (obj as LightBase).can_modify():
			var dist = obj.global_position.distance_to(player.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = obj

	return closest == self


func _get_interaction_area() -> Area3D:
	if has_node("PickUpArea"):
		return get_node("PickUpArea") as Area3D

	if has_node("Area3D"):
		return get_node("Area3D") as Area3D

	return null
