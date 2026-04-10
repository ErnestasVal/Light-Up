extends SignalBase

@onready var player = get_tree().get_first_node_in_group("PlayerCharacter")
@onready var hitbox : Area3D = $HitBox
@onready var animation_player : AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	momentary = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	checkInputs()

func checkInputs() -> void:
	if Input.is_action_just_pressed("activate_object"):
		if hitbox.get_overlapping_areas().has(player.hitbox_area):
			if not player.has_picked_up_object:
				# Check we are the closest object to the player
				if _is_closest_activatable():
					activate()

func activate():
	animation_player.play("button_push")
	super()

func _is_closest_activatable() -> bool:
	var closest = null
	var closest_dist = INF
	
	for area in player.hitbox_area.get_overlapping_areas():
		var obj = area.get_parent()  # adjust if your pickup_area is on the object itself
		if obj.has_method("activate"):
			var dist = obj.global_position.distance_to(player.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = obj
	
	return closest == self
