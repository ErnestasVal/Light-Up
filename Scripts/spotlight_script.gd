class_name Spotlight
extends LightBase

var isPickedUp : bool = false

@onready var spotlightLegs : GeometryInstance3D = %Leg
@onready var player = get_tree().get_first_node_in_group("PlayerCharacter")
@onready var cameraRay : RayCast3D = player.cam_holder.camera_ray
@onready var pickup_area : Area3D = %PickUpArea
@onready var rigidbody : RigidBody3D = $"."

func _process(delta: float) -> void:
	checkInputs()
	if isPickedUp:
		global_position = player.pick_up_point.global_position
		if cameraRay.is_colliding():
			rotation_degrees.y = cameraRay.get_collision_point().y - 180
			lightHead.look_at(cameraRay.get_collision_point())
			lightHead.rotation.x = -lightHead.rotation.x			
			lightHead.rotation_degrees.y = lightHead.rotation_degrees.y - 180 
		else:
			lightHead.rotation.x = -player.cam.global_rotation.x
			lightHead.rotation_degrees.y = 0
			rotation_degrees.y = player.cam_holder.global_rotation_degrees.y - 180
		spotlightLegs.rotation.y = lightHead.rotation.y

func checkInputs() -> void:
	if Input.is_action_just_pressed("activate_object"):
		if isPickedUp:
			# Always allow dropping the currently held object
			handleActivate()
		elif pickup_area.get_overlapping_areas().has(player.hitbox_area):
			# Only pick up if no other object is already held
			if not player.has_picked_up_object:
				# Check we are the closest object to the player
				if _is_closest_interactable():
					handleActivate()


func _is_closest_interactable() -> bool:
	var closest = null
	var closest_dist = INF
	
	for area in player.hitbox_area.get_overlapping_areas():
		var obj = area.get_parent()  # adjust if your pickup_area is on the object itself
		if obj.has_method("handleActivate"):
			var dist = obj.global_position.distance_to(player.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = obj
	
	return closest == self

func handleActivate() -> void:
	isPickedUp = !isPickedUp
	#if rigidbody:
	#	rigidbody.freeze = !rigidbody.freeze
	player.has_picked_up_object = isPickedUp  # track on the player
