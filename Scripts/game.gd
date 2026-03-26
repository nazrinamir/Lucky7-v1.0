extends Node2D

var deck_manager := DeckManager.new()

var players: Array = []
var current_player_index: int = 0

var discard_pile: Array = []
var current_drawn_card: Dictionary = {}
var turn_phase: String = "choose_source"

var discard_available_this_turn: bool = false

var active_power_card: Dictionary = {}
var pending_power_effect: String = ""

var selected_target_player_index: int = -1

var selected_own_hand_index_for_j: int = -1

func _ready() -> void:
	start_game()

func start_game() -> void:
	deck_manager.create_deck()
	deck_manager.shuffle_deck()

	setup_players(4) # change to 3 or 4 when needed
	deal_initial_hands()

	discard_pile.clear()
	current_drawn_card = {}
	turn_phase = "choose_source"
	current_player_index = 0

	print_game_state()

func setup_players(player_count: int) -> void:
	players.clear()

	if player_count < 2:
		player_count = 2
	elif player_count > 4:
		player_count = 4

	for i in range(player_count):
		var player = {
			"id": i,
			"name": "Player %d" % (i + 1),
			"hand": [],
			"is_disqualified": false
		}
		players.append(player)

	current_player_index = 0

func get_current_player() -> Dictionary:
	return players[current_player_index]
	
func deal_initial_hands() -> void:
	for player in players:
		player["hand"].clear()

	for i in range(4):
		for player in players:
			var card = deck_manager.draw_card()
			if not card.is_empty():
				player["hand"].append({
					"card": card,
					"is_locked": false,
					"is_revealed": false
				})

func draw_from_deck() -> void:
	if turn_phase != "choose_source":
		print("You cannot draw right now.")
		return

	var card = deck_manager.draw_card()
	if card.is_empty():
		print("Draw pile is empty.")
		return

	current_drawn_card = card
	turn_phase = "action"
	discard_available_this_turn = false

	print(get_current_player()["name"], " drew from deck: ", deck_manager.format_card(current_drawn_card))
	print_game_state()

func take_discard() -> void:
	if turn_phase != "choose_source":
		print("You cannot take discard right now.")
		return

	if discard_pile.is_empty() or not discard_available_this_turn:
		print("Discard is not available this turn.")
		return

	var top_discard = discard_pile[-1]
	if not top_discard["can_be_taken"]:
		print("This discard cannot be taken.")
		return
		
	current_drawn_card = discard_pile.pop_back()["card"]
	turn_phase = "action"
	discard_available_this_turn = false

	print(get_current_player()["name"], " took discard: ", deck_manager.format_card(current_drawn_card))
	print_game_state()

func play_power_card() -> void:
	if turn_phase != "action":
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

	print(get_current_player()["name"], " played power card: ", deck_manager.format_card(active_power_card))

	turn_phase = "power_action"
	print("Waiting for power action input for: ", pending_power_effect)

func get_power_card_type(card: Dictionary) -> String:
	if card.is_empty():
		return ""

	if card.get("is_joker", false):
		return "JOKER"

	return card["rank"]
	
func power_card_requires_target_selection(power_type: String) -> bool:
	match power_type:
		"J":
			return true
		"Q":
			return true
		"K":
			return true
		"JOKER":
			return true
		_:
			return false

func resolve_j_effect(my_hand_index: int, target_player_index: int, target_hand_index: int) -> bool:
	var current_player = players[current_player_index]

	if target_player_index < 0 or target_player_index >= players.size():
		print("Invalid target player.")
		return false

	var target_player = players[target_player_index]

	if target_player_index == current_player_index:
		print("J must target another player.")
		return false

	if my_hand_index < 0 or my_hand_index >= current_player["hand"].size():
		print("Invalid own hand index.")
		return false

	if target_hand_index < 0 or target_hand_index >= target_player["hand"].size():
		print("Invalid target hand index.")
		return false

	if current_player["hand"][my_hand_index]["is_locked"]:
		print("Your selected card is locked.")
		return false

	if target_player["hand"][target_hand_index]["is_locked"]:
		print("Target card is locked.")
		return false

	var my_card = current_player["hand"][my_hand_index]["card"]
	var target_card = target_player["hand"][target_hand_index]["card"]

	current_player["hand"][my_hand_index]["card"] = target_card
	target_player["hand"][target_hand_index]["card"] = my_card

	print(current_player["name"], " swapped a card with ", target_player["name"])
	return true
	
