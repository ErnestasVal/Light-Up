extends ActivatableBase

@export var off_transparency : float = 0.1
@export var on_transparency : float = 0.8
@export var vertex_transition_time : float = 0.5
@export var ramp_top_height : float = 3.0

@onready var mesh : MeshInstance3D = $"."
@onready var flat_collision : CollisionShape3D = $StaticBody3D/FlatCollision
@onready var ramp_collision : CollisionShape3D = $StaticBody3D/RampCollision

var ramp_shape : ConvexPolygonShape3D
var base_collision_points : PackedVector3Array = PackedVector3Array()
var base_mesh_arrays : Array = []
var shape_tween : Tween

func _ready() -> void:
	super()
	_prepare_shape()
	flat_collision.disabled = true
	ramp_collision.disabled = false
	setParameters(false)

func toggle() -> void:
	super()
	setParameters(true)


func set_shape_flat() -> void:
	_stop_shape_tween()
	_apply_geometry(0.0)


func set_shape_ramp() -> void:
	_stop_shape_tween()
	_apply_geometry(ramp_top_height)


func bring_vertexes_up_to_ramp() -> void:
	_animate_geometry(ramp_top_height)


func bring_vertexes_down_to_flat() -> void:
	_animate_geometry(0.0)


func setParameters(animated: bool = true) -> void:
	var material := mesh.get_surface_override_material(0) as StandardMaterial3D
	if material != null:
		if isActivated:
			material.albedo_color.a = on_transparency
		else:
			material.albedo_color.a = off_transparency

	if isActivated:
		flat_collision.disabled = true
		ramp_collision.disabled = false
		if animated:
			bring_vertexes_up_to_ramp()
		else:
			set_shape_ramp()
	else:
		if animated:
			bring_vertexes_down_to_flat()
		else:
			set_shape_flat()
		flat_collision.disabled = true
		ramp_collision.disabled = false


func _prepare_shape() -> void:
	var shape := ramp_collision.shape as ConvexPolygonShape3D
	if shape == null:
		return

	ramp_shape = shape.duplicate() as ConvexPolygonShape3D
	ramp_collision.shape = ramp_shape
	base_collision_points = _copy_points(ramp_shape.points)

	if mesh.mesh is ArrayMesh:
		var mesh_res := mesh.get_mesh()
		var mesh_resource := mesh_res.duplicate() as ArrayMesh
		mesh.set_mesh(mesh_resource)
		if mesh_resource != null and mesh_resource.get_surface_count() > 0:
			base_mesh_arrays = mesh_resource.surface_get_arrays(0)


func _apply_geometry(target_height: float) -> void:
	_apply_collision_height(target_height)
	_apply_mesh_height(target_height)


func _animate_geometry(target_height: float) -> void:
	if vertex_transition_time <= 0.0:
		_apply_geometry(target_height)
		return

	if shape_tween != null:
		shape_tween.kill()
		shape_tween = null

	var current_height := _get_top_vertex_height()
	if is_equal_approx(current_height, target_height):
		_apply_geometry(target_height)
		return

	shape_tween = create_tween()
	shape_tween.tween_method(_apply_geometry, current_height, target_height, vertex_transition_time)


func _stop_shape_tween() -> void:
	if shape_tween != null:
		shape_tween.kill()
		shape_tween = null


func _copy_points(points: PackedVector3Array) -> PackedVector3Array:
	var copied := PackedVector3Array()
	for point in points:
		copied.append(point)
	return copied


func _get_highest_y(points: PackedVector3Array) -> float:
	var highest_y := -INF
	for point in points:
		highest_y = max(highest_y, point.y)
	return highest_y


func _get_top_vertex_height() -> float:
	if ramp_shape == null:
		return 0.0

	return _get_highest_y(ramp_shape.points)



func _apply_collision_height(height: float) -> void:
	if ramp_shape == null or base_collision_points.is_empty():
		return

	var points := _copy_points(base_collision_points)
	var highest_y := _get_highest_y(points)
	for index in range(points.size()):
		if is_equal_approx(points[index].y, highest_y):
			var vertex := points[index]
			vertex.y = height
			points[index] = vertex

	ramp_shape.points = points


func _apply_mesh_height(height: float) -> void:
	var mesh_res = mesh.get_mesh()
	if not (mesh_res is ArrayMesh):
		return

	var arrays = mesh_res.surface_get_arrays(0)
	if arrays.is_empty():
		return
	var vertices = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	if vertices.is_empty():
		return
	
	var highest_y := -INF
	for v in vertices:
		highest_y = max(highest_y, v.y)

	for i in range(vertices.size()):
		if is_equal_approx(vertices[i].y, highest_y):
			var vv : Vector3 = vertices[i]
			vv.y = height
			vertices[i] = vv

	arrays[Mesh.ARRAY_VERTEX] = vertices

	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.set_mesh(array_mesh)
