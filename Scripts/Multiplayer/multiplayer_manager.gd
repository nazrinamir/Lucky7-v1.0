extends Node
class_name MultiplayerManager

signal room_created(room_data)
signal room_joined(room_data)
signal room_updated(room_data)
signal room_left(room_data)
signal room_deleted(room_id)
signal game_started(room_data)
signal command_applied(room_id, result, snapshot)
signal command_rejected(room_id, error_message)
signal game_finished(room_data)
signal peer_connected(peer_id)
signal peer_disconnected(peer_id)
signal connected_to_server
signal connection_failed
signal server_disconnected

var peer := ENetMultiplayerPeer.new()
var is_host: bool = false
var room_manager := RoomManager.new()
var active_room_id: String = ""

# Host-owned local game instance per room
var room_games: Dictionary = {}

# Local identity
var local_player_id: String = ""
var local_player_name: String = ""


func set_local_player(player_id: String, player_name: String) -> void:
	local_player_id = player_id
	local_player_name = player_name

func host_game(port: int = 7777, max_clients: int = 4) -> Dictionary:
	var err = peer.create_server(port, max_clients)
	if err != OK:
		return fail("Failed to host game on port %d" % port)

	multiplayer.multiplayer_peer = peer
	is_host = true
	_bind_network_signals()

	return {
		"ok": true,
		"message": "Hosting on port %d" % port
	}

func join_game(ip: String, port: int = 7777) -> Dictionary:
	var err = peer.create_client(ip, port)
	if err != OK:
		return fail("Failed to join %s:%d" % [ip, port])

	multiplayer.multiplayer_peer = peer
	is_host = false
	_bind_network_signals()

	return {
		"ok": true,
		"message": "Joining %s:%d" % [ip, port]
	}
	
func create_room(max_players: int = 4) -> Dictionary:
	var host_player := make_player_payload(local_player_id, local_player_name)

	var result = room_manager.create_room(host_player, max_players)
	if result["ok"]:
		emit_signal("room_created", result["room"])

	return result


func join_room(room_id: String) -> Dictionary:
	if not is_host:
		return fail("Clients must request room join through the host.")
		
	var player := make_player_payload(local_player_id, local_player_name)

	var result = room_manager.join_room(room_id, player)
	if result["ok"]:
		emit_signal("room_joined", result["room"])

	return result


func leave_room(room_id: String) -> Dictionary:
	var result = room_manager.leave_room(room_id, local_player_id)

	if not result["ok"]:
		return result

	if result.get("deleted", false):
		emit_signal("room_deleted", result["room_id"])
	else:
		emit_signal("room_left", result["room"])

	return result


func host_start_game(room_id: String) -> Dictionary:
	active_room_id = room_id

	if not room_manager.is_host(room_id, local_player_id):
		return fail("Only the host can start the game.")

	var room = room_manager.get_room(room_id)
	if room.is_empty():
		return fail("Room not found.")

	var player_count: int = room["players"].size()
	var seed := int(Time.get_unix_time_from_system())

	room["game_seed"] = seed
	room["status"] = "starting"
	room_manager.rooms[room_id] = room

	emit_signal("game_started", room)
	rpc("rpc_sync_room_state", room_id, room)
	rpc("rpc_open_game_scene", room_id)
	
	return {
		"ok": true,
		"room": room
	}

func host_apply_command(room_id: String, player_id: String, command: Dictionary) -> Dictionary:
	if not room_manager.is_host(room_id, local_player_id):
		return fail("Only the host can apply commands authoritatively.")

	if not room_manager.has_player(room_id, player_id):
		return fail("Player is not in this room.")

	if not room_games.has(room_id):
		return fail("No active game found for room.")

	var room = room_manager.get_room(room_id)
	if room.is_empty():
		return fail("Room not found.")

	var current_player_index = get_current_turn_player_index(room_id)
	var room_players: Array = room["players"]

	if current_player_index < 0 or current_player_index >= room_players.size():
		return fail("Invalid current turn player index.")

	var expected_player_id = room_players[current_player_index].get("player_id", "")
	if player_id != expected_player_id:
		return fail("It is not this player's turn.")

	var game_manager: GameManager = room_games[room_id]
	var result = game_manager.apply_command(command)

	if not result.get("ok", false):
		emit_signal("command_rejected", room_id, result.get("error", "Command failed."))
		return result

	var snapshot = game_manager.get_game_snapshot()
	room_manager.update_room_snapshot(room_id, snapshot, result)

	emit_signal("command_applied", room_id, result, snapshot)
	emit_signal("room_updated", room_manager.get_room(room_id))

	if game_manager.turn_phase == game_manager.PHASE_GAME_OVER:
		var finished = room_manager.finish_room_game(room_id, snapshot, result)
		if finished["ok"]:
			emit_signal("game_finished", finished["room"])

	return result

func send_command(room_id: String, command: Dictionary) -> Dictionary:
	return host_apply_command(room_id, local_player_id, command)

func receive_remote_snapshot(room_id: String, snapshot: Dictionary, room_data: Dictionary = {}) -> void:
	# For non-host clients later:
	# use this when host/server sends latest room snapshot.
	if room_data.is_empty():
		room_data = room_manager.get_room(room_id)

	if not room_data.is_empty():
		room_manager.update_room_snapshot(room_id, snapshot)

	emit_signal("room_updated", room_manager.get_room(room_id))


