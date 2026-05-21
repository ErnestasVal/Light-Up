class_name LightPlatform
extends Node3D

@export var collision_height: float = 0.2
@export var minimum_hit_radius: float = 0.15
@export var maximum_hit_radius_factor: float = 0.5
@export var cell_size: float = 0.25
@export var inverted: bool = false
@export var color_sensitive: bool = false
@export var sensitive_color: Color = Color(1, 1, 1)
@export var color_tolerance: float = 0.12
@export var transparency: float = 0.25

@onready var mesh: MeshInstance3D = $"."
@onready var collision_body: StaticBody3D = $StaticBody3D
@onready var base_collision: CollisionShape3D = $StaticBody3D/CollisionShape3D
var platform_material: StandardMaterial3D
var default_platform_color: Color

var platform_aabb: AABB
var surface_y: float = 0.0
var cone_collisions: Dictionary[Node, CollisionShape3D] = {}
var platform_cells: Array[CollisionShape3D] = []


func _ready() -> void:
	platform_aabb = mesh.get_aabb()
	surface_y = platform_aabb.end.y
	platform_material = _ensure_platform_material()
	if platform_material != null:
		default_platform_color = platform_material.albedo_color
		# If color sensitive, set the platform color once on load and do not change it at runtime
		if color_sensitive:
			var inv_load: Color = invert_color_hue(sensitive_color)
			inv_load.a = transparency
			platform_material.albedo_color = inv_load
	if inverted:
		base_collision.disabled = true
		_build_platform_cells()
	else:
		base_collision.disabled = true
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	var seen_cones: Dictionary = {}

	for light_source in get_tree().get_nodes_in_group("light_sources"):
		if not (light_source is LightBase):
			continue

		var light_base := light_source as LightBase
		if color_sensitive and not _color_matches(light_base.lightColor):
			continue

		var cone := light_base.lightCone
		if cone == null or not is_instance_valid(cone):
			continue

		seen_cones[cone] = true
		if not inverted:
			_sync_cone_collision(cone)

	# (Color is set once on load when `color_sensitive` is enabled.)

	if inverted:
		_update_inverted_collision(seen_cones.keys())
		for cone in cone_collisions.keys().duplicate():
			_remove_cone_collision(cone)
		return

	for cone in cone_collisions.keys().duplicate():
		if not seen_cones.has(cone) or not is_instance_valid(cone):
			_remove_cone_collision(cone)


func _build_platform_cells() -> void:
	for child in collision_body.get_children():
		if child is CollisionShape3D and child != base_collision:
			child.queue_free()

	platform_cells.clear()

	var cell_count_x: int = max(1, ceili(platform_aabb.size.x / max(cell_size, 0.01)))
	var cell_count_z: int = max(1, ceili(platform_aabb.size.z / max(cell_size, 0.01)))
	var cell_size_x: float = platform_aabb.size.x / cell_count_x
	var cell_size_z: float = platform_aabb.size.z / cell_count_z
	var shape_size: Vector3 = Vector3(cell_size_x, collision_height, cell_size_z)

	for x in range(cell_count_x):
		for z in range(cell_count_z):
			var cell := CollisionShape3D.new()
			cell.name = "LightCell_%d_%d" % [x, z]
			var box := BoxShape3D.new()
			box.size = shape_size
			cell.shape = box

			var center_x: float = platform_aabb.position.x + (x + 0.5) * cell_size_x
			var center_z: float = platform_aabb.position.z + (z + 0.5) * cell_size_z
			cell.position = Vector3(center_x, surface_y + collision_height * 0.5, center_z)
			collision_body.add_child(cell)
			platform_cells.append(cell)


func _update_inverted_collision(active_cones: Array) -> void:
	for cell in platform_cells:
		if is_instance_valid(cell):
			cell.disabled = false

	for cone_node in active_cones:
		if not (cone_node is LightCone):
			continue

		var hit_data := _get_hit_data(cone_node)
		if hit_data.is_empty():
			continue

		var hit_position: Vector3 = hit_data["position"]
		var hit_radius: float = hit_data["radius"]
		for cell in platform_cells:
			if not is_instance_valid(cell):
				continue
			var cell_center := cell.position
			var distance := Vector2(cell_center.x - hit_position.x, cell_center.z - hit_position.z).length()
			if distance <= hit_radius + max(cell_size, _get_cell_half_size(cell)):
				cell.disabled = true


func _get_cell_half_size(cell: CollisionShape3D) -> float:
	if cell.shape is BoxShape3D:
		return (cell.shape as BoxShape3D).size.x * 0.5

	return 0.0



func _sync_cone_collision(cone: LightCone) -> void:
	var hit_data := _get_hit_data(cone)
	if hit_data.is_empty():
		_remove_cone_collision(cone)
		return

	var collision := _get_or_create_cone_collision(cone)
	var shape := collision.shape as CylinderShape3D
	if shape == null:
		shape = CylinderShape3D.new()
		collision.shape = shape

	shape.height = collision_height
	shape.radius = hit_data["radius"]
	var hit_position: Vector3 = hit_data["position"]
	collision.position = Vector3(hit_position.x, surface_y + collision_height * 0.5, hit_position.z)


