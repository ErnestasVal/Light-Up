extends Node3D

@export var activateObject : Node3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_area_entered(area: Area3D) -> void:
	print_debug("enters")
	if activateObject.has_method("toggle"):
		activateObject.toggle()


func _on_area_3d_area_exited(area: Area3D) -> void:
	if activateObject.has_method("toggle"):
		activateObject.toggle()
