extends RefCounted
class_name MoveValidator

func can_draw_card(state) -> bool:
	return state.turn_phase == state.PHASE_CHOOSE_SOURCE


func can_take_discard(state) -> bool:
	if state.turn_phase != state.PHASE_CHOOSE_SOURCE:
		return false

	if state.discard_pile.is_empty():
		return false

	if not state.discard_available_this_turn:
		return false

	var top = state.discard_pile[-1]
	return top["can_be_taken"]


func can_discard_current_card(state) -> bool:
	return state.turn_phase == state.PHASE_ACTION and not state.current_drawn_card.is_empty()


func can_swap(state, player_index: int, slot_index: int) -> bool:
	if state.turn_phase != state.PHASE_ACTION:
		return false

	if state.current_drawn_card.is_empty():
		return false

	if player_index < 0 or player_index >= state.players.size():
		return false

	if slot_index < 0 or slot_index >= state.players[player_index]["hand"].size():
		return false

	var slot = state.players[player_index]["hand"][slot_index]
	return not slot["is_locked"]


func can_play_power_card(state) -> bool:
	if state.turn_phase != state.PHASE_ACTION:
		return false

	if state.current_drawn_card.is_empty():
		return false

	return state.deck_manager.is_power_card(state.current_drawn_card)


func is_valid_player(state, player_index: int) -> bool:
	return player_index >= 0 and player_index < state.players.size()


func is_valid_slot(state, player_index: int, slot_index: int) -> bool:
	if not is_valid_player(state, player_index):
		return false

	return slot_index >= 0 and slot_index < state.players[player_index]["hand"].size()
