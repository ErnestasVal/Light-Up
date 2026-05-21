class_name UI
extends CanvasLayer
@export var hudOn = true
@export var mouse_mode_action : StringName = "play_char_mouse_mode_action"
@export var levels : Array[PackedScene]
@onready var animation : AnimationPlayer = $AnimationPlayer
@onready var hud : Control = $InGame
@onready var pause : Container = $PauseMenu
@onready var level_select : Container = $LevelSelect
var _level_change_tween: Tween = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !hudOn:
		hud.visible = false
	animation.play("EnterLevel")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed(mouse_mode_action) and hudOn:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			pause.visible = true
			get_tree().paused = true
		else:
			pause.visible = false
			get_tree().paused = false
	if Input.is_action_just_pressed(mouse_mode_action) and level_select.visible:
		level_select.visible = false

func exitLevel():
	animation.play("ExitLevel")


func _on_resume_pressed() -> void:
	Input.action_press(mouse_mode_action)
	Input.action_release(mouse_mode_action)

func _on_restart_pressed() -> void:
	level_change()
	
func _do_change_level(level : PackedScene, go_to_main_menu: bool):
	if go_to_main_menu:
		get_tree().change_scene_to_file("res://Levels/main_menu.tscn")
	elif level:
		get_tree().change_scene_to_packed(level)
	else:
		get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	level_change(null, true)
	
func level_change(level : PackedScene = null, go_to_main_menu: bool = false):
	Input.action_press(mouse_mode_action)
	Input.action_release(mouse_mode_action)
	_level_change_tween = create_tween()
	_level_change_tween.tween_interval(0.5)
	_level_change_tween.tween_callback(_do_change_level.bind(level, go_to_main_menu))
	exitLevel()

func show_level_select():
	level_select.visible = true

func _on_close_pressed() -> void:
	level_select.visible = false


func _on_level_pressed(extra_arg_0: int) -> void:
	level_change(levels[extra_arg_0])
