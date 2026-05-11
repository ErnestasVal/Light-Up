extends Control

@export var overlay : UI
@export var first_level : PackedScene
@export var debug_level : PackedScene
var _level_change_tween: Tween = null

@onready var startButton : TextureButton = $Start
@onready var selectButton : TextureButton = $LevelSelect
@onready var debugButton : TextureButton = $DebugLevel
@onready var settingsButton : TextureButton = $Settings
@onready var quitButton : TextureButton = $Quit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	level_change(first_level)

func _on_debug_level_pressed() -> void:
	level_change(debug_level)

func _on_quit_pressed() -> void:
	get_tree().quit()

func level_change(level : PackedScene):
	_level_change_tween = create_tween()
	_level_change_tween.tween_interval(0.5)
	_level_change_tween.tween_callback(_do_change_level.bind(level))
	if overlay:
		overlay.exitLevel()
	
func _do_change_level(level : PackedScene):
	if level:
		get_tree().change_scene_to_packed(level)
	else:
		get_tree().reload_current_scene()
