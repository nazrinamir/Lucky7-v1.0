extends Node2D

@onready var game_manager := GameManager.new()
@onready var input_manager := $InputManager
@onready var slot_manager = $SlotManager


var room_id: String = ""
var multiplayer_manager: MultiplayerManager

func _ready() -> void:
	game_manager.name = "GameManager"
	add_child(game_manager)
	
	if multiplayer_manager != null and room_id != "":
		var room_data = multiplayer_manager.get_room(room_id)

		if not room_data.is_empty():
			var player_count = room_data.get("players", []).size()
			var seed = int(room_data.get("game_seed", -1))
			game_manager.start_game(player_count, seed)
		else:
			game_manager.start_game()
	else:
		game_manager.start_game()
	input_manager.set_game_ref(game_manager)
	input_manager.set_slot_manager(slot_manager)
	slot_manager.set_game_ref(game_manager)

func _input(event):
	if event.is_action_pressed("draw_card"):
		game_manager.draw_from_deck()

	elif event.is_action_pressed("take_discard"):
		game_manager.take_discard()

	elif event.is_action_pressed("discard_card"):
		game_manager.discard_current_card()

	elif event.is_action_pressed("play_power_card"):
		game_manager.play_power_card()

	elif event.is_action_pressed("swap_slot_0"):
		game_manager.handle_slot_input(0)

	elif event.is_action_pressed("swap_slot_1"):
		game_manager.handle_slot_input(1)

	elif event.is_action_pressed("swap_slot_2"):
		game_manager.handle_slot_input(2)

	elif event.is_action_pressed("swap_slot_3"):
		game_manager.handle_slot_input(3)

	elif event.is_action_pressed("select_player_0"):
		game_manager.handle_player_input(0)

	elif event.is_action_pressed("select_player_1"):
		game_manager.handle_player_input(1)

	elif event.is_action_pressed("select_player_2"):
		game_manager.handle_player_input(2)

	elif event.is_action_pressed("select_player_3"):
		game_manager.handle_player_input(3)
