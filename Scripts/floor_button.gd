extends Node3D

@export var activateObject : Node3D
var enteredAreas : Array[Area3D]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enteredAreas.clear()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_area_entered(area: Area3D) -> void:
	print_debug("entered")
	enteredAreas.append(area)
	if activateObject.has_method("toggle") && len(enteredAreas) == 1:
		activateObject.toggle()


func _on_area_3d_area_exited(area: Area3D) -> void:
	enteredAreas.erase(area)
	if activateObject.has_method("toggle") && len(enteredAreas) == 0:
		activateObject.toggle()
