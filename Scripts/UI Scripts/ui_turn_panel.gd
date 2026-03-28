extends Control
class_name UITurnPanel

var game_ref

@onready var turn_label = $CenterContainer/TurnLabel

func set_game_ref(value):
	game_ref = value
	update_turn_ui()

func update_turn_ui():
	if game_ref == null:
		print("TurnPanel game_ref is null")
		return

	turn_label.text = str(game_ref.get_current_player_index() + 1)

func _on_turn_changed(current_player_index: int):
	turn_label.text = str(current_player_index + 1)
