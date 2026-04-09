extends IndicatorBase

var count_down : bool = false

@onready var progress_bar: TextureProgressBar = $SubViewport/TextureProgressBar
@onready var sub_viewport: SubViewport = $SubViewport

func _ready() -> void:
		# Make the viewport texture unique per instance — this is the key fix
	var viewport_texture = sub_viewport.get_texture()
	texture = viewport_texture.duplicate()
	# Re-assign so this sprite uses its own copy
	texture = sub_viewport.get_texture()
	if signal_object:
		if signal_object.momentary:
			count_down = true
			progress_bar.set_max(signal_object.deactivation_time)
			progress_bar.set_value(signal_object.deactivation_time)
		else:
			progress_bar.set_max(signal_object.activation_time)
			progress_bar.set_value(0)
	super()

func _process(delta: float) -> void:
	if isOn:
		if count_down:
			progress_bar.set_value(progress_bar.value - delta)
			if progress_bar.value <= 0:
				_reset()
		elif progress_bar.value < progress_bar.max_value:
			progress_bar.set_value(progress_bar.value + delta)
			if progress_bar.value >= progress_bar.max_value:
				isOn = false
	
func _reset():
	if count_down:
		progress_bar.set_value(progress_bar.max_value)
	else:
		progress_bar.set_value(0)
	super()
