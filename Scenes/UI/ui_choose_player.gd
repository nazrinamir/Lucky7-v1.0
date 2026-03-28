extends Control
class_name UIChoosePlayer

signal player_selected(player_index: int)

const POWER_CARD = ["J","Q","K","JOKER",]

@onready var modal = $modal
@onready var p1_button = $modal/Panel/CenterContainer/VBoxContainer/ParentHBoxContainer/HBoxContainer/Player1
@onready var p2_button = $modal/Panel/CenterContainer/VBoxContainer/ParentHBoxContainer/HBoxContainer/Player2
@onready var p3_button = $modal/Panel/CenterContainer/VBoxContainer/ParentHBoxContainer/HBoxContainer/Player3
@onready var p4_button = $modal/Panel/CenterContainer/VBoxContainer/ParentHBoxContainer/HBoxContainer/Player4

@onready var buttons = $modal/Panel/CenterContainer/VBoxContainer/ParentHBoxContainer/HBoxContainer
@onready var slots = $modal/Panel/CenterContainer/VBoxContainer/ParentHBoxContainer/HBoxContainer2
@onready var instruct_label = $modal/Panel/CenterContainer/VBoxContainer/Instruction


func _ready():
	modal.visible = false
	slots.visible = false

	p1_button.pressed.connect(func(): player_selected.emit(0))
	p2_button.pressed.connect(func(): player_selected.emit(1))
	p3_button.pressed.connect(func(): player_selected.emit(2))
	p4_button.pressed.connect(func(): player_selected.emit(3))

func identify_card_flow(rank):
	if rank == "J":
		jack_flow()
	elif rank == "Q":
		queen_flow()
	elif rank == "K":
		king_flow()
	elif rank == "JOKER":
		joker_flow()
	else:
		return

func joker_flow():
	pass

func king_flow():
	pass

func queen_flow():
	pass

func jack_flow():
	pass

func open_modal():
	if get_parent():
		get_parent().visible = true

	visible = true
	modal.visible = true
	instruct_label.text = "Select Player"
	buttons.visible = true
	slots.visible = false

func close_modal():
	modal.visible = false
	visible = false

	if get_parent():
		get_parent().visible = false

func show_slot():
	instruct_label.text = "Select Slot"
	buttons.visible = false
	slots.visible = true
