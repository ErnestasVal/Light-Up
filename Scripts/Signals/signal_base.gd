class_name SignalBase
extends Node3D

@export var activateObject : Node3D
@export var inverted : bool = false
@export var activation_time: float = 1.0
@export var deactivation_time: float = 1.0
var _activation_tween: Tween = null
var _deactivation_tween: Tween = null
var momentary: bool = false

var activated : bool
signal activated_object
signal deactivated_object

func _ready() -> void:
	if inverted && activateObject != null && activateObject.has_method("increment"):
		activateObject.increment()
		
func activate():
	if _activation_tween:
		return
	activated_object.emit()
	_activation_tween = create_tween()
	_activation_tween.tween_interval(activation_time)
	_activation_tween.tween_callback(_do_activate)
	if momentary:
		if _deactivation_tween:
			_deactivation_tween.kill()
			_deactivation_tween = null
		_deactivation_tween = create_tween()
		_deactivation_tween.tween_interval(deactivation_time)
		_deactivation_tween.tween_callback(_do_deactivate)

func deactivate():
	if _activation_tween:
			_activation_tween.kill()
			_activation_tween = null
			deactivated_object.emit()
			pass
	if _deactivation_tween:
		_deactivation_tween.kill()
		_deactivation_tween = null
	_deactivation_tween = create_tween()
	_deactivation_tween.tween_interval(deactivation_time)
	_deactivation_tween.tween_callback(_do_deactivate)
	
func _do_activate():
	_activation_tween = null
	if activated != !inverted:
		activated = !inverted
		if !inverted && activateObject != null && activateObject.has_method("increment"):
			activateObject.increment()
			
		if inverted && activateObject != null && activateObject.has_method("decrement"):
			activateObject.decrement()
			

func _do_deactivate():
	deactivated_object.emit()
	if activated != inverted:
		activated = inverted
		if !inverted && activateObject != null && activateObject.has_method("decrement"):
			activateObject.decrement()
		if inverted && activateObject != null && activateObject.has_method("increment"):
			activateObject.increment()
			
