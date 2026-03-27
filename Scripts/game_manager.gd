extends Node
class_name GameManager

var player_manager := PlayerManager.new()
var score_manager := ScoreManager.new()
var state_serializer := StateSerializer.new()
var move_validator := MoveValidator.new()
var match_history := MatchHistory.new()
var command_validator := CommandValidator.new()

var turn_number: int = 1
var seed: int = 0

const PHASE_CHOOSE_SOURCE := "choose_source"
const PHASE_ACTION := "action"
const PHASE_POWER_ACTION := "power_action"
const PHASE_GAME_OVER := "game_over"

const POWER_J := "J"
const POWER_Q := "Q"
const POWER_K := "K"
const POWER_JOKER := "JOKER"

var deck_manager := DeckManager.new()

var DEBUG := true

signal game_started
signal game_state_updated
signal turn_changed(current_player_index)
signal command_executed(result)
signal game_ended(winner_data)
signal command_failed(error_message)

# =========================
# GAME STATE
# =========================
var players: Array = []
var current_player_index: int = 0

var discard_pile: Array = []
var current_drawn_card: Dictionary = {}
var turn_phase: String = PHASE_CHOOSE_SOURCE
var discard_available_this_turn: bool = false

# =========================
# POWER CARD STATE
# =========================
var active_power_card: Dictionary = {}
var pending_power_effect: String = ""
var selected_target_player_index: int = -1
var selected_own_hand_index_for_j: int = -1


#func _ready() -> void:
	#print("GameManager ready:", self)
	#start_game()


# =========================
# LOGGING
# =========================
func log_message(parts: Array) -> void:
	if not DEBUG:
		return
	print(" ".join(parts.map(func(p): return str(p))))


func log_state() -> void:
	if DEBUG:
		print_game_state()


# =========================
# GAME SETUP
# =========================
func start_game(player_count: int = 4, seed: int = -1) -> void:
	deck_manager.create_deck()

	if seed == -1:
		seed = Time.get_unix_time_from_system()

	self.seed = seed
	deck_manager.set_seed(self.seed)
	deck_manager.shuffle_deck()

	print("Game seed:", self.seed)

	setup_players(player_count)
	deal_initial_hands()
	reset_runtime_state()

	match_history.clear()
	turn_number = 1
	
	emit_signal("game_started")
	emit_signal("game_state_updated")

	log_state()
	
func record_event(action: String, extra: Dictionary = {}) -> void:
	var event := {
		"turn": turn_number,
		"player_index": current_player_index,
		"player_name": get_current_player().get("name", ""),
		"action": action
	}

	for key in extra.keys():
		event[key] = extra[key]

	match_history.add_event(event)

func setup_players(player_count: int) -> void:
	players = player_manager.setup_players(player_count)
	current_player_index = 0


func deal_initial_hands() -> void:
	player_manager.deal_initial_hands(players, deck_manager, 4)


func reset_runtime_state() -> void:
	discard_pile.clear()
	current_drawn_card = {}
	turn_phase = PHASE_CHOOSE_SOURCE
	discard_available_this_turn = false
	reset_power_state()
	current_player_index = 0


func reset_power_state() -> void:
	active_power_card = {}
	pending_power_effect = ""
	selected_target_player_index = -1
	selected_own_hand_index_for_j = -1


func get_current_player() -> Dictionary:
	if players.is_empty():
		return {}
	return players[current_player_index]


# =========================
# PERSISTENCE
# =========================
func save_game(path: String = "user://save.json") -> void:
	state_serializer.save_to_file(self, path)
	log_message(["Game saved to", path])


func load_game(path: String = "user://save.json") -> void:
	state_serializer.load_from_file(self, path)
	log_message(["Game loaded from", path])
	log_state()
	emit_signal("game_state_updated")


# =========================
# VALIDATION HELPERS
# =========================
func is_valid_player_index(player_index: int) -> bool:
	return player_manager.is_valid_player_index(players, player_index)


func is_valid_hand_index(player_index: int, hand_index: int) -> bool:
	return player_manager.is_valid_hand_index(players, player_index, hand_index)


func push_to_discard(card: Dictionary, can_be_taken: bool) -> void:
	discard_pile.append({
		"card": card,
		"can_be_taken": can_be_taken
	})
	discard_available_this_turn = true


func get_top_discard() -> Dictionary:
	if discard_pile.is_empty():
		return {}
	return discard_pile[-1]


