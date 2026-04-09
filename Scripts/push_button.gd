extends SignalBase

@export var activation_time : float = 5.0
@onready var player = get_tree().get_first_node_in_group("PlayerCharacter")
@onready var hitbox : Area3D = $HitBox
@onready var animation_player : AnimationPlayer = $AnimationPlayer
var _activation_tween: Tween = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	checkInputs()

func checkInputs() -> void:
	if Input.is_action_just_pressed("activate_object"):
		if hitbox.get_overlapping_areas().has(player.hitbox_area):
			if not player.has_picked_up_object:
				# Check we are the closest object to the player
				if _is_closest_interactable():
					handleActivate()

func handleActivate():
	if _activation_tween:
		_activation_tween.kill()
		_activation_tween = null
	activate()
	animation_player.play("button_push")
	_activation_tween = create_tween()
	_activation_tween.tween_interval(activation_time)
	_activation_tween.tween_callback(_do_deactivate)
	
func _do_deactivate():
	_activation_tween = null
	super.deactivate()

func _is_closest_interactable() -> bool:
	var closest = null
	var closest_dist = INF
	
	for area in player.hitbox_area.get_overlapping_areas():
		var obj = area.get_parent()  # adjust if your pickup_area is on the object itself
		if obj.has_method("handleActivate"):
			var dist = obj.global_position.distance_to(player.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = obj
	
	return closest == self
