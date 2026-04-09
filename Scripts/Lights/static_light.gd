class_name StaticLight
extends LightBase

@export var neededToActivate = 1
@export var inverted : bool = false
var isActivated : bool
var activeCount : int = 0

func _ready() -> void:
	super()
	isActivated = inverted
	lightCone.visible = isActivated
	light.visible = isActivated

func increment():
	activeCount += 1
	if activeCount >= neededToActivate && isActivated == inverted:
		toggle()

func decrement():
	activeCount -= 1
	if activeCount < neededToActivate && isActivated != inverted:
		toggle()

func toggle() -> void:
	isActivated = !isActivated
	lightCone.visible = isActivated
	light.visible = isActivated
