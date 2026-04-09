class_name ActivatableBase
extends Node3D

@export var neededToActivate = 1
@export var inverted : bool = false
var isActivated : bool 
var activeCount : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	isActivated = inverted

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func increment():
	activeCount += 1
	if activeCount >= neededToActivate && isActivated == inverted:
		toggle()

func decrement():
	activeCount -= 1
	if activeCount < neededToActivate && isActivated != inverted:
		toggle()

func toggle():
	isActivated = !isActivated
