extends Node
class_name CommandRouter

var game_manager: GameManager	
var room_id: String = ""

func setup(gm: GameManager, multiplayer_room_id: String = "") -> void:
	game_manager = gm
	room_id = multiplayer_room_id

func execute(command: Dictionary) -> Dictionary:
	if room_id != "":
		return MPManager.send_network_command(room_id, command)
	return game_manager.apply_command(command)
