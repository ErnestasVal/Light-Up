extends Node
var isPickedUp : bool = false
@export var lightColor : Color = 'fff2cc'
@onready var node : Node3D = $"."
@onready var light : SpotLight3D = $LightHead/SpotLight3D
@onready var lightCone : Node3D = $LightHead/LightCone
@onready var spotlightHead : GeometryInstance3D = %LightHead
@onready var spotlightLegs : GeometryInstance3D = %Leg
@onready var player = get_tree().get_first_node_in_group("PlayerCharacter")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	light.light_color = lightColor
	lightCone.setChangedValues()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	checkInputs()
	if isPickedUp:
		node.position = player.global_position
		node.position.y -= 1
		spotlightHead.rotation.x = -player.cam.global_rotation.x
		spotlightHead.rotation_degrees.y = player.cam_holder.global_rotation_degrees.y - 180

func checkInputs() -> void:
	if Input.is_action_just_pressed("pick_up_object"):
		handlePickup()

func handlePickup() -> void:
	isPickedUp = !isPickedUp
	spotlightHead.set_layer_mask_value(1, !isPickedUp)
	spotlightLegs.set_layer_mask_value(1, !isPickedUp)
