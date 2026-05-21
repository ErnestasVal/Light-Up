extends RigidBody3D

var isPickedUp: bool = false
var isFalling: bool = false

@onready var player = get_tree().get_first_node_in_group("PlayerCharacter")
@onready var pickup_area: Area3D = $PickupArea

func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	_handle_inputs()
	if isPickedUp and is_instance_valid(player):
		global_position = player.pick_up_point.global_position
		if is_instance_valid(player.cam_holder):
			rotation_degrees.y = player.cam_holder.global_rotation_degrees.y - 180


func _handle_inputs() -> void:
	if not is_instance_valid(player):
		return
	if Input.is_action_just_pressed("activate_object"):
		if isPickedUp:
			pickUp()
		elif pickup_area.get_overlapping_areas().has(player.hitbox_area):
			if not player.has_picked_up_object and player.state_machine.curr_state != JumpState:
				if _is_closest_activatable():
					pickUp()


func _is_closest_activatable() -> bool:
	if not is_instance_valid(player) or not is_instance_valid(player.hitbox_area):
		return false

	var closest = null
	var closest_dist = INF
	for area in player.hitbox_area.get_overlapping_areas():
		var obj = area.get_parent()
		if obj and obj.has_method("pickUp"):
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
		freeze = true
		set_collision_layer_value(1, false)
	else:
		player.picked_up_object = null

		var drop_offset = -player.cam.global_basis.z * 0.6
		global_position = player.pick_up_point.global_position + drop_offset

		freeze = false
		set_collision_layer_value(1, true)

		linear_velocity = player.velocity if player.has_method("get") else Vector3.ZERO

		sleeping = false
		isFalling = true

	player.has_picked_up_object = isPickedUp