# =========================
# MAIN TURN ACTIONS
# =========================
func draw_from_deck() -> Dictionary:
	if not move_validator.can_draw_card(self):
		var error = "You cannot draw right now."
		log_message([error])
		return {"ok": false, "error": error}

	var card = deck_manager.draw_card()
	if card.is_empty():
		var error = "Draw pile is empty."
		log_message([error])
		return {"ok": false, "error": error}

	current_drawn_card = card
	turn_phase = PHASE_ACTION
	discard_available_this_turn = false

	log_message([
		get_current_player()["name"],
		"drew from deck:",
		deck_manager.format_card(current_drawn_card)
	])
	log_state()

	record_event("draw_from_deck", {
		"card": deck_manager.format_card(current_drawn_card)
	})

	return {
		"ok": true,
		"message": "Drew card"
	}


func take_discard() -> Dictionary:
	if not move_validator.can_take_discard(self):
		var error = "You cannot take discard right now."
		log_message([error])
		return {"ok": false, "error": error}

	current_drawn_card = discard_pile.pop_back()["card"]
	turn_phase = PHASE_ACTION
	discard_available_this_turn = false

	log_message([
		get_current_player()["name"],
		"took discard:",
		deck_manager.format_card(current_drawn_card)
	])
	log_state()
	
	record_event("take_discard", {
		"card": deck_manager.format_card(current_drawn_card)
	})
	
	return {
		"ok": true,
		"message": "Took discard"
	}


func discard_current_card() -> Dictionary:
	if not move_validator.can_discard_current_card(self):
		var error = "You cannot discard right now."
		log_message([error])
		return {"ok": false, "error": error}

	push_to_discard(current_drawn_card, true)

	log_message([
		get_current_player()["name"],
		"discarded:",
		deck_manager.format_card(current_drawn_card)
	])

	record_event("discard_current_card", {
		"card": deck_manager.format_card(current_drawn_card)
	})

	current_drawn_card = {}
	finalize_turn_after_action()

	return {
		"ok": true,
		"message": "Discarded card"
	}
	

func swap_with_hand(hand_index: int) -> Dictionary:
	if not move_validator.can_swap(self, current_player_index, hand_index):
		var error = "You cannot swap right now."
		log_message([error])
		return {"ok": false, "error": error}

	var old_card = player_manager.swap_with_hand(
		players,
		current_player_index,
		hand_index,
		current_drawn_card
	)

	if old_card.is_empty():
		var error = "Invalid swap or card is locked."
		log_message([error])
		return {"ok": false, "error": error}

	push_to_discard(old_card, true)

	log_message([
		get_current_player()["name"],
		"swapped in:",
		deck_manager.format_card(players[current_player_index]["hand"][hand_index]["card"])
	])

	log_message([
		get_current_player()["name"],
		"swapped out:",
		deck_manager.format_card(old_card)
	])

	record_event("swap_with_hand", {
		"slot_index": hand_index,
		"new_card": deck_manager.format_card(players[current_player_index]["hand"][hand_index]["card"]),
		"old_card": deck_manager.format_card(old_card)
	})

	current_drawn_card = {}
	finalize_turn_after_action()

	return {
		"ok": true,
		"message": "Swapped with hand"
	}


func finalize_turn_after_action() -> void:
	check_game_over()
	if turn_phase != PHASE_GAME_OVER:
		next_turn()


# =========================
# POWER CARD FLOW
# =========================
func play_power_card() -> Dictionary:
	if not move_validator.can_play_power_card(self):
		var error = "You cannot play a power card right now."
		log_message([error])
		return {"ok": false, "error": error}

	active_power_card = current_drawn_card
	current_drawn_card = {}
	pending_power_effect = get_power_card_type(active_power_card)

	clear_power_target()
	clear_j_selection()

	log_message([
		get_current_player()["name"],
		"played power card:",
		deck_manager.format_card(active_power_card)
	])

	record_event("play_power_card", {
		"card": deck_manager.format_card(active_power_card),
		"power_type": pending_power_effect
	})

	turn_phase = PHASE_POWER_ACTION
	log_message(["Waiting for power action input for:", pending_power_effect])
	
	return {
		"ok": true,
		"message": "Played power card"
	}


func get_power_card_type(card: Dictionary) -> String:
	if card.is_empty():
		return ""

	if card.get("is_joker", false):
		return POWER_JOKER

	return card["rank"]


func finish_power_card_resolution() -> void:
	push_to_discard(active_power_card, false)

	log_message([
		"Power card moved to discard:",
		deck_manager.format_card(active_power_card)
	])

	reset_power_state()
	finalize_turn_after_action()


func clear_power_target() -> void:
	selected_target_player_index = -1


func clear_j_selection() -> void:
	selected_own_hand_index_for_j = -1


# =========================
# POWER EFFECTS
# =========================
func resolve_j_effect(my_hand_index: int, target_player_index: int, target_hand_index: int) -> bool:
	var success = player_manager.swap_between_players(
		players,
		current_player_index,
		my_hand_index,
		target_player_index,
		target_hand_index
	)

	if success:
		log_message([
			players[current_player_index]["name"],
			"swapped a card with",
			players[target_player_index]["name"]
		])

		record_event("resolve_j_effect", {
			"source_player_index": current_player_index,
			"source_player_name": players[current_player_index]["name"],
			"source_hand_index": my_hand_index,
			"target_player_index": target_player_index,
			"target_player_name": players[target_player_index]["name"],
			"target_hand_index": target_hand_index
		})

	return success


