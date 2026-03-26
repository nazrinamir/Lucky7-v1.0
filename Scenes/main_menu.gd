extends Control

@onready var start_button = $CenterContainer/VBoxContainer/PlayButton
@onready var settings_button = $CenterContainer/VBoxContainer/SettingButton
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://Scenes/settings.tscn")

func _on_quit_pressed():
	get_tree().quit()