func clear_j_selection() -> void:
	selected_own_hand_index_for_j = -1

func select_j_own_slot(hand_index: int) -> void:
	if pending_power_effect != "J":
		return

	if hand_index < 0 or hand_index >= players[current_player_index]["hand"].size():
		print("Invalid own hand slot for J.")
		return

	selected_own_hand_index_for_j = hand_index
	print("Selected own slot for J: ", hand_index)

func resolve_j_with_target(target_player_index: int, target_hand_index: int) -> void:
	if pending_power_effect != "J":
		return

	if selected_own_hand_index_for_j == -1:
		print("Select your own card first for J.")
		return

	var success = resolve_j_effect(selected_own_hand_index_for_j, target_player_index, target_hand_index)
	if not success:
		return

	clear_j_selection()
	finish_power_card_resolution()
	
func resolve_q_effect(target_player_index: int) -> bool:
	if target_player_index < 0 or target_player_index >= players.size():
		print("Invalid target player for Q.")
		return false

	var target_player = players[target_player_index]

	for slot in target_player["hand"]:
		slot["is_revealed"] = true

	print(get_current_player()["name"], " viewed cards of ", target_player["name"])
	return true
	
func clear_all_reveals() -> void:
	for player in players:
		for slot in player["hand"]:
			slot["is_revealed"] = false
			
func resolve_k_effect(target_player_index: int, target_hand_index: int) -> bool:
	if target_player_index < 0 or target_player_index >= players.size():
		print("Invalid target player for K.")
		return false

	var target_player = players[target_player_index]

	if target_hand_index < 0 or target_hand_index >= target_player["hand"].size():
		print("Invalid target hand index for K.")
		return false

	target_player["hand"][target_hand_index]["is_locked"] = true
	print(get_current_player()["name"], " locked a card of ", target_player["name"])
	return true

func resolve_joker_effect(target_player_index: int) -> bool:
	if target_player_index < 0 or target_player_index >= players.size():
		print("Invalid target player for Joker.")
		return false

	var target_player = players[target_player_index]
	target_player["hand"].shuffle()

	print(get_current_player()["name"], " shuffled the hand positions of ", target_player["name"])
	return true
	
func finish_power_card_resolution() -> void:
	discard_pile.append({
		"card": active_power_card,
		"can_be_taken": false
	})
	discard_available_this_turn = true

	print("Power card moved to discard: ", deck_manager.format_card(active_power_card))

	active_power_card = {}
	pending_power_effect = ""

	check_game_over()
	if turn_phase != "game_over":
		next_turn()

func discard_current_card() -> void:
	if turn_phase != "action":
		print("No card available to discard.")
		return

	if current_drawn_card.is_empty():
		print("Current drawn card is empty.")
		return

	discard_pile.append({
		"card": current_drawn_card,
		"can_be_taken": true
	})
	discard_available_this_turn = true
	print(get_current_player()["name"], " discarded: ", deck_manager.format_card(current_drawn_card))

	current_drawn_card = {}
	check_game_over()
	if turn_phase != "game_over":
		next_turn()

func swap_with_hand(hand_index: int) -> void:
	if turn_phase != "action":
		print("You cannot swap right now.")
		return

	if current_drawn_card.is_empty():
		print("No drawn card to swap.")
		return

	var player = players[current_player_index]
	var hand = player["hand"]

	if hand_index < 0 or hand_index >= hand.size():
		print("Invalid hand index.")
		return

	if hand[hand_index]["is_locked"]:
		print("That card is locked and cannot be swapped out.")
		return

	var old_card = hand[hand_index]["card"]
	hand[hand_index]["card"] = current_drawn_card

	discard_pile.append({
		"card": old_card,
		"can_be_taken": true
	})
	discard_available_this_turn = true

	print(player["name"], " swapped in: ", deck_manager.format_card(hand[hand_index]["card"]))
	print(player["name"], " swapped out: ", deck_manager.format_card(old_card))

	current_drawn_card = {}
	check_game_over()
	if turn_phase != "game_over":
		next_turn()
		
