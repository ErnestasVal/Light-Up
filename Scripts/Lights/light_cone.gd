class_name LightCone
extends Node3D
@onready var node : Node3D = $"."
@onready var light : SpotLight3D = $"../SpotLight3D"
@onready var lightHead : MeshInstance3D = %LightHead
@onready var mesh : MeshInstance3D = $Cone

@export var cone_tip_offset: Vector3 = Vector3.ZERO  # local offset if needed
@export var cone_direction_local: Vector3 = Vector3.DOWN
@export_flags_3d_physics var occluder_mask: int = 0x7fffffff
@export var transparent_occluder_group: StringName = &"light_transparent"
@export var max_transparent_hits: int = 8
# Tracks which planes are currently "inside"
var planes_inside: Dictionary = {}  # Node -> bool

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
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
		_update_visual_clip()
		for plane in get_tree().get_nodes_in_group("detectable_planes"):
			var was_inside = planes_inside.get(plane, false)
			var now_inside = is_point_in_cone(plane.global_position, plane)

			if now_inside and not was_inside:
				planes_inside[plane] = true
				_on_plane_entered(plane)
			elif not now_inside and was_inside:
				planes_inside[plane] = false
				_on_plane_exited(plane)


func _update_visual_clip() -> void:
	var shader_mat := mesh.get_surface_override_material(0) as ShaderMaterial
	if shader_mat == null:
		return

	var tip = global_position + global_basis * cone_tip_offset
	var dir = (global_basis * cone_direction_local).normalized()
	var beam_end = tip + dir * light.spot_range
	var hit = _intersect_first_opaque(tip, beam_end)

	var clip_t := 1.0
	if not hit.is_empty():
		clip_t = clamp(tip.distance_to(hit.get("position") as Vector3) / max(light.spot_range, 0.001), 0.0, 1.0)

	shader_mat.set_shader_parameter("wall_clip_t", clip_t)

func is_point_in_cone(point: Vector3, target_plane: Node = null) -> bool:
	var tip = global_position + global_basis * cone_tip_offset
	var dir = (global_basis * cone_direction_local).normalized()
	var to_point = point - tip
	var projected = to_point.dot(dir)

	if projected < 0.0 or projected > light.spot_range:
		return false

	var angle = rad_to_deg(acos(clamp(to_point.normalized().dot(dir), -1.0, 1.0)))
	if angle > light.spot_angle:
		return false

	return _has_line_of_sight(tip, point, target_plane)


func _has_line_of_sight(from: Vector3, to: Vector3, target_plane: Node) -> bool:
	var hit := _intersect_first_opaque(from, to)

	if hit.is_empty():
		return true

	var collider: Object = hit.get("collider")
	if collider == null:
		return false

	if target_plane != null and collider is Node and _is_target_plane_hit(collider as Node, target_plane):
		return true

	return false


func _intersect_first_opaque(from: Vector3, to: Vector3) -> Dictionary:
	var space_state := get_world_3d().direct_space_state
	var exclude: Array[RID] = []
	var current_from := from
	var direction := (to - from).normalized()

	for _i in range(max_transparent_hits + 1):
		var query := PhysicsRayQueryParameters3D.create(current_from, to, occluder_mask, exclude)
		query.collide_with_areas = false
		var hit := space_state.intersect_ray(query)

		if hit.is_empty():
			return {}

		var collider: Object = hit.get("collider")
		if collider == null:
			return hit

		if collider is Node and (collider as Node).is_in_group(transparent_occluder_group):
			exclude.append(hit.get("rid"))
			current_from = (hit.get("position") as Vector3) + direction * 0.01
			continue

		return hit

	return {}


func _is_target_plane_hit(hit_node: Node, target_plane: Node) -> bool:
	return hit_node == target_plane or target_plane.is_ancestor_of(hit_node) or hit_node.is_ancestor_of(target_plane)

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
