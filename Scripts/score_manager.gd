extends RefCounted
class_name ScoreManager


func is_hand_disqualified(hand: Array) -> bool:
	for slot in hand:
		var card = slot["card"]

		if card.get("is_joker", false):
			return true

		if card.get("rank", "") in ["J", "Q", "K"]:
			return true

	return false


func calculate_hand_score(hand: Array) -> int:
	var total := 0

	for slot in hand:
		total += int(slot["card"].get("value", 0))

	return total


func get_player_result(player: Dictionary) -> Dictionary:
	var hand = player["hand"]

	if is_hand_disqualified(hand):
		return {
			"name": player["name"],
			"is_disqualified": true,
			"score": -1
		}

	return {
		"name": player["name"],
		"is_disqualified": false,
		"score": calculate_hand_score(hand)
	}


func get_all_results(players: Array) -> Array:
	var results: Array = []

	for player in players:
		results.append(get_player_result(player))

	return results


func get_winner(players: Array) -> Dictionary:
	var best_score := 999999
	var winner: Dictionary = {}

	for player in players:
		var result = get_player_result(player)

		if result["is_disqualified"]:
			continue

		if result["score"] < best_score:
			best_score = result["score"]
			winner = result

	return winner


func print_final_results(players: Array) -> void:
	var winner = get_winner(players)

	print("------ FINAL RESULTS ------")

	for player in players:
		var result = get_player_result(player)

		if result["is_disqualified"]:
			print(result["name"], ": DISQUALIFIED")
		else:
			print(result["name"], ": ", result["score"])

	if winner.is_empty():
		print("No winner. All players disqualified.")
	else:
		print("Winner: ", winner["name"], " with score ", winner["score"])