func get_room(room_id: String) -> Dictionary:
	return room_manager.get_room(room_id)


func get_room_players(room_id: String) -> Array:
	var room = room_manager.get_room(room_id)
	if room.is_empty():
		return []
	return room.get("players", []).duplicate(true)


func get_room_snapshot(room_id: String) -> Dictionary:
	var room = room_manager.get_room(room_id)
	if room.is_empty():
		return {}
	return room.get("game_snapshot", {}).duplicate(true)


func get_current_turn_player_index(room_id: String) -> int:
	if not room_games.has(room_id):
		var snapshot = get_room_snapshot(room_id)
		if snapshot.is_empty():
			return -1
		return int(snapshot.get("current_player_index", -1))

	var game_manager: GameManager = room_games[room_id]
	return game_manager.get_current_player_index()


func get_current_turn_player(room_id: String) -> Dictionary:
	var room = room_manager.get_room(room_id)
	if room.is_empty():
		return {}

	var index = get_current_turn_player_index(room_id)
	var players: Array = room["players"]

	if index < 0 or index >= players.size():
		return {}

	return players[index].duplicate(true)


func destroy_room_game(room_id: String) -> void:
	if not room_games.has(room_id):
		return

	var game_manager: GameManager = room_games[room_id]
	if is_instance_valid(game_manager):
		game_manager.queue_free()

	room_games.erase(room_id)


func make_player_payload(player_id: String, player_name: String) -> Dictionary:
	return {
		"player_id": player_id,
		"player_name": player_name
	}


func fail(message: String) -> Dictionary:
	return {
		"ok": false,
		"error": message
	}

func _on_peer_connected(id: int) -> void:
	print("Peer connected:", id)
	emit_signal("peer_connected", id)

func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected:", id)
	emit_signal("peer_disconnected", id)

func _on_connected_to_server() -> void:
	print("Connected to server")
	emit_signal("connected_to_server")

	if not is_host:
		rpc_id(1, "rpc_request_join_room", local_player_id, local_player_name)

func _on_connection_failed() -> void:
	print("Connection failed")
	emit_signal("connection_failed")

func _on_server_disconnected() -> void:
	print("Server disconnected")
	emit_signal("server_disconnected")
	
func _bind_network_signals() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)

	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)

	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)

	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)
		
@rpc("any_peer")
func rpc_send_command(room_id: String, player_id: String, command: Dictionary) -> void:
	if not is_host:
		return

	var result = host_apply_command(room_id, player_id, command)

	if result.get("ok", false):
		var snapshot = get_room_snapshot(room_id)
		rpc("rpc_receive_snapshot", room_id, snapshot, result)
	else:
		rpc_id(multiplayer.get_remote_sender_id(), "rpc_receive_command_rejection", room_id, result.get("error", "Command failed."))

@rpc("authority")
func rpc_receive_command_rejection(room_id: String, error_message: String) -> void:
	emit_signal("command_rejected", room_id, error_message)
	
@rpc("authority", "call_local")
func rpc_receive_snapshot(room_id: String, snapshot: Dictionary, result: Dictionary) -> void:
	var room = room_manager.get_room(room_id)

	if not room.is_empty():
		room_manager.update_room_snapshot(room_id, snapshot, result)

	emit_signal("command_applied", room_id, result, snapshot)
	emit_signal("room_updated", room_manager.get_room(room_id))
	
@rpc("authority")
func rpc_receive_room_info(room_id: String, room_data: Dictionary) -> void:
	active_room_id = room_id
	room_manager.rooms[room_id] = room_data.duplicate(true)
	emit_signal("room_joined", room_data)

@rpc("authority")
func rpc_open_game_scene(room_id: String) -> void:
	active_room_id = room_id
	emit_signal("game_started", room_manager.get_room(room_id))

@rpc("any_peer")
func rpc_request_join_room(player_id: String, player_name: String) -> void:
	if not is_host:
		return

	if active_room_id == "":
		return

	var result = room_manager.join_room(active_room_id, {
		"player_id": player_id,
		"player_name": player_name
	})

	var sender_id = multiplayer.get_remote_sender_id()

	if result["ok"]:
		var room_data = result["room"]

		# send full room data to the joining client
		rpc_id(sender_id, "rpc_receive_room_info", active_room_id, room_data)

		# optionally send updated room data to everyone already in lobby
		rpc("rpc_sync_room_state", active_room_id, room_data)

		emit_signal("room_updated", room_data)

@rpc("authority", "call_local")
func rpc_sync_room_state(room_id: String, room_data: Dictionary) -> void:
	active_room_id = room_id
	room_manager.rooms[room_id] = room_data.duplicate(true)
	emit_signal("room_updated", room_data)
	
func send_network_command(room_id: String, command: Dictionary) -> Dictionary:
	if is_host:
		return send_command(room_id, command)

	rpc_id(1, "rpc_send_command", room_id, local_player_id, command)

	return {
		"ok": true,
		"message": "Command sent to host"
	}

func set_room_snapshot(room_id: String, snapshot: Dictionary) -> void:
	var room = room_manager.get_room(room_id)
	if room.is_empty():
		return

	room["game_snapshot"] = snapshot
	room_manager.rooms[room_id] = room
	rpc("rpc_sync_room_state", room_id, room)
