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

var room_manager := RoomManager.new()

# Host-owned local game instance per room
var room_games: Dictionary = {}

# Local identity
var local_player_id: String = ""
var local_player_name: String = ""


func set_local_player(player_id: String, player_name: String) -> void:
	local_player_id = player_id
	local_player_name = player_name


func create_room(max_players: int = 4) -> Dictionary:
	var host_player := make_player_payload(local_player_id, local_player_name)

	var result = room_manager.create_room(host_player, max_players)
	if result["ok"]:
		emit_signal("room_created", result["room"])

	return result


func join_room(room_id: String) -> Dictionary:
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
	if not room_manager.is_host(room_id, local_player_id):
		return fail("Only the host can start the game.")

	var room = room_manager.get_room(room_id)
	if room.is_empty():
		return fail("Room not found.")

	var player_count: int = room["players"].size()
	var seed := int(Time.get_unix_time_from_system())

	var game_manager := GameManager.new()
	game_manager.name = "RoomGame_%s" % room_id
	add_child(game_manager)

	game_manager.start_game(player_count, seed)

	room_games[room_id] = game_manager

	var snapshot = game_manager.get_game_snapshot()
	var room_result = room_manager.start_room_game(room_id, seed, snapshot)

	if room_result["ok"]:
		emit_signal("game_started", room_result["room"])

	return room_result


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
