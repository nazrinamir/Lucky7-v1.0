extends Control
class_name UIChoosePlayer

signal player_selected(player_index: int)
signal slot_selected(slot_index: int)

const CARD_DESCRIPTION = {
	"J": "Choose two players and two slots to swap cards",
	"Q": "Choose a player to view a card",
	"K": "Choose a player and a slot to lock",
	"JOKER": "Choose a player to shuffle their slots"
}

@onready var TurnLabel = $"../../TurnCanvas/UITurnPanel/CenterContainer/TurnLabel"

@onready var modal = $modal
@onready var drawn_card_modal = $"../../CardCanvasLayer/UICard"
@onready var p1_button = $modal/Panel/CenterContainer/VBoxContainer/ParentHBoxContainer/HBoxContainer/Player1
@onready var p2_button = $modal/Panel/CenterContainer/VBoxContainer/ParentHBoxContainer/HBoxContainer/Player2
@onready var p3_button = $modal/Panel/CenterContainer/VBoxContainer/ParentHBoxContainer/HBoxContainer/Player3
@onready var p4_button = $modal/Panel/CenterContainer/VBoxContainer/ParentHBoxContainer/HBoxContainer/Player4

@onready var s1_button = $modal/Panel/CenterContainer/VBoxContainer/ParentHBoxContainer/HBoxContainer2/Slot1
@onready var s2_button = $modal/Panel/CenterContainer/VBoxContainer/ParentHBoxContainer/HBoxContainer2/Slot2
@onready var s3_button = $modal/Panel/CenterContainer/VBoxContainer/ParentHBoxContainer/HBoxContainer2/Slot3
@onready var s4_button = $modal/Panel/CenterContainer/VBoxContainer/ParentHBoxContainer/HBoxContainer2/Slot4

@onready var buttons = $modal/Panel/CenterContainer/VBoxContainer/ParentHBoxContainer/HBoxContainer
@onready var slots = $modal/Panel/CenterContainer/VBoxContainer/ParentHBoxContainer/HBoxContainer2
@onready var instruct_label = $modal/Panel/CenterContainer/VBoxContainer/Instruction
@onready var power_label = $modal/Panel/CenterContainer/VBoxContainer/PowerCard

func _ready():
	modal.visible = false
	slots.visible = false

	p1_button.pressed.connect(func(): player_selected.emit(0))
	p2_button.pressed.connect(func(): player_selected.emit(1))
	p3_button.pressed.connect(func(): player_selected.emit(2))
	p4_button.pressed.connect(func(): player_selected.emit(3))

	s1_button.pressed.connect(func(): slot_selected.emit(0))
	s2_button.pressed.connect(func(): slot_selected.emit(1))
	s3_button.pressed.connect(func(): slot_selected.emit(2))
	s4_button.pressed.connect(func(): slot_selected.emit(3))

func open_modal():
	if get_parent():
		get_parent().visible = true

	visible = true
	modal.visible = true
	show_player_selection()

func close_modal():
	modal.visible = false
	visible = false

	if get_parent():
		get_parent().visible = false

func close_drawn_card_modal():
	drawn_card_modal.visible = false

func show_player_selection():
	buttons.visible = true
	slots.visible = false

func show_slot_selection():
	buttons.visible = false
	slots.visible = true

func set_instruction(text: String):
	instruct_label.text = text

func set_power_description(rank: String):
	power_label.text = CARD_DESCRIPTION.get(rank, rank)

func set_turn_label(label:int):
	TurnLabel.text = label
	
