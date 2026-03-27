extends RefCounted
class_name CommandValidator

const TYPE_DRAW_CARD := "draw_card"
const TYPE_TAKE_DISCARD := "take_discard"
const TYPE_DISCARD_CARD := "discard_card"
const TYPE_SWAP_WITH_HAND := "swap_with_hand"
const TYPE_PLAY_POWER_CARD := "play_power_card"
const TYPE_SELECT_PLAYER := "select_player"
const TYPE_SELECT_SLOT := "select_slot"

const VALID_TYPES := [
	TYPE_DRAW_CARD,
	TYPE_TAKE_DISCARD,
	TYPE_DISCARD_CARD,
	TYPE_SWAP_WITH_HAND,
	TYPE_PLAY_POWER_CARD,
	TYPE_SELECT_PLAYER,
	TYPE_SELECT_SLOT
]


func validate(command: Dictionary) -> Dictionary:
	if command.is_empty():
		return invalid("Command cannot be empty.")

	if not command.has("type"):
		return invalid("Missing command type.")

	var command_type = command.get("type")

	if typeof(command_type) != TYPE_STRING:
		return invalid("Command type must be a string.")

	if command_type not in VALID_TYPES:
		return invalid("Unknown command type: %s" % str(command_type))

	match command_type:
		TYPE_DRAW_CARD, TYPE_TAKE_DISCARD, TYPE_DISCARD_CARD, TYPE_PLAY_POWER_CARD:
			return ok()

		TYPE_SWAP_WITH_HAND, TYPE_SELECT_SLOT:
			return validate_slot_index(command)

		TYPE_SELECT_PLAYER:
			return validate_player_index(command)

	return invalid("Unhandled command type: %s" % str(command_type))


func validate_slot_index(command: Dictionary) -> Dictionary:
	if not command.has("slot_index"):
		return invalid("Missing slot_index.")

	var slot_index = command.get("slot_index")

	if typeof(slot_index) != TYPE_INT:
		return invalid("slot_index must be an integer.")

	if slot_index < 0:
		return invalid("slot_index cannot be negative.")

	return ok()


func validate_player_index(command: Dictionary) -> Dictionary:
	if not command.has("player_index"):
		return invalid("Missing player_index.")

	var player_index = command.get("player_index")

	if typeof(player_index) != TYPE_INT:
		return invalid("player_index must be an integer.")

	if player_index < 0:
		return invalid("player_index cannot be negative.")

	return ok()


func ok() -> Dictionary:
	return {
		"ok": true,
		"error": ""
	}


func invalid(message: String) -> Dictionary:
	return {
		"ok": false,
		"error": message
	}
