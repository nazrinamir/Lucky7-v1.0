extends RefCounted
class_name StateSerializer


func export_state(game_manager) -> Dictionary:
	return {
		"players": game_manager.players,
		"current_player_index": game_manager.current_player_index,
		"discard_pile": game_manager.discard_pile,
		"current_drawn_card": game_manager.current_drawn_card,
		"turn_phase": game_manager.turn_phase,
		"discard_available_this_turn": game_manager.discard_available_this_turn,
		"active_power_card": game_manager.active_power_card,
		"pending_power_effect": game_manager.pending_power_effect,
		"selected_target_player_index": game_manager.selected_target_player_index,
		"selected_own_hand_index_for_j": game_manager.selected_own_hand_index_for_j,
		"deck": game_manager.deck_manager.deck
	}

func import_state(game_manager, data: Dictionary) -> void:
	game_manager.players = data.get("players", [])
	game_manager.current_player_index = data.get("current_player_index", 0)
	game_manager.discard_pile = data.get("discard_pile", [])
	game_manager.current_drawn_card = data.get("current_drawn_card", {})
	game_manager.turn_phase = data.get("turn_phase", "choose_source")
	game_manager.discard_available_this_turn = data.get("discard_available_this_turn", false)

	game_manager.active_power_card = data.get("active_power_card", {})
	game_manager.pending_power_effect = data.get("pending_power_effect", "")
	game_manager.selected_target_player_index = data.get("selected_target_player_index", -1)
	game_manager.selected_own_hand_index_for_j = data.get("selected_own_hand_index_for_j", -1)

	game_manager.deck_manager.deck = data.get("deck", [])

func save_to_file(game_manager, path: String = "user://save.json") -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	var data = export_state(game_manager)
	file.store_string(JSON.stringify(data))
	file.close()

func load_from_file(game_manager, path: String = "user://save.json") -> void:
	if not FileAccess.file_exists(path):
		print("Save file not found")
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var data = JSON.parse_string(content)
	if typeof(data) == TYPE_DICTIONARY:
		import_state(game_manager, data)