func resolve_q_effect(target_player_index: int) -> bool:
	var success = player_manager.reveal_all_cards_of_player(players, target_player_index)

	if success:
		log_message([
			get_current_player()["name"],
			"viewed cards of",
			players[target_player_index]["name"]
		])

		record_event("resolve_q_effect", {
			"target_player_index": target_player_index,
			"target_player_name": players[target_player_index]["name"]
		})

	return success


func resolve_k_effect(target_player_index: int, target_hand_index: int) -> bool:
	var success = player_manager.lock_card(players, target_player_index, target_hand_index)

	if success:
		log_message([
			get_current_player()["name"],
			"locked a card of",
			players[target_player_index]["name"]
		])

		record_event("resolve_k_effect", {
			"target_player_index": target_player_index,
			"target_player_name": players[target_player_index]["name"],
			"target_hand_index": target_hand_index
		})

	return success


func resolve_joker_effect(target_player_index: int) -> bool:
	var success = player_manager.shuffle_player_hand_positions(players, target_player_index)

	if success:
		log_message([
			get_current_player()["name"],
			"shuffled the hand positions of",
			players[target_player_index]["name"]
		])

		record_event("resolve_joker_effect", {
			"target_player_index": target_player_index,
			"target_player_name": players[target_player_index]["name"]
		})

	return success


# =========================
# POWER INPUT HELPERS
# =========================
func select_j_own_slot(hand_index: int) -> void:
	if pending_power_effect != POWER_J:
		return

	if not is_valid_hand_index(current_player_index, hand_index):
		log_message(["Invalid own hand slot for J."])
		return

	selected_own_hand_index_for_j = hand_index
	log_message(["Selected own slot for J:", hand_index])


func resolve_j_with_target(target_player_index: int, target_hand_index: int) -> void:
	if pending_power_effect != POWER_J:
		return

	if selected_own_hand_index_for_j == -1:
		log_message(["Select your own card first for J."])
		return

	if not resolve_j_effect(selected_own_hand_index_for_j, target_player_index, target_hand_index):
		return

	clear_j_selection()
	finish_power_card_resolution()


func handle_player_input(player_index: int) -> Dictionary:
	if turn_phase != PHASE_POWER_ACTION:
		var error = "Player selection is only used during power actions."
		log_message([error])
		return {"ok": false, "error": error}

	if not is_valid_player_index(player_index):
		var error = "Invalid player selection."
		log_message([error])
		return {"ok": false, "error": error}

	match pending_power_effect:
		POWER_Q:
			if resolve_q_effect(player_index):
				finish_power_card_resolution()
				return {"ok": true, "message": "Player selected"}
			return {"ok": false, "error": "Q effect failed"}

		POWER_JOKER:
			if resolve_joker_effect(player_index):
				finish_power_card_resolution()
				return {"ok": true, "message": "Player selected"}
			return {"ok": false, "error": "Joker effect failed"}

		POWER_J, POWER_K:
			selected_target_player_index = player_index
			log_message(["Selected target player:", players[player_index]["name"]])
			return {"ok": true, "message": "Target player selected"}

		_:
			var error = "This power card does not use player selection."
			log_message([error])
			return {"ok": false, "error": error}


func handle_slot_input(slot_index: int) -> Dictionary:
	if turn_phase == PHASE_POWER_ACTION:
		return handle_power_action_slot(slot_index)
	return swap_with_hand(slot_index)


func handle_power_action_slot(slot_index: int) -> Dictionary:
	match pending_power_effect:
		POWER_J:
			return handle_j_power_slot(slot_index)

		POWER_K:
			if selected_target_player_index == -1:
				var error = "No target player selected for K."
				log_message([error])
				return {"ok": false, "error": error}

			if not is_valid_hand_index(selected_target_player_index, slot_index):
				var error = "Invalid target slot selection."
				log_message([error])
				return {"ok": false, "error": error}

			var success = resolve_k_effect(selected_target_player_index, slot_index)
			if not success:
				var error = "K effect failed."
				log_message([error])
				return {"ok": false, "error": error}

			finish_power_card_resolution()
			return {"ok": true, "message": "K effect resolved"}

		_:
			var error = "This power card does not use slot selection."
			log_message([error])
			return {"ok": false, "error": error}


