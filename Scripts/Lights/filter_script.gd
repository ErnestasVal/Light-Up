extends RigidBody3D

@export var hold_offset : Vector3
@export var filter_color : Color = "#0000ff"
var is_on_light : bool = false
var is_held : bool = false
var light : LightBase
@onready var mesh : MeshInstance3D = $Filter
@onready var pickup_area : Area3D = $PickupArea
@onready var player : PlayerCharacter = get_tree().get_first_node_in_group("PlayerCharacter")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mesh.get_surface_override_material(1).albedo_color = filter_color
	mesh.get_surface_override_material(1).albedo_color.a = 0.15
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	checkInputs()
	if is_on_light:
		global_position = light.lightHead.global_position
		rotation.x = light.lightHead.rotation.x	#Up and Down, Z rotation
		rotation.y = light.rotation.y + light.lightHead.rotation.y	#Left and Right rotation
	elif is_held:
		global_position = player.pick_up_point.global_position
		rotation_degrees.y = player.cam_holder.global_rotation_degrees.y - 180

func checkInputs() -> void:
	if Input.is_action_just_pressed("interact"):
		interact()
		
func interact():
	if !is_held && pickup_area.get_overlapping_areas().has(player.hitbox_area) && !player.has_picked_up_object:
		if is_on_light:
			is_on_light = false
			light.lightColor = light.default_light_color
			light.setLightValues()
		is_held = true
		player.picked_up_object = self
		player.has_picked_up_object = true
	elif is_held:
		# Calculate a safe drop position in front of/below the pick_up_point
		var drop_position = player.pick_up_point.global_position
		
		# Cast a ray downward from drop position to find the floor
		var space_state = get_world_3d().direct_space_state
		var ray_origin = drop_position
		var ray_end = drop_position + Vector3.DOWN * 5.0  # Max 5 units down
		
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.exclude = [self]  # Don't hit ourselves
		var result = space_state.intersect_ray(query)
		
		if result:
			# Place object just above the detected floor
			global_position = result.position + Vector3.UP * 0.1
		else:
			# Fallback: drop slightly in front of the player at feet level
			global_position = player.global_position + player.global_transform.basis.z * -1.0 + Vector3.UP * 0.5
		
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		
		is_held = false
		player.has_picked_up_object = false
		player.picked_up_object = null
		
		var closest_light = _closest_pickupable()
		if closest_light:
			is_on_light = true
			light = closest_light
			light.lightColor = filter_color
			light.setLightValues()

func _closest_pickupable() -> LightBase:
	var closest = null
	var closest_dist = INF
	
	for area in player.hitbox_area.get_overlapping_areas():
		var obj = area.get_parent()  # adjust if your pickup_area is on the object itself
		if obj.has_method("pickUp"):
			var dist = obj.global_position.distance_to(player.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = obj
	return closest
