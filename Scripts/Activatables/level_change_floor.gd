extends Node3D

@export var next_level : PackedScene
@onready var player : PlayerCharacter = get_tree().get_first_node_in_group("PlayerCharacter")
var _level_change_tween: Tween = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _do_change_level():
	if next_level:
		get_tree().change_scene_to_packed(next_level)
	else:
		get_tree().reload_current_scene()

func _on_area_3d_area_entered(area: Area3D) -> void:
	_level_change_tween = create_tween()
	_level_change_tween.tween_interval(0.5)
	_level_change_tween.tween_callback(_do_change_level)
	player.ui.exitLevel()
