extends Control
class_name UIChoosePlayer

signal player_selected(player_index: int)

@onready var modal = $modal
@onready var p1_button = $modal/Panel/CenterContainer/HBoxContainer/Player1
@onready var p2_button = $modal/Panel/CenterContainer/HBoxContainer/Player2
@onready var p3_button = $modal/Panel/CenterContainer/HBoxContainer/Player3
@onready var p4_button = $modal/Panel/CenterContainer/HBoxContainer/Player4

func _ready():
	modal.visible = false

	p1_button.pressed.connect(func(): player_selected.emit(0))
	p2_button.pressed.connect(func(): player_selected.emit(1))
	p3_button.pressed.connect(func(): player_selected.emit(2))
	p4_button.pressed.connect(func(): player_selected.emit(3))

func open_modal():
	if get_parent():
		get_parent().visible = true

	visible = true
	modal.visible = true

func close_modal():
	modal.visible = false
	visible = false

	if get_parent():
		get_parent().visible = false
