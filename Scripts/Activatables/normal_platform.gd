extends ActivatableBase

@export var off_transparency : float = 0.1
@export var on_transparency : float = 0.8
@onready var mesh : MeshInstance3D = $"."
@onready var collision_shape : CollisionShape3D = $StaticBody3D/CollisionShape3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	setParameters()

func toggle():
	super()
	setParameters()

func setParameters():
	if isActivated:
		mesh.get_surface_override_material(0).albedo_color.a = on_transparency
		collision_shape.disabled = false
	else:
		mesh.get_surface_override_material(0).albedo_color.a = off_transparency
		collision_shape.disabled = true
