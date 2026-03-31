extends Node2D

@onready var game_manager := GameManager.new()
@onready var input_manager := $InputManager
@onready var slot_manager = $SlotManager

@onready var cp_manager = $ChoosePlayerManager
@onready var ui_choose_player = $CPCanvasLayer/UIChoosePlayer

@onready var ui_turn_panel = $TurnCanvas/UITurnPanel

var room_id: String = ""
var game_loaded := false
var waiting_for_snapshot := false


func _ready() -> void:
	game_manager.name = "GameManager"
	add_child(game_manager)

	MPManager.command_applied.connect(_on_command_applied)
	MPManager.command_rejected.connect(_on_command_rejected)
	MPManager.game_finished.connect(_on_game_finished)

	# 👇 ADD THIS BLOCK
	if OS.has_feature("server"):
		print("Starting dedicated server...")
		var result = MPManager.host_game(7777)
		print(result)

		# create a default room for server
		var room = MPManager.create_room()
		room_id = room.get("room", {}).get("room_id", "")
		print("Server room created:", room_id)

		_setup_multiplayer_game()
	else:
		if room_id != "":
			_setup_multiplayer_game()
		else:
			_setup_local_game()

	game_loaded = true
	set_game_ref_to_child()
	game_manager.turn_changed.connect(ui_turn_panel._on_turn_changed)
	
	
func set_game_ref_to_child():
	input_manager.set_game_ref(game_manager)
	input_manager.set_slot_manager(slot_manager)
	slot_manager.set_game_ref(game_manager)
	ui_turn_panel.set_game_ref(game_manager)

	cp_manager.set_game_ref(game_manager)
	cp_manager.set_ui_ref(ui_choose_player)

	ui_choose_player.player_selected.connect(cp_manager.on_player_selected)
	ui_choose_player.slot_selected.connect(cp_manager.on_slot_selected)

	ui_turn_panel.set_game_ref(game_manager)


func _exit_tree() -> void:
	if room_id != "" and MPManager.is_host:
		MPManager.unregister_host_game(room_id)

	if MPManager.command_applied.is_connected(_on_command_applied):
		MPManager.command_applied.disconnect(_on_command_applied)

	if MPManager.command_rejected.is_connected(_on_command_rejected):
		MPManager.command_rejected.disconnect(_on_command_rejected)

	if MPManager.game_finished.is_connected(_on_game_finished):
		MPManager.game_finished.disconnect(_on_game_finished)


func get_game_manager() -> GameManager:
	return game_manager


func _setup_local_game() -> void:
	print("No room_id, starting local game")
	game_manager.start_game()
	_refresh_view()


func _setup_multiplayer_game() -> void:
	var room_data = MPManager.get_room(room_id)

	print("room_id =", room_id)
	print("room_data =", room_data)

	if room_data.is_empty():
		print("Room data empty, waiting for room sync")
		waiting_for_snapshot = true
		return

	var seed = int(room_data.get("game_seed", -1))
	var snapshot: Dictionary = room_data.get("game_snapshot", {})
	var players: Array = room_data.get("players", [])

	if MPManager.is_host:
		_setup_host_room_game(players, seed)
	else:
		_setup_client_room_game(snapshot, seed)


func _setup_host_room_game(players: Array, seed: int) -> void:
	var player_count := players.size()

	print("HOST starting room game with player_count =", player_count)

	game_manager.start_game(player_count, seed)

	MPManager.register_host_game(room_id, self)

	var new_snapshot = game_manager.get_game_snapshot()
	MPManager.set_room_snapshot(room_id, new_snapshot)

	waiting_for_snapshot = false
	_refresh_view()
	print("Host generated and sent initial snapshot")


func _setup_client_room_game(snapshot: Dictionary, seed: int) -> void:
	if snapshot.is_empty():
		print("Client has no snapshot yet, waiting...")
		waiting_for_snapshot = true
		return

	var snapshot_player_count = snapshot.get("players", []).size()
	print("CLIENT loading from snapshot player_count =", snapshot_player_count)

	game_manager.start_game(snapshot_player_count, seed)
	game_manager.state_serializer.import_state(game_manager, snapshot)

	waiting_for_snapshot = false
	_refresh_view()
	print("Imported initial room snapshot")


func _input(event) -> void:
	if not game_loaded:
		return

	if room_id != "":
		_handle_multiplayer_input(event)
	else:
		_handle_local_input(event)


func _handle_multiplayer_input(event) -> void:
	if waiting_for_snapshot:
		return

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

	_refresh_view()


func _on_command_applied(applied_room_id: String, result: Dictionary, snapshot: Dictionary) -> void:
	if applied_room_id != room_id:
		return

	if snapshot.is_empty():
		return

	var snapshot_player_count = snapshot.get("players", []).size()
	var current_seed = int(snapshot.get("seed", -1))

	if game_manager.players.is_empty() and snapshot_player_count > 0:
		game_manager.start_game(snapshot_player_count, current_seed)

	game_manager.state_serializer.import_state(game_manager, snapshot)

	waiting_for_snapshot = false
	_refresh_view()
	print("Updated from room snapshot:", result)


func _on_command_rejected(applied_room_id: String, error_message: String) -> void:
	if applied_room_id != room_id:
		return

	print("Command rejected:", error_message)


func _on_game_finished(room_data: Dictionary) -> void:
	if room_data.get("room_id", "") != room_id:
		return

	print("Game finished.")


func _refresh_view() -> void:
	# update your UI here
	pass
