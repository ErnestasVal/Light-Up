class_name SignalBase
extends Node3D

@export var activateObject : Node3D
@export var inverted : bool = false
var activated : bool

func _ready() -> void:
	if inverted && activateObject != null && activateObject.has_method("increment"):
		activateObject.increment()

func activate():
	activated = !inverted
	if !inverted && activateObject != null && activateObject.has_method("increment"):
		activateObject.increment()
	if inverted && activateObject != null && activateObject.has_method("decrement"):
		activateObject.decrement()

func deactivate():
	activated = inverted
	if !inverted && activateObject != null && activateObject.has_method("decrement"):
		activateObject.decrement()
	if inverted && activateObject != null && activateObject.has_method("increment"):
		activateObject.increment()
