extends SignalBase
class_name SolarPanel

@export var colorSensitive : bool = false
@export var sensitiveTo : Color = "#FFFFFF"

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("detectable_planes")
	super()

func activate(light_color : Color = "#000000"):
	if !colorSensitive || (colorSensitive && sensitiveTo.is_equal_approx(light_color)):
		super()

func deactivate(light_color : Color = "#000000"):
	if !colorSensitive || (colorSensitive && sensitiveTo.is_equal_approx(light_color)):
		super()
