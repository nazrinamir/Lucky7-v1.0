extends Node2D

var deck_manager := DeckManager.new()

var player_hand: Array = []
var discard_pile: Array = []
var current_drawn_card: Dictionary = {}
var turn_phase: String = "draw"

func _ready() -> void:
	start_game()

func start_game() -> void:
	deck_manager.create_deck()
	deck_manager.shuffle_deck()
	deal_initial_hand()
	print_game_state()

func deal_initial_hand() -> void:
	player_hand.clear()

	for i in range(4):
		var card = deck_manager.draw_card()
		if not card.is_empty():
			player_hand.append(card)

func draw_from_deck() -> void:
	if turn_phase != "draw":
		print("You cannot draw right now.")
		return

	var card = deck_manager.draw_card()
	if card.is_empty():
		print("Draw pile is empty.")
		return

	current_drawn_card = card
	turn_phase = "action"
	print("Drew from deck: ", deck_manager.format_card(current_drawn_card))
	print_game_state()

func take_discard() -> void:
	if turn_phase != "draw":
		print("You cannot take discard right now.")
		return

	if discard_pile.is_empty():
		print("Discard pile is empty.")
		return

	current_drawn_card = discard_pile.pop_back()
	turn_phase = "action"
	print("Took discard: ", deck_manager.format_card(current_drawn_card))
	print_game_state()

func discard_current_card() -> void:
	if turn_phase != "action":
		print("No card available to discard.")
		return

	if current_drawn_card.is_empty():
		print("Current drawn card is empty.")
		return

	discard_pile.append(current_drawn_card)
	print("Discarded: ", deck_manager.format_card(current_drawn_card))

	current_drawn_card = {}
	turn_phase = "draw"
	print_game_state()

func swap_with_hand(hand_index: int) -> void:
	if turn_phase != "action":
		print("You cannot swap right now.")
		return

	if current_drawn_card.is_empty():
		print("No drawn card to swap.")
		return

	if hand_index < 0 or hand_index >= player_hand.size():
		print("Invalid hand index.")
		return

	var old_card = player_hand[hand_index]
	player_hand[hand_index] = current_drawn_card
	discard_pile.append(old_card)

	print("Swapped in: ", deck_manager.format_card(player_hand[hand_index]))
	print("Swapped out: ", deck_manager.format_card(old_card))

	current_drawn_card = {}
	turn_phase = "draw"
	print_game_state()

func print_game_state() -> void:
	print("------ GAME STATE ------")
	print("Phase: ", turn_phase)
	print("Deck count: ", deck_manager.get_deck_count())

	print("Player hand:")
	for i in range(player_hand.size()):
		print("  Slot ", i, ": ", deck_manager.format_card(player_hand[i]))

	if current_drawn_card.is_empty():
		print("Current drawn card: None")
	else:
		print("Current drawn card: ", deck_manager.format_card(current_drawn_card))

	if discard_pile.is_empty():
		print("Top discard: None")
	else:
		print("Top discard: ", deck_manager.format_card(discard_pile[-1]))

	print("------------------------")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("draw_card"):
		draw_from_deck()

	if event.is_action_pressed("discard_card"):
		discard_current_card()

	if event.is_action_pressed("swap_slot_0"):
		swap_with_hand(0)

	if event.is_action_pressed("swap_slot_1"):
		swap_with_hand(1)

	if event.is_action_pressed("swap_slot_2"):
		swap_with_hand(2)

	if event.is_action_pressed("swap_slot_3"):
		swap_with_hand(3)


func _on_button_pressed() -> void:
	pass # Replace with function body.
