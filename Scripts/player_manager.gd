extends RefCounted
class_name PlayerManager


func setup_players(player_count: int) -> Array:
	var players: Array = []
	player_count = clamp(player_count, 2, 4)

	for i in range(player_count):
		players.append({
			"id": i,
			"name": "Player %d" % (i + 1),
			"hand": [],
			"is_disqualified": false
		})

	return players


func make_hand_slot(card: Dictionary) -> Dictionary:
	return {
		"card": card,
		"is_locked": false,
		"is_revealed": false
	}


func deal_initial_hands(players: Array, deck_manager, cards_per_player: int = 4) -> void:
	for player in players:
		player["hand"].clear()

	for _i in range(cards_per_player):
		for player in players:
			var card = deck_manager.draw_card()
			if not card.is_empty():
				player["hand"].append(make_hand_slot(card))


func is_valid_player_index(players: Array, player_index: int) -> bool:
	return player_index >= 0 and player_index < players.size()


func is_valid_hand_index(players: Array, player_index: int, hand_index: int) -> bool:
	if not is_valid_player_index(players, player_index):
		return false

	var hand: Array = players[player_index]["hand"]
	return hand_index >= 0 and hand_index < hand.size()


func swap_with_hand(players: Array, player_index: int, hand_index: int, new_card: Dictionary) -> Dictionary:
	if not is_valid_hand_index(players, player_index, hand_index):
		return {}

	var hand = players[player_index]["hand"]

	if hand[hand_index]["is_locked"]:
		return {}

	var old_card = hand[hand_index]["card"]
	hand[hand_index]["card"] = new_card

	return old_card


func clear_all_reveals(players: Array) -> void:
	for player in players:
		for slot in player["hand"]:
			slot["is_revealed"] = false


func reveal_all_cards_of_player(players: Array, player_index: int) -> bool:
	if not is_valid_player_index(players, player_index):
		return false

	for slot in players[player_index]["hand"]:
		slot["is_revealed"] = true

	return true


func lock_card(players: Array, player_index: int, hand_index: int) -> bool:
	if not is_valid_hand_index(players, player_index, hand_index):
		return false

	players[player_index]["hand"][hand_index]["is_locked"] = true
	return true


func shuffle_player_hand_positions(players: Array, player_index: int) -> bool:
	if not is_valid_player_index(players, player_index):
		return false

	players[player_index]["hand"].shuffle()
	return true


func swap_between_players(
	players: Array,
	source_player_index: int,
	source_hand_index: int,
	target_player_index: int,
	target_hand_index: int
) -> bool:
	if not is_valid_hand_index(players, source_player_index, source_hand_index):
		return false

	if not is_valid_hand_index(players, target_player_index, target_hand_index):
		return false

	if source_player_index == target_player_index:
		return false

	var source_slot = players[source_player_index]["hand"][source_hand_index]
	var target_slot = players[target_player_index]["hand"][target_hand_index]

	if source_slot["is_locked"] or target_slot["is_locked"]:
		return false

	var temp_card = source_slot["card"]
	source_slot["card"] = target_slot["card"]
	target_slot["card"] = temp_card

	return true
