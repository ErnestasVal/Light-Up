extends Node3D
@onready var node : Node3D = $"."
@onready var light : SpotLight3D = $"../SpotLight3D"
@onready var lightHead : MeshInstance3D = %LightHead
@onready var mesh : MeshInstance3D = $Cone

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setChangedValues() -> void:
	node.scale.y = light.spot_range
	var radius_scale = light.spot_range * tan(deg_to_rad(light.spot_angle)) * 2
	node.scale.x = radius_scale
	node.scale.z = radius_scale
	lightHead.get_surface_override_material(1).albedo_color = light.light_color
	mesh.get_surface_override_material(0).set_shader_parameter("beam_color", light.light_color)
