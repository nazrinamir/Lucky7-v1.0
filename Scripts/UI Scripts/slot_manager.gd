extends Node
class_name SlotManager

const BACK_CARD = preload("res://Assets/Red-Cover.png")

@onready var hand_slots := [
	$"../PlayerCanvasLayer/UI/CurrentPlayerHand/HBoxContainer/CardSlot",
	$"../PlayerCanvasLayer/UI/CurrentPlayerHand/HBoxContainer/CardSlot2",
	$"../PlayerCanvasLayer/UI/CurrentPlayerHand/HBoxContainer/CardSlot3",
	$"../PlayerCanvasLayer/UI/CurrentPlayerHand/HBoxContainer/CardSlot4"
]

var game_ref = null
var is_swap_mode := false

func set_game_ref(value) -> void:
	game_ref = value
	#print("SlotManager game_ref assigned =", game_ref)
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

	#print("slot pressed:", index)

	if not is_swap_mode:
		return

	game_ref.apply_command({"type":"swap_with_hand","slot_index":index})
	end_swap_mode()
	update_hand_ui()

	var input_manager = get_node_or_null("../InputManager")
	if input_manager:
		input_manager.refresh_ui()

func update_hand_ui() -> void:
	if game_ref == null:
		print("game_ref is null")
		return

	var player_index = game_ref.current_player_index

	#print("update_hand_ui called")
	#print("player_index =", player_index)
	#print("Player hand =", game_ref.get_player_hand(player_index))

	for i in range(hand_slots.size()):
		var slot_data = game_ref.get_player_slot(player_index, i)
		#print("slot", i, "=", str(slot_data))
		if slot_data.is_empty():
			hand_slots[i].texture_normal = null
			hand_slots[i].modulate = Color(1, 1, 1, 1)
			continue

		if slot_data.get("is_revealed", false):
			hand_slots[i].texture_normal = load(slot_data["card"]["texture"])
		else:
			hand_slots[i].texture_normal = BACK_CARD

		if slot_data.get("is_locked", false):
			hand_slots[i].modulate = Color(0.7, 0.7, 0.7, 1.0)
		else:
			hand_slots[i].modulate = Color(1, 1, 1, 1)
