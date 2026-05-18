extends Node3D

@export var glass_surface_index: int = 0
@export var sample_columns: int = 3
@export var sample_rows: int = 4
@export var window_color: Color = Color(0.4821648, 0.70091337, 0.9062963, 0.15)

@onready var window_mesh: MeshInstance3D = $"."
@onready var window_body: StaticBody3D = $StaticBody3D
@onready var collision_shape: CollisionShape3D = $StaticBody3D/CollisionShape3D

var glass_material: StandardMaterial3D
var default_glass_color: Color
var active_cones: Dictionary[LightCone, LightBase] = {}
var sample_points: Array[Vector3] = []


func _ready() -> void:
	glass_surface_index = _get_valid_glass_surface_index()
	glass_material = _ensure_glass_material()
	default_glass_color = window_color
	glass_material.albedo_color = window_color
	_build_sample_points()
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	var visible_cones: Dictionary[LightCone, LightBase] = {}

	for light_source in get_tree().get_nodes_in_group("light_sources"):
		if not (light_source is LightBase):
			continue

		var light_base := light_source as LightBase
		var cone := light_base.lightCone
		if cone == null or not is_instance_valid(cone):
			continue

		if _cone_hits_window(cone):
			visible_cones[cone] = light_base
			if not active_cones.has(cone):
				_apply_light_tint(light_base)

	for cone in active_cones.keys().duplicate():
		if not visible_cones.has(cone) or not is_instance_valid(cone):
			_restore_light_tint(cone)

	_refresh_window_color()

	active_cones = visible_cones


func _cone_hits_window(cone: LightCone) -> bool:
	for point in sample_points:
		if cone.is_point_in_cone(point, self):
			return true

	return false


func _build_sample_points() -> void:
	sample_points.clear()

	var box := collision_shape.shape as BoxShape3D
	if box == null:
		sample_points.append(window_body.global_position)
		return

	var columns: int = max(1, sample_columns)
	var rows: int = max(1, sample_rows)
	var half_height: float = box.size.y * 0.5
	var half_width: float = box.size.z * 0.5

	for row in range(rows):
		var row_t: float = 0.0 if rows == 1 else float(row) / float(rows - 1)
		var local_y: float = lerp(-half_height, half_height, row_t)
		for column in range(columns):
			var column_t: float = 0.0 if columns == 1 else float(column) / float(columns - 1)
			var local_z: float = lerp(-half_width, half_width, column_t)
			sample_points.append(window_body.to_global(Vector3(0.0, local_y, local_z)))


func _refresh_window_color() -> void:
	if glass_material == null:
		return

	glass_material.albedo_color = default_glass_color


func _apply_light_tint(light_base: LightBase) -> void:
	var active_count: int = int(light_base.get_meta("window_filter_count", 0))
	if active_count == 0:
		light_base.set_meta("window_filter_original_color", light_base.lightColor)
		light_base.lightColor = window_color
		light_base.setLightValues()

	light_base.set_meta("window_filter_count", active_count + 1)


func _restore_light_tint(cone: LightCone) -> void:
	var light_base := _get_light_base(cone)
	if light_base == null:
		return

	var active_count: int = int(light_base.get_meta("window_filter_count", 0))
	if active_count <= 1:
		if light_base.has_meta("window_filter_original_color"):
			light_base.lightColor = light_base.get_meta("window_filter_original_color")
			light_base.setLightValues()
			light_base.remove_meta("window_filter_original_color")
		else:
			light_base.lightColor = light_base.default_light_color
			light_base.setLightValues()
		light_base.remove_meta("window_filter_count")
	else:
		light_base.set_meta("window_filter_count", active_count - 1)


func _ensure_glass_material() -> StandardMaterial3D:
	var override_material := window_mesh.get_surface_override_material(glass_surface_index) as StandardMaterial3D
	if override_material != null:
		return override_material

	var source_material := window_mesh.mesh.surface_get_material(glass_surface_index) as StandardMaterial3D
	if source_material == null:
		source_material = StandardMaterial3D.new()
	else:
		source_material = source_material.duplicate() as StandardMaterial3D

	window_mesh.set_surface_override_material(glass_surface_index, source_material)
	return source_material


func _get_valid_glass_surface_index() -> int:
	if window_mesh == null or window_mesh.mesh == null:
		return glass_surface_index

	return clamp(glass_surface_index, 0, window_mesh.mesh.get_surface_count() - 1)


func _get_light_base(cone: LightCone) -> LightBase:
	var node: Node = cone
	while node != null:
		if node is LightBase:
			return node as LightBase
		node = node.get_parent()

	return null
