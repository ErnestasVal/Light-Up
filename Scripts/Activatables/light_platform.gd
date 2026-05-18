class_name LightPlatform
extends Node3D

@export var collision_height: float = 0.2
@export var minimum_hit_radius: float = 0.15
@export var maximum_hit_radius_factor: float = 0.5
@export var cell_size: float = 0.25
@export var inverted: bool = true

@onready var mesh: MeshInstance3D = $"."
@onready var collision_body: StaticBody3D = $StaticBody3D
@onready var base_collision: CollisionShape3D = $StaticBody3D/CollisionShape3D

var platform_aabb: AABB
var surface_y: float = 0.0
var cone_collisions: Dictionary[Node, CollisionShape3D] = {}
var platform_cells: Array[CollisionShape3D] = []


func _ready() -> void:
	platform_aabb = mesh.get_aabb()
	surface_y = platform_aabb.end.y
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

		var cone := (light_source as LightBase).lightCone
		if cone == null or not is_instance_valid(cone):
			continue

		seen_cones[cone] = true
		if not inverted:
			_sync_cone_collision(cone)

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
