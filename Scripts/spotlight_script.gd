class_name Spotlight
extends LightBase

var isPickedUp : bool = false

@onready var spotlightLegs : GeometryInstance3D = %Leg
@onready var player = get_tree().get_first_node_in_group("PlayerCharacter")

func _process(delta: float) -> void:
	checkInputs()
	if isPickedUp:
		global_position = player.global_position + Vector3(0, -1, 0)
		lightHead.rotation.x = -player.cam.global_rotation.x
		lightHead.rotation_degrees.y = player.cam_holder.global_rotation_degrees.y - 180

func checkInputs() -> void:
	if Input.is_action_just_pressed("pick_up_object"):
		handlePickup()

func handlePickup() -> void:
	isPickedUp = !isPickedUp
	lightHead.set_layer_mask_value(1, !isPickedUp)
	spotlightLegs.set_layer_mask_value(1, !isPickedUp)
