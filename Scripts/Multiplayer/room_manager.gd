extends RefCounted
class_name RoomManager

const STATUS_WAITING := "waiting"
const STATUS_IN_GAME := "in_game"
const STATUS_FINISHED := "finished"

var rooms: Dictionary = {}


func create_room(host_player: Dictionary, max_players: int = 4) -> Dictionary:
	var room_id := generate_room_code()

	var room := {
		"room_id": room_id,
		"host_player_id": host_player.get("player_id", ""),
		"players": [host_player],
		"max_players": max_players,
		"status": STATUS_WAITING,
		"created_at": Time.get_unix_time_from_system(),
		"game_seed": 0,
		"game_snapshot": {},
		"last_result": {}
	}

	rooms[room_id] = room

	return {
		"ok": true,
		"room": duplicate_room(room)
	}


func join_room(room_id: String, player: Dictionary) -> Dictionary:
	if not rooms.has(room_id):
		return fail("Room not found.")

	var room: Dictionary = rooms[room_id]

	if room["status"] != STATUS_WAITING:
		return fail("Game already started.")

	if room["players"].size() >= room["max_players"]:
		return fail("Room is full.")

	if has_player(room_id, player.get("player_id", "")):
		return fail("Player already in room.")

	room["players"].append(player)
	rooms[room_id] = room

	return {
		"ok": true,
		"room": duplicate_room(room)
	}


func leave_room(room_id: String, player_id: String) -> Dictionary:
	if not rooms.has(room_id):
		return fail("Room not found.")

	var room: Dictionary = rooms[room_id]
	var players: Array = room["players"]

	var remove_index := -1
	for i in range(players.size()):
		if players[i].get("player_id", "") == player_id:
			remove_index = i
			break

	if remove_index == -1:
		return fail("Player not found in room.")

	players.remove_at(remove_index)
	room["players"] = players

	if players.is_empty():
		rooms.erase(room_id)
		return {
			"ok": true,
			"deleted": true,
			"room_id": room_id
		}

	if room["host_player_id"] == player_id:
		room["host_player_id"] = players[0].get("player_id", "")

	rooms[room_id] = room

	return {
		"ok": true,
		"deleted": false,
		"room": duplicate_room(room)
	}


func start_room_game(room_id: String, seed: int, snapshot: Dictionary) -> Dictionary:
	if not rooms.has(room_id):
		return fail("Room not found.")

	var room: Dictionary = rooms[room_id]

	if room["status"] != STATUS_WAITING:
		return fail("Room cannot be started.")

	room["status"] = STATUS_IN_GAME
	room["game_seed"] = seed
	room["game_snapshot"] = snapshot.duplicate(true)
	room["last_result"] = {}

	rooms[room_id] = room

	return {
		"ok": true,
		"room": duplicate_room(room)
	}


func finish_room_game(room_id: String, snapshot: Dictionary, result: Dictionary = {}) -> Dictionary:
	if not rooms.has(room_id):
		return fail("Room not found.")

	var room: Dictionary = rooms[room_id]
	room["status"] = STATUS_FINISHED
	room["game_snapshot"] = snapshot.duplicate(true)
	room["last_result"] = result.duplicate(true)

	rooms[room_id] = room

	return {
		"ok": true,
		"room": duplicate_room(room)
	}


func update_room_snapshot(room_id: String, snapshot: Dictionary, result: Dictionary = {}) -> Dictionary:
	if not rooms.has(room_id):
		return fail("Room not found.")

	var room: Dictionary = rooms[room_id]
	room["game_snapshot"] = snapshot.duplicate(true)
	room["last_result"] = result.duplicate(true)

	rooms[room_id] = room

	return {
		"ok": true,
		"room": duplicate_room(room)
	}


func get_room(room_id: String) -> Dictionary:
	if not rooms.has(room_id):
		return {}
	return duplicate_room(rooms[room_id])


func has_player(room_id: String, player_id: String) -> bool:
	if not rooms.has(room_id):
		return false

	var room: Dictionary = rooms[room_id]
	for player in room["players"]:
		if player.get("player_id", "") == player_id:
			return true

	return false


func is_host(room_id: String, player_id: String) -> bool:
	if not rooms.has(room_id):
		return false

	return rooms[room_id].get("host_player_id", "") == player_id


func generate_room_code(length: int = 6) -> String:
	const CHARS := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var code := ""
	for _i in range(length):
		var index := rng.randi_range(0, CHARS.length() - 1)
		code += CHARS[index]

	if rooms.has(code):
		return generate_room_code(length)

	return code


func duplicate_room(room: Dictionary) -> Dictionary:
	return room.duplicate(true)


func fail(message: String) -> Dictionary:
	return {
		"ok": false,
		"error": message
	}
