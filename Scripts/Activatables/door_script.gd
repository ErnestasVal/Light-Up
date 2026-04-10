extends ActivatableBase

@onready var door_mesh : MeshInstance3D = $Door
@onready var door_collision : CollisionShape3D = $DoorCollision

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	door_mesh.visible = !inverted
	door_collision.disabled = inverted
	super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func toggle():
	door_mesh.visible = !door_mesh.visible
	door_collision.disabled = !door_collision.disabled
	super()
