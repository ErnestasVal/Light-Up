class_name UI
extends CanvasLayer

@onready var animation : AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation.play("EnterLevel")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func exitLevel():
	animation.play("ExitLevel")
