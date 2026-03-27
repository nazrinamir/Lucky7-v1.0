extends Node
class_name SlotManager

const BACK_CARD = preload("res://Assets/Red-Cover.png")

var game_ref = null
var is_swap_mode := false

@onready var hand_slots := [
	$"../PlayerCanvasLayer/UI/CurrentPlayerHand/HBoxContainer/CardSlot",
	$"../PlayerCanvasLayer/UI/CurrentPlayerHand/HBoxContainer/CardSlot2",
	$"../PlayerCanvasLayer/UI/CurrentPlayerHand/HBoxContainer/CardSlot3",
	$"../PlayerCanvasLayer/UI/CurrentPlayerHand/HBoxContainer/CardSlot4"
]

func set_game_ref(value) -> void:
	game_ref = value
	update_hand_ui()

func _ready() -> void:
	for i in range(hand_slots.size()):
		hand_slots[i].pressed.connect(func(): _on_slot_pressed(i))

func begin_swap_mode() -> void:
	is_swap_mode = true
	print("Swap mode ON")

func end_swap_mode() -> void:
	is_swap_mode = false
	print("Swap mode OFF")

func _on_slot_pressed(index: int) -> void:
	if game_ref == null:
		print("game_ref is null")
		return

	print("Slot pressed:", index)

	if is_swap_mode:
		game_ref.handle_slot_input(index)
		end_swap_mode()
		update_hand_ui()

func update_hand_ui() -> void:
	if game_ref == null:
		return

	var player_index = game_ref.current_player_index

	for i in range(hand_slots.size()):
		var slot_data = game_ref.get_player_slot(player_index, i)

		if slot_data.is_empty():
			hand_slots[i].texture_normal = null
			continue

		if slot_data.get("is_revealed", false):
			hand_slots[i].texture_normal = slot_data["card"]["texture"]
		else:
			hand_slots[i].texture_normal = BACK_CARD
