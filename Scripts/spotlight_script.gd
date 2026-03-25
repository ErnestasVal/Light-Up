class_name Spotlight
extends LightBase

var isPickedUp : bool = false

@onready var spotlightLegs : GeometryInstance3D = %Leg
@onready var player = get_tree().get_first_node_in_group("PlayerCharacter")
@onready var cameraRay : RayCast3D = player.cam_holder.camera_ray
@onready var pickup_area : Area3D = $PickUpArea

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
	if Input.is_action_just_pressed("pick_up_object"):
		if pickup_area.get_overlapping_areas().has(player.hitbox_area) || isPickedUp:
			handlePickup()

func handlePickup() -> void:
	isPickedUp = !isPickedUp
	#lightHead.set_layer_mask_value(1, !isPickedUp)
	#spotlightLegs.set_layer_mask_value(1, !isPickedUp)
