class_name IndicatorBase
extends Sprite3D

@export var signal_object : SignalBase
var isOn : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if signal_object != null:
		signal_object.activated_object.connect(_on_activated_object)
		signal_object.deactivated_object.connect(_on_deactivated_object)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_activated_object():
	isOn = true

func _on_deactivated_object():
	_reset()

func _reset():
	isOn = false
