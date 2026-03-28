extends Node2D
class_name ChoosePlayerManager



var game_ref
var ui_ref

func set_game_ref(value):
	game_ref = value

func set_ui_ref(value):
	ui_ref = value

func open_modal():
	print("ChoosePlayerManager.open_modal called")
	print("ui_ref =", ui_ref)

	if ui_ref == null:
		print("ui_ref is null")
		return

	if ui_ref.get_parent():
		ui_ref.get_parent().visible = true
		
	#ui_ref.identify_card_flow(game_ref.current_drawn_card.rank)
	
	ui_ref.open_modal()

func on_player_selected(player_index: int):
	print("Player selected:", player_index)

	if game_ref == null:
		print("game_ref is null")
		return

	game_ref.apply_command({
		"type": "select_player",
		"player_index": player_index
	})
	