func _get_hit_data(cone: LightCone) -> Dictionary:
	if cone == null or not is_instance_valid(cone.light):
		return {}

	var tip_global := cone.global_position + cone.global_basis * cone.cone_tip_offset
	var dir_global := (cone.global_basis * cone.cone_direction_local).normalized()
	var tip_local := to_local(tip_global)
	var dir_local := global_transform.basis.inverse() * dir_global

	if abs(dir_local.y) < 0.0001:
		return {}

	var travel := (surface_y - tip_local.y) / dir_local.y
	if travel < 0.0:
		return {}

	var hit_local := tip_local + dir_local * travel
	if hit_local.x < platform_aabb.position.x or hit_local.x > platform_aabb.end.x:
		return {}
	if hit_local.z < platform_aabb.position.z or hit_local.z > platform_aabb.end.z:
		return {}

	var radius: float = max(travel * tan(deg_to_rad(cone.light.spot_angle)), minimum_hit_radius)
	var max_radius: float = min(platform_aabb.size.x, platform_aabb.size.z) * maximum_hit_radius_factor
	radius = min(radius, max_radius)

	return {
		"position": hit_local,
		"radius": radius,
	}


func _get_or_create_cone_collision(cone: Node) -> CollisionShape3D:
	if cone_collisions.has(cone):
		var existing: CollisionShape3D = cone_collisions[cone]
		if is_instance_valid(existing):
			return existing

	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "LightCollision_%d" % cone_collisions.size()
	collision_body.add_child(collision)
	cone_collisions[cone] = collision
	return collision


func _remove_cone_collision(cone: Node) -> void:
	if not cone_collisions.has(cone):
		return

	var collision: CollisionShape3D = cone_collisions[cone]
	cone_collisions.erase(cone)
	if is_instance_valid(collision):
		collision.queue_free()


func _ensure_platform_material() -> StandardMaterial3D:
	var idx: int = 0
	var override_material := mesh.get_surface_override_material(idx) as StandardMaterial3D
	if override_material != null:
		return override_material

	if mesh.mesh == null or mesh.mesh.get_surface_count() == 0:
		return null

	var source_material := mesh.mesh.surface_get_material(idx) as StandardMaterial3D
	if source_material == null:
		source_material = StandardMaterial3D.new()
	else:
		source_material = source_material.duplicate() as StandardMaterial3D

	mesh.set_surface_override_material(idx, source_material)
	return source_material


func _color_matches(light_color: Color) -> bool:
	# Use hue-based matching when possible; fallback to RGB distance for low saturation
	var lc_hsv: Vector3 = rgb_to_hsv(light_color)
	var sc_hsv: Vector3 = rgb_to_hsv(sensitive_color)
	var hue_tol: float = max(0.0, color_tolerance)

	# If either color is nearly desaturated, RGB distance is more reliable
	if lc_hsv.y < 0.05 or sc_hsv.y < 0.05:
		var dr: float = light_color.r - sensitive_color.r
		var dg: float = light_color.g - sensitive_color.g
		var db: float = light_color.b - sensitive_color.b
		var diff_len: float = Vector3(dr, dg, db).length()
		return diff_len <= hue_tol

	return hue_distance(lc_hsv.x, sc_hsv.x) <= hue_tol


func invert_color_hue(c: Color) -> Color:
	var hsv: Vector3 = rgb_to_hsv(c)
	hsv.x = fposmod(hsv.x + 0.5, 1.0)
	var out: Color = hsv_to_rgb(hsv.x, hsv.y, hsv.z)
	out.a = c.a
	return out


func rgb_to_hsv(c: Color) -> Vector3:
	var r: float = c.r
	var g: float = c.g
	var b: float = c.b
	var maxv: float = max(r, max(g, b))
	var minv: float = min(r, min(g, b))
	var v: float = maxv
	var d: float = maxv - minv
	var s: float = 0.0
	if maxv > 0.0:
		s = d / maxv

	var h: float = 0.0
	if d > 0.0:
		if maxv == r:
			h = (g - b) / d
			h = fposmod(h, 6.0)
		elif maxv == g:
			h = (b - r) / d + 2.0
		else:
			h = (r - g) / d + 4.0
		h = h / 6.0
		if h < 0.0:
			h += 1.0

	return Vector3(h, s, v)


func hsv_to_rgb(h: float, s: float, v: float) -> Color:
	if s <= 0.0:
		return Color(v, v, v)

	var hh: float = fposmod(h, 1.0) * 6.0
	var i: int = int(floor(hh))
	var f: float = hh - float(i)
	var p: float = v * (1.0 - s)
	var q: float = v * (1.0 - s * f)
	var t: float = v * (1.0 - s * (1.0 - f))

	match i % 6:
		0:
			return Color(v, t, p)
		1:
			return Color(q, v, p)
		2:
			return Color(p, v, t)
		3:
			return Color(p, q, v)
		4:
			return Color(t, p, v)
		5:
			return Color(v, p, q)

	return Color(0, 0, 0)


func hue_distance(h1: float, h2: float) -> float:
	var d: float = abs(h1 - h2)
	if d > 0.5:
		d = 1.0 - d
	return d
