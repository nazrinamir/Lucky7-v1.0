extends Node
class_name GameManager

var player_manager := PlayerManager.new()
var score_manager := ScoreManager.new()

const PHASE_CHOOSE_SOURCE := "choose_source"
const PHASE_ACTION := "action"
const PHASE_POWER_ACTION := "power_action"
const PHASE_GAME_OVER := "game_over"

const POWER_J := "J"
const POWER_Q := "Q"
const POWER_K := "K"
const POWER_JOKER := "JOKER"

var deck_manager := DeckManager.new()

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


func _ready() -> void:
	start_game()


# =========================
# GAME SETUP
# =========================
func start_game(player_count: int = 4) -> void:
	deck_manager.create_deck()
	deck_manager.shuffle_deck()

	setup_players(player_count)
	deal_initial_hands()
	reset_turn_state()

	print_game_state()


func setup_players(player_count: int) -> void:
	players = player_manager.setup_players(player_count)
	current_player_index = 0


func deal_initial_hands() -> void:
	player_manager.deal_initial_hands(players, deck_manager, 4)


func make_hand_slot(card: Dictionary) -> Dictionary:
	return {
		"card": card,
		"is_locked": false,
		"is_revealed": false
	}


func reset_turn_state() -> void:
	discard_pile.clear()
	current_drawn_card = {}
	active_power_card = {}
	pending_power_effect = ""
	selected_target_player_index = -1
	selected_own_hand_index_for_j = -1
	discard_available_this_turn = false
	turn_phase = PHASE_CHOOSE_SOURCE
	current_player_index = 0


func get_current_player() -> Dictionary:
	return players[current_player_index]


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
func draw_from_deck() -> void:
	if turn_phase != PHASE_CHOOSE_SOURCE:
		print("You cannot draw right now.")
		return

	var card = deck_manager.draw_card()
	if card.is_empty():
		print("Draw pile is empty.")
		return

	current_drawn_card = card
	turn_phase = PHASE_ACTION
	discard_available_this_turn = false

	print(get_current_player()["name"], " drew from deck: ", deck_manager.format_card(current_drawn_card))
	print_game_state()


func take_discard() -> void:
	if turn_phase != PHASE_CHOOSE_SOURCE:
		print("You cannot take discard right now.")
		return

	if discard_pile.is_empty() or not discard_available_this_turn:
		print("Discard is not available this turn.")
		return

	var top_discard = get_top_discard()
	if not top_discard["can_be_taken"]:
		print("This discard cannot be taken.")
		return

	current_drawn_card = discard_pile.pop_back()["card"]
	turn_phase = PHASE_ACTION
	discard_available_this_turn = false

	print(get_current_player()["name"], " took discard: ", deck_manager.format_card(current_drawn_card))
	print_game_state()


func discard_current_card() -> void:
	if turn_phase != PHASE_ACTION:
		print("No card available to discard.")
		return

	if current_drawn_card.is_empty():
		print("Current drawn card is empty.")
		return

	push_to_discard(current_drawn_card, true)
	print(get_current_player()["name"], " discarded: ", deck_manager.format_card(current_drawn_card))

	current_drawn_card = {}
	finalize_turn_after_action()


func swap_with_hand(hand_index: int) -> void:
	if turn_phase != PHASE_ACTION:
		print("You cannot swap right now.")
		return

	if current_drawn_card.is_empty():
		print("No drawn card to swap.")
		return

	var old_card = player_manager.swap_with_hand(
		players,
		current_player_index,
		hand_index,
		current_drawn_card
	)

	if old_card.is_empty():
		print("Invalid swap or card is locked.")
		return

	push_to_discard(old_card, true)

	print(get_current_player()["name"], " swapped in: ", deck_manager.format_card(players[current_player_index]["hand"][hand_index]["card"]))
	print(get_current_player()["name"], " swapped out: ", deck_manager.format_card(old_card))

	current_drawn_card = {}
	finalize_turn_after_action()


func finalize_turn_after_action() -> void:
	check_game_over()
	if turn_phase != PHASE_GAME_OVER:
		next_turn()


# =========================
# POWER CARD FLOW
# =========================
func play_power_card() -> void:
	if turn_phase != PHASE_ACTION:
		print("You cannot play a power card right now.")
		return

	if current_drawn_card.is_empty():
		print("There is no drawn card to play.")
		return

	if not deck_manager.is_power_card(current_drawn_card):
		print("Current drawn card is not a power card.")
		return

	active_power_card = current_drawn_card
	current_drawn_card = {}
	pending_power_effect = get_power_card_type(active_power_card)

	clear_power_target()
	clear_j_selection()

	print(get_current_player()["name"], " played power card: ", deck_manager.format_card(active_power_card))

	turn_phase = PHASE_POWER_ACTION
	print("Waiting for power action input for: ", pending_power_effect)