func handle_j_power_slot(slot_index: int) -> Dictionary:
	if selected_own_hand_index_for_j == -1:
		if not is_valid_hand_index(current_player_index, slot_index):
			var error = "Invalid own slot selection."
			log_message([error])
			return {"ok": false, "error": error}

		selected_own_hand_index_for_j = slot_index
		log_message(["Selected your own slot for J:", slot_index])
		return {"ok": true, "message": "Own J slot selected"}

	if selected_target_player_index == -1:
		var error = "Select a target player for J first."
		log_message([error])
		return {"ok": false, "error": error}

	if not is_valid_hand_index(selected_target_player_index, slot_index):
		var error = "Invalid target slot selection."
		log_message([error])
		return {"ok": false, "error": error}

	if resolve_j_effect(selected_own_hand_index_for_j, selected_target_player_index, slot_index):
		clear_j_selection()
		clear_power_target()
		finish_power_card_resolution()
		return {"ok": true, "message": "J effect resolved"}

	var error = "J effect failed."
	log_message([error])
	return {"ok": false, "error": error}


# =========================
# TURN / GAME FLOW
# =========================
func next_turn() -> void:
	clear_all_reveals()
	current_player_index = (current_player_index + 1) % players.size()
	turn_phase = PHASE_CHOOSE_SOURCE

	log_message(["Next turn:", get_current_player()["name"]])
	log_state()
	
	emit_signal("turn_changed", current_player_index)
	emit_signal("game_state_updated")

	turn_number += 1


func clear_all_reveals() -> void:
	player_manager.clear_all_reveals(players)


func check_game_over() -> void:
	if deck_manager.get_deck_count() == 0 and current_drawn_card.is_empty():
		turn_phase = PHASE_GAME_OVER
		var winner = score_manager.get_winner(players)

		emit_signal("game_ended", winner)
		emit_signal("game_state_updated")

		log_message(["Game Over"])
		print_final_results()



# =========================
# SCORING
# =========================
func print_final_results() -> void:
	score_manager.print_final_results(players)

# =========================
# HISTORY
# =========================
func apply_command(command: Dictionary) -> Dictionary:
	var validation = command_validator.validate(command)

	if not validation["ok"]:
		log_message(["Invalid command:", validation["error"]])
		emit_signal("command_failed", validation["error"])

		record_event("invalid_command", {
			"command": command.duplicate(true),
			"error": validation["error"]
		})

		return {
			"ok": false,
			"error": validation["error"]
		}

	record_event("command_received", {
		"command": command.duplicate(true)
	})

	var command_type = command.get("type", "")
	var result: Dictionary = {}

	match command_type:
		"draw_card":
			result = draw_from_deck()

		"take_discard":
			result = take_discard()

		"discard_card":
			result = discard_current_card()

		"swap_with_hand":
			result = swap_with_hand(command["slot_index"])

		"play_power_card":
			result = play_power_card()

		"select_player":
			result = handle_player_input(command["player_index"])

		"select_slot":
			result = handle_slot_input(command["slot_index"])

		_:
			log_message(["Unknown command:", command_type])
			return {
				"ok": false,
				"error": "Unknown command type"
			}

	if not result.get("ok", false):
		emit_signal("command_failed", result.get("error", "Command failed"))
		return result

	result["type"] = command_type
	emit_signal("command_executed", result)
	emit_signal("game_state_updated")
	return result
	
# =========================
# DEBUG
# =========================
func print_game_state() -> void:
	print("------ GAME STATE ------")
	print("Phase: ", turn_phase)
	print("Deck count: ", deck_manager.get_deck_count())
	print("Current player: ", get_current_player()["name"])

	for player in players:
		print(player["name"], " hand:")
		for i in range(player["hand"].size()):
			var slot = player["hand"][i]
			var lock_text = " [LOCKED]" if slot["is_locked"] else ""
			var reveal_text = " [REVEALED]" if slot["is_revealed"] else ""
			print("  Slot ", i, ": ", deck_manager.format_card(slot["card"]), lock_text, reveal_text)

	if current_drawn_card.is_empty():
		print("Current drawn card: None")
	else:
		print("Current drawn card: ", deck_manager.format_card(current_drawn_card))
 
	if discard_pile.is_empty():
		print("Top discard: None")
	else:
		print("Top discard: ", deck_manager.format_card(discard_pile[-1]["card"]))

	print("------------------------")

func get_game_snapshot() -> Dictionary:
	return state_serializer.export_state(self)
	
func get_player_hand(player_index: int) -> Array:
	if not is_valid_player_index(player_index):
		return []
	return players[player_index]["hand"]
	
func get_player_slot(player_index: int, slot_index: int) -> Dictionary:
	if not is_valid_hand_index(player_index, slot_index):
		return {}
	return players[player_index]["hand"][slot_index]
	
func get_player_slot_card(player_index: int, slot_index: int) -> Dictionary:
	var slot = get_player_slot(player_index, slot_index)
	if slot.is_empty():
		return {}
	return slot["card"]
	
func get_current_player_index() -> int:
	return current_player_index
