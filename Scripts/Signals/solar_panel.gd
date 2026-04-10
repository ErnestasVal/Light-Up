extends SignalBase
class_name SolarPanel

@export var colorSensitive : bool = false
@export var sensitiveTo : Color = "#FFFFFF"

var activated_lights: Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("detectable_planes")
	super()

func activate(cone: Node = null, light_color : Color = "#000000"):
	if !colorSensitive || (colorSensitive && sensitiveTo.is_equal_approx(light_color)):
		if cone not in activated_lights:
			activated_lights.append(cone)
		super()

func deactivate(cone: Node = null, light_color : Color = "#000000"):
	if !colorSensitive || (colorSensitive && sensitiveTo.is_equal_approx(light_color)):
		activated_lights.erase(cone)
		if activated_lights.is_empty():
			super()
