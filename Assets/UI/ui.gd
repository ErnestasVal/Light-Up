class_name UI
extends CanvasLayer
@export var hudOn = true
@onready var animation : AnimationPlayer = $AnimationPlayer
@onready var hud : Container = $Crosshair

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !hudOn:
		hud.visible = false
	animation.play("EnterLevel")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func exitLevel():
	animation.play("ExitLevel")
