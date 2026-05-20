class_name UI
extends CanvasLayer
@export var hudOn = true
@export var mouse_mode_action : StringName = "play_char_mouse_mode_action"
@export var main_menu_scene : PackedScene
@onready var animation : AnimationPlayer = $AnimationPlayer
@onready var hud : Control = $InGame
@onready var pause : Container = $PanelContainer
var _level_change_tween: Tween = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !hudOn:
		hud.visible = false
	animation.play("EnterLevel")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed(mouse_mode_action):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			pause.visible = true
			get_tree().paused = true
		else:
			pause.visible = false
			get_tree().paused = false

func exitLevel():
	animation.play("ExitLevel")


func _on_resume_pressed() -> void:
	Input.action_press(mouse_mode_action)
	Input.action_release(mouse_mode_action)


func _on_restart_pressed() -> void:
	level_change()
	
func _do_change_level(level : PackedScene):
	if level:
		get_tree().change_scene_to_packed(level)
	else:
		get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	level_change(main_menu_scene)
	
func level_change(level : PackedScene = null):
	Input.action_press(mouse_mode_action)
	Input.action_release(mouse_mode_action)
	_level_change_tween = create_tween()
	_level_change_tween.tween_interval(0.5)
	_level_change_tween.tween_callback(_do_change_level.bind(level))
	exitLevel()