func get_power_card_type(card: Dictionary) -> String:
	if card.is_empty():
		return ""

	if card.get("is_joker", false):
		return POWER_JOKER

	return card["rank"]


func power_card_requires_target_selection(power_type: String) -> bool:
	match power_type:
		POWER_J, POWER_Q, POWER_K, POWER_JOKER:
			return true
		_:
			return false


func finish_power_card_resolution() -> void:
	push_to_discard(active_power_card, false)
	print("Power card moved to discard: ", deck_manager.format_card(active_power_card))

	active_power_card = {}
	pending_power_effect = ""
	clear_power_target()
	clear_j_selection()

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
		print(players[current_player_index]["name"], " swapped a card with ", players[target_player_index]["name"])

	return success


func resolve_q_effect(target_player_index: int) -> bool:
	var success = player_manager.reveal_all_cards_of_player(players, target_player_index)

	if success:
		print(get_current_player()["name"], " viewed cards of ", players[target_player_index]["name"])

	return success


func resolve_k_effect(target_player_index: int, target_hand_index: int) -> bool:
	var success = player_manager.lock_card(players, target_player_index, target_hand_index)

	if success:
		print(get_current_player()["name"], " locked a card of ", players[target_player_index]["name"])

	return success


func resolve_joker_effect(target_player_index: int) -> bool:
	var success = player_manager.shuffle_player_hand_positions(players, target_player_index)

	if success:
		print(get_current_player()["name"], " shuffled the hand positions of ", players[target_player_index]["name"])

	return success


# =========================
# POWER INPUT HELPERS
# =========================
func select_j_own_slot(hand_index: int) -> void:
	if pending_power_effect != POWER_J:
		return

	if not is_valid_hand_index(current_player_index, hand_index):
		print("Invalid own hand slot for J.")
		return

	selected_own_hand_index_for_j = hand_index
	print("Selected own slot for J: ", hand_index)


func resolve_j_with_target(target_player_index: int, target_hand_index: int) -> void:
	if pending_power_effect != POWER_J:
		return

	if selected_own_hand_index_for_j == -1:
		print("Select your own card first for J.")
		return

	var success = resolve_j_effect(selected_own_hand_index_for_j, target_player_index, target_hand_index)
	if not success:
		return

	clear_j_selection()
	finish_power_card_resolution()


func handle_player_input(player_index: int) -> void:
	if turn_phase != PHASE_POWER_ACTION:
		print("Player selection is only used during power actions.")
		return

	if not is_valid_player_index(player_index):
		print("Invalid player selection.")
		return

	match pending_power_effect:
		POWER_Q:
			if resolve_q_effect(player_index):
				finish_power_card_resolution()

		POWER_JOKER:
			if resolve_joker_effect(player_index):
				finish_power_card_resolution()

		POWER_J, POWER_K:
			selected_target_player_index = player_index
			print("Selected target player: ", players[player_index]["name"])

		_:
			print("This power card does not use player selection.")


func handle_slot_input(slot_index: int) -> void:
	if turn_phase == PHASE_POWER_ACTION:
		handle_power_action_slot(slot_index)
	else:
		swap_with_hand(slot_index)


func handle_power_action_slot(slot_index: int) -> void:
	match pending_power_effect:
		POWER_J:
			handle_j_power_slot(slot_index)

		POWER_K:
			if selected_target_player_index == -1:
				print("Select a target player for K first.")
				return

			if resolve_k_effect(selected_target_player_index, slot_index):
				clear_power_target()
				finish_power_card_resolution()

		POWER_Q:
			print("Q needs player selection, not slot selection.")

		POWER_JOKER:
			print("Joker needs player selection, not slot selection.")

		_:
			print("Unknown power action.")


func handle_j_power_slot(slot_index: int) -> void:
	if selected_own_hand_index_for_j == -1:
		selected_own_hand_index_for_j = slot_index
		print("Selected your own slot for J: ", slot_index)
		return

	if selected_target_player_index == -1:
		print("Select a target player for J first.")
		return

	if resolve_j_effect(selected_own_hand_index_for_j, selected_target_player_index, slot_index):
		clear_j_selection()
		clear_power_target()
		finish_power_card_resolution()


# =========================
# TURN / GAME FLOW
# =========================
func next_turn() -> void:
	clear_all_reveals()
	current_player_index = (current_player_index + 1) % players.size()
	turn_phase = PHASE_CHOOSE_SOURCE

	print("Next turn: ", get_current_player()["name"])
	print_game_state()


func clear_all_reveals() -> void:
	player_manager.clear_all_reveals(players)


func check_game_over() -> void:
	if deck_manager.get_deck_count() == 0 and current_drawn_card.is_empty():
		turn_phase = PHASE_GAME_OVER
		print("Game Over")
		print_final_results()


# =========================
# SCORING
# =========================
func print_final_results() -> void:
	score_manager.print_final_results(players)


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
