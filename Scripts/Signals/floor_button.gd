extends SignalBase
class_name FloorButton
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _on_area_3d_area_entered(area: Area3D) -> void:
	activate()


func _on_area_3d_area_exited(area: Area3D) -> void:
	deactivate()