func clear_power_target() -> void:
	selected_target_player_index = -1

func next_turn() -> void:
	clear_all_reveals()
	current_player_index = (current_player_index + 1) % players.size()
	turn_phase = "choose_source"
	print("Next turn: ", get_current_player()["name"])
	print_game_state()
	
func check_game_over() -> void:
	if deck_manager.get_deck_count() == 0 and current_drawn_card.is_empty():
		turn_phase = "game_over"
		print("Game Over")
		print_final_results()

func is_hand_disqualified(hand: Array) -> bool:
	for slot in hand:
		var card = slot["card"]
		if card.get("is_joker", false):
			return true
		if card["rank"] in ["J", "Q", "K"]:
			return true
	return false

func calculate_hand_score(hand: Array) -> int:
	var total := 0
	for slot in hand:
		total += slot["card"]["value"]
	return total

func print_final_results() -> void:
	var best_score = 999999
	var winner_name = ""

	print("------ FINAL RESULTS ------")

	for player in players:
		var hand = player["hand"]

		if is_hand_disqualified(hand):
			print(player["name"], ": DISQUALIFIED")
			continue

		var score = calculate_hand_score(hand)
		print(player["name"], ": ", score)

		if score < best_score:
			best_score = score
			winner_name = player["name"]

	if winner_name != "":
		print("Winner: ", winner_name, " with score ", best_score)
	else:
		print("No winner. All players disqualified.")
		
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

func _input(event: InputEvent) -> void:
	if turn_phase == "game_over":
		return

	if event.is_action_pressed("draw_card"):
		draw_from_deck()

	if event.is_action_pressed("take_discard"):
		take_discard()

	if event.is_action_pressed("discard_card"):
		discard_current_card()

	if event.is_action_pressed("play_power_card"):
		play_power_card()

	if event.is_action_pressed("swap_slot_0"):
		handle_slot_input(0)

	if event.is_action_pressed("swap_slot_1"):
		handle_slot_input(1)

	if event.is_action_pressed("swap_slot_2"):
		handle_slot_input(2)

	if event.is_action_pressed("swap_slot_3"):
		handle_slot_input(3)

	if event.is_action_pressed("select_player_0"):
		handle_player_input(0)

	if event.is_action_pressed("select_player_1"):
		handle_player_input(1)

	if event.is_action_pressed("select_player_2"):
		handle_player_input(2)

	if event.is_action_pressed("select_player_3"):
		handle_player_input(3)

func handle_player_input(player_index: int) -> void:
	if turn_phase != "power_action":
		print("Player selection is only used during power actions.")
		return

	match pending_power_effect:
		"Q":
			var success = resolve_q_effect(player_index)
			if success:
				finish_power_card_resolution()

		"JOKER":
			var success = resolve_joker_effect(player_index)
			if success:
				finish_power_card_resolution()

		"J":
			selected_target_player_index = player_index
			print("Selected target player for J: ", players[player_index]["name"])

		"K":
			selected_target_player_index = player_index
			print("Selected target player for K: ", players[player_index]["name"])

		_:
			print("This power card does not use player selection.")
			
func handle_slot_input(slot_index: int) -> void:
	if turn_phase == "power_action":
		handle_power_action_slot(slot_index)
	else:
		swap_with_hand(slot_index)

func handle_power_action_slot(slot_index: int) -> void:
	match pending_power_effect:
		"J":
			handle_j_power_slot(slot_index)

		"K":
			if selected_target_player_index == -1:
				print("Select a target player for K first.")
				return

			var success = resolve_k_effect(selected_target_player_index, slot_index)
			if not success:
				return

			selected_target_player_index = -1
			finish_power_card_resolution()

		"Q":
			print("Q needs player selection, not slot selection.")

		"JOKER":
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

	var success = resolve_j_effect(selected_own_hand_index_for_j, selected_target_player_index, slot_index)
	if not success:
		return

	selected_own_hand_index_for_j = -1
	selected_target_player_index = -1
	finish_power_card_resolution()


#func _on_deck_pressed() -> void:
	#pass # Replace with function body.
