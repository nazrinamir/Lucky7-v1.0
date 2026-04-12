extends Node
class_name PauseManager

const SETTINGS_SCENE := "res://Scenes/setting.tscn"
const HUB_SCENE := "res://Scenes/game_selection.tscn"

@onready var pause_layer: CanvasLayer = $"../PauseCanvasLayer"
@onready var resume_button: Button = $"../PauseCanvasLayer/UI/Panel/CenterContainer/VBoxContainer/ResumeButton"
@onready var setting_button: Button = $"../PauseCanvasLayer/UI/Panel/CenterContainer/VBoxContainer/SettingButton"
@onready var quit_button: Button = $"../PauseCanvasLayer/UI/Panel/CenterContainer/VBoxContainer/QuitButton"
@onready var pause_button: Button = $"../PauseHudLayer/PauseButton"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_layer.visible = false
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS

	resume_button.pressed.connect(_on_resume_pressed)
	setting_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	pause_button.pressed.connect(_on_pause_button_pressed)


func _unhandled_input(event: InputEvent) -> void:
	var want_toggle := event.is_action_pressed("ui_cancel")
	if not want_toggle and event is InputEventKey:
		var k := event as InputEventKey
		want_toggle = k.pressed and not k.echo and (k.keycode == KEY_ESCAPE or k.physical_keycode == KEY_ESCAPE)
	if not want_toggle:
		return
	toggle_pause()
	get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if get_tree().paused:
		resume_game()
	else:
		pause_game()


func pause_game() -> void:
	get_tree().paused = true
	pause_layer.visible = true
	pause_button.visible = false


func resume_game() -> void:
	get_tree().paused = false
	pause_layer.visible = false
	pause_button.visible = true


func _on_resume_pressed() -> void:
	resume_game()


func _on_pause_button_pressed() -> void:
	pause_game()


func _on_settings_pressed() -> void:
	resume_game()
	get_tree().change_scene_to_file(SETTINGS_SCENE)


func _on_quit_pressed() -> void:
	resume_game()
	get_tree().change_scene_to_file(HUB_SCENE)
