extends Control

@onready var host_button = $HBoxContainer/HostButton
@onready var join_button = $HBoxContainer/JoinButton
@onready var start_button = $StartButton
@onready var back_button = $BackButton

func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	

func _on_copy_pressed():
	pass

func _on_host_pressed():
	pass

func _on_join_pressed():
	pass

func _on_start_pressed():
	pass

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/game_selection.tscn")
