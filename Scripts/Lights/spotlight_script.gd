class_name Spotlight
extends LightBase

@export var initial_light_head_target: Node3D

var isPickedUp : bool = false
var isFalling : bool = false
var cameraRay : RayCast3D
var lastCollisionPoint : Vector3 = Vector3.INF

@onready var spotlightLegs : GeometryInstance3D = %Leg
@onready var pickup_area : Area3D = %PickUpArea
@onready var rigidbody : RigidBody3D = $"."

func _ready() -> void:
	if player != null:
		cameraRay = player.cam_holder.camera_ray
	super()

	if is_instance_valid(initial_light_head_target):
		_aim_light_head_at(initial_light_head_target.global_position)

func _process(_delta: float) -> void:
	_handle_modify_input()
	checkInputs()
	if isPickedUp:
		global_position = player.pick_up_point.global_position

		if cameraRay.is_colliding():
			lastCollisionPoint = cameraRay.get_collision_point()
			lightHead.look_at(lastCollisionPoint)
			lightHead.rotation.x = -lightHead.rotation.x
			lightHead.rotation_degrees.y = lightHead.rotation_degrees.y - 180
		else:
			lightHead.look_at(cameraRay.to_global(cameraRay.target_position))
			lightHead.rotation.x = -lightHead.rotation.x
			lightHead.rotation_degrees.y = lightHead.rotation_degrees.y - 180
			rotation_degrees.y = player.cam_holder.global_rotation_degrees.y - 180
			lastCollisionPoint = Vector3.INF
		spotlightLegs.rotation.y = lightHead.rotation.y
	else:
		if lastCollisionPoint != Vector3.INF and isFalling:
			lightHead.look_at(lastCollisionPoint)
			lightHead.rotation.x = -lightHead.rotation.x
			lightHead.rotation_degrees.y = lightHead.rotation_degrees.y - 180
			if rigidbody.linear_velocity.is_zero_approx():
				lastCollisionPoint = Vector3.INF
				isFalling = false


func _aim_light_head_at(target_position: Vector3) -> void:
	lightHead.look_at(target_position)
	lightHead.rotation.x = -lightHead.rotation.x
	lightHead.rotation_degrees.y = lightHead.rotation_degrees.y - 180

func checkInputs() -> void:
	if Input.is_action_just_pressed("activate_object"):
		if isPickedUp:
			# Always allow dropping the currently held object
			pickUp()
		elif pickup_area.get_overlapping_areas().has(player.hitbox_area):
			# Only pick up if no other object is already held
			if not player.has_picked_up_object && player.state_machine.curr_state != JumpState:
				# Check we are the closest object to the player
				if _is_closest_activatable():
					pickUp()


func _is_closest_activatable() -> bool:
	var closest = null
	var closest_dist = INF
	
	for area in player.hitbox_area.get_overlapping_areas():
		var obj = area.get_parent()  # adjust if your pickup_area is on the object itself
		if obj.has_method("pickUp"):
			var dist = obj.global_position.distance_to(player.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = obj
	
	return closest == self

func pickUp() -> void:
	isPickedUp = !isPickedUp
	if isPickedUp:
		isFalling = false
		player.picked_up_object = self
		rigidbody.freeze = true  # Freeze instead of layer-toggle while held
		rigidbody.set_collision_layer_value(1, false)
	else:
		player.picked_up_object = null
		
		# Move it to a safe drop position BEFORE re-enabling collision
		var drop_offset = -player.cam.global_basis.z * 0.6  # small forward offset
		rigidbody.global_position = player.pick_up_point.global_position + drop_offset
		
		rigidbody.freeze = false
		rigidbody.set_collision_layer_value(1, true)
		
		# Inherit player velocity so it doesn't snap
		rigidbody.linear_velocity = player.velocity if player.has_method("get") else Vector3.ZERO
		
		# Wake the physics body explicitly
		rigidbody.sleeping = false
		isFalling = true

	player.has_picked_up_object = isPickedUp
