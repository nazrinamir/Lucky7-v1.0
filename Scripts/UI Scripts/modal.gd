extends Control

@onready var label = $ColorRect/CenterContainer/Panel/VBoxContainer/Label
@onready var button = $ColorRect/CenterContainer/Panel/VBoxContainer/Button
@onready var animation_player = $AnimationPlayer
@onready var color_rect = $ColorRect
@onready var panel = $ColorRect/CenterContainer/Panel

signal confirmed

func _ready():
	visible = false
	button.pressed.connect(_on_close_button_pressed)

func show_modal(message: String):
	label.text = message
	visible = true
	animation_player.play("open")

func _on_close_button_pressed():
	animation_player.play("close")
	await animation_player.animation_finished
	visible = false
	confirmed.emit()
