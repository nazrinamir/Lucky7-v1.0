extends Control

@onready var singleplayer_button = $HBoxContainer/SinglePlayerButton
@onready var multiplayer_button = $HBoxContainer/MultiplayerButton
@onready var back_button = $BackButton

func _ready() -> void:
	singleplayer_button.pressed.connect(_on_singleplayer_pressed)
	multiplayer_button.pressed.connect(_on_multiplayer_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _on_singleplayer_pressed():
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_multiplayer_pressed():
	get_tree().change_scene_to_file("res://Scenes/multiplayer.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
