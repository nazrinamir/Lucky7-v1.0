extends Node2D

@onready var game_manager := GameManager.new()
@onready var input_manager := $InputManager
@onready var slot_manager = $SlotManager


var room_id: String = ""
var game_loaded := false

func _ready() -> void:
	game_manager.name = "GameManager"
	add_child(game_manager)

	input_manager.set_game_ref(game_manager)

	MPManager.command_applied.connect(_on_command_applied)
	MPManager.command_rejected.connect(_on_command_rejected)
	MPManager.game_finished.connect(_on_game_finished)

	if room_id != "":
		var room_data = MPManager.get_room(room_id)

		print("room_id =", room_id)
		print("room_data =", room_data)

		if not room_data.is_empty():
			var seed = int(room_data.get("game_seed", -1))
			var snapshot = room_data.get("game_snapshot", {})

			if MPManager.is_host:
				var player_count = room_data.get("players", []).size()

				print("HOST starting room game with player_count =", player_count)
				game_manager.start_game(player_count, seed)

				var new_snapshot = game_manager.get_game_snapshot()
				MPManager.set_room_snapshot(room_id, new_snapshot)
				print("Host generated and sent initial snapshot")
			else:
				if not snapshot.is_empty():
					var snapshot_player_count = snapshot.get("players", []).size()

					print("CLIENT loading from snapshot player_count =", snapshot_player_count)
					game_manager.start_game(snapshot_player_count, seed)
					game_manager.state_serializer.import_state(game_manager, snapshot)
					print("Imported initial room snapshot")
				else:
					print("Client has no snapshot yet")
		else:
			print("Room data empty, fallback start_game()")
			game_manager.start_game()
	else:
		print("No room_id, fallback start_game()")
		game_manager.start_game()
	input_manager.set_game_ref(game_manager)
	input_manager.set_slot_manager(slot_manager)
	slot_manager.set_game_ref(game_manager)

	game_loaded = true

func _input(event):
	if not game_loaded:
		return

	if room_id != "":
		_handle_multiplayer_input(event)
	else:
		_handle_local_input(event)

func _handle_multiplayer_input(event) -> void:
	if event.is_action_pressed("draw_card"):
		MPManager.send_network_command(room_id, {"type": "draw_card"})
	elif event.is_action_pressed("take_discard"):
		MPManager.send_network_command(room_id, {"type": "take_discard"})
	elif event.is_action_pressed("discard_card"):
		MPManager.send_network_command(room_id, {"type": "discard_card"})
	elif event.is_action_pressed("play_power_card"):
		MPManager.send_network_command(room_id, {"type": "play_power_card"})
	elif event.is_action_pressed("swap_slot_0"):
		MPManager.send_network_command(room_id, {"type": "select_slot", "slot_index": 0})
	elif event.is_action_pressed("swap_slot_1"):
		MPManager.send_network_command(room_id, {"type": "select_slot", "slot_index": 1})
	elif event.is_action_pressed("swap_slot_2"):
		MPManager.send_network_command(room_id, {"type": "select_slot", "slot_index": 2})
	elif event.is_action_pressed("swap_slot_3"):
		MPManager.send_network_command(room_id, {"type": "select_slot", "slot_index": 3})
	elif event.is_action_pressed("select_player_0"):
		MPManager.send_network_command(room_id, {"type": "select_player", "player_index": 0})
	elif event.is_action_pressed("select_player_1"):
		MPManager.send_network_command(room_id, {"type": "select_player", "player_index": 1})
	elif event.is_action_pressed("select_player_2"):
		MPManager.send_network_command(room_id, {"type": "select_player", "player_index": 2})
	elif event.is_action_pressed("select_player_3"):
		MPManager.send_network_command(room_id, {"type": "select_player", "player_index": 3})

func _handle_local_input(event) -> void:
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

func _on_command_applied(applied_room_id: String, result: Dictionary, snapshot: Dictionary) -> void:
	if applied_room_id != room_id:
		return

	game_manager.state_serializer.import_state(game_manager, snapshot)
	_refresh_view()
	print("Updated from room snapshot:", result)

func _on_command_rejected(applied_room_id: String, error_message: String) -> void:
	if applied_room_id != room_id:
		return

	print("Command rejected:", error_message)

func _on_game_finished(room_data: Dictionary) -> void:
	if room_data["room_id"] != room_id:
		return

	print("Game finished.")

func _refresh_view() -> void:
	# update your UI here
	pass
