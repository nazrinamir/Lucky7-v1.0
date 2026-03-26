extends Control

@onready var label = $ColorRect/CenterContainer/Panel/VBoxContainer/Label
@onready var close_button = $ColorRect/CenterContainer/Panel/VBoxContainer/Button

signal confirmed

func _ready():
	visible = false
	close_button.pressed.connect(_on_close_button_pressed)

func show_modal(message: String):
	label.text = message
	visible = true

func _on_close_button_pressed():
	visible = false
	confirmed.emit()
