class_name LightCone
extends Node3D
@onready var node : Node3D = $"."
@onready var light : SpotLight3D = $"../SpotLight3D"
@onready var lightHead : MeshInstance3D = %LightHead
@onready var mesh : MeshInstance3D = $Cone

@export var cone_tip_offset: Vector3 = Vector3.ZERO  # local offset if needed
@export var cone_direction_local: Vector3 = Vector3.DOWN
# Tracks which planes are currently "inside"
var planes_inside: Dictionary = {}  # Node -> bool

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
	

func _physics_process(_delta):
	if visible:
		for plane in get_tree().get_nodes_in_group("detectable_planes"):
			var was_inside = planes_inside.get(plane, false)
			var now_inside = is_point_in_cone(plane.global_position)

			if now_inside and not was_inside:
				planes_inside[plane] = true
				_on_plane_entered(plane)
			elif not now_inside and was_inside:
				planes_inside[plane] = false
				_on_plane_exited(plane)

func is_point_in_cone(point: Vector3) -> bool:
	var tip = global_position + global_basis * cone_tip_offset
	var dir = (global_basis * cone_direction_local).normalized()
	var to_point = point - tip
	var projected = to_point.dot(dir)

	if projected < 0.0 or projected > light.spot_range:
		return false

	var angle = rad_to_deg(acos(clamp(to_point.normalized().dot(dir), -1.0, 1.0)))
	return angle <= light.spot_angle

func _on_plane_entered(plane: Node):
	plane.activate(self, light.light_color)

func _on_plane_exited(plane: Node):
	plane.deactivate(self, light.light_color)

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if not visible:
			for plane in planes_inside.keys():
				if is_instance_valid(plane) and planes_inside[plane]:
					planes_inside[plane] = false
					_on_plane_exited(plane)
