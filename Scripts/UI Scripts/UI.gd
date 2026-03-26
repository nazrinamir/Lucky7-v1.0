extends Control

@onready var modal = $Modal
@onready var open_button = $Button

func _ready():
	open_button.pressed.connect(_on_open_button_pressed)

func _on_open_button_pressed():
	open_button.visible = false
	modal.show_modal("Are you sure?")
	modal.confirmed.connect(_on_modal_confirmed, CONNECT_ONE_SHOT)

func _on_modal_confirmed():
	open_button.visible = true
	print("Confirmed!")
