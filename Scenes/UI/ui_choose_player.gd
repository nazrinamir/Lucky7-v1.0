extends Control
class_name UIChoosePlayer

signal player_selected(player_index: int)
signal slot_selected(slot_index: int)

const CARD_DESCRIPTION = {
	"J": "Player A, A's slot, then player B and B's slot — swap those two cards",
	"Q": "Choose a player to reveal all four slots",
	"K": "Choose a player, then a slot on their hand to lock",
	"JOKER": "Choose a player to shuffle their hand"
}

@onready var TurnLabel = $"../../TurnCanvas/UITurnPanel/CenterContainer/TurnLabel"

@onready var drawn_card = $"../../CardCanvasLayer/UICard/Panel/DrawnCard"
@onready var power_button = $"../../CardCanvasLayer/UICard/Panel/VBoxContainer/PowerButton"
@onready var discard_button = $"../../CardCanvasLayer/UICard/Panel/VBoxContainer/DiscardButton"
@onready var swap_button = $"../../CardCanvasLayer/UICard/Panel/VBoxContainer/SwapButton"

@onready var modal = $modal
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

@onready var discard_card_display = $"../../CardCanvasLayer/UICard/DiscardCard"

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
	close_group_drawn_card()

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
	

func close_group_drawn_card() -> void:
	if drawn_card:
		drawn_card.visible = false
	if power_button:
		power_button.visible = false
	if discard_button:
		discard_button.visible = false
	if swap_button:
		swap_button.visible = false

func update_d_card(top_card_discard):
	discard_card_display.texture_normal = top_card_discard["card"]["texture"]
