extends SignalBase
class_name SolarPanel

@export var colorSensitive : bool = false
@export var sensitiveTo : Color = "#FFFFFF"
@export var activation_delay: float = 1.0
var _activation_tween: Tween = null

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("detectable_planes")
	super()

func activate(light_color : Color = "#000000"):
	if !colorSensitive || (colorSensitive && sensitiveTo.is_equal_approx(light_color)):
		if _activation_tween:
			return
		
		_activation_tween = create_tween()
		_activation_tween.tween_interval(activation_delay)
		_activation_tween.tween_callback(_do_activate)

func deactivate(light_color : Color = "#000000"):
	# Interrupt activation if still waiting
	if !colorSensitive || (colorSensitive && sensitiveTo.is_equal_approx(light_color)):
		if _activation_tween:
			_activation_tween.kill()
			_activation_tween = null
		else : super.deactivate()

func _do_activate():
	_activation_tween = null
	super.activate()
