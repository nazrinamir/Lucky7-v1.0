extends Node2D
class_name ChoosePlayerManager

var game_ref
var ui_ref

var current_power_rank = ""
var selected_player_index = -1

var flow_step = ""
var first_player_index = -1
var first_slot_index = -1
var second_player_index = -1
var second_slot_index = -1

func set_game_ref(value):
	game_ref = value

func set_ui_ref(value):
	ui_ref = value

func reset_flow():
	flow_step = ""
	selected_player_index = -1
	first_player_index = -1
	first_slot_index = -1
	second_player_index = -1
	second_slot_index = -1

func open_modal():
	print("ChoosePlayerManager.open_modal called")

	if game_ref == null:
		print("game_ref is null")
		return

	if ui_ref == null:
		print("ui_ref is null")
		return

	reset_flow()
	current_power_rank = game_ref.current_drawn_card["rank"]

	ui_ref.set_power_description(current_power_rank)
	ui_ref.open_modal()

	match current_power_rank:
		"J":
			flow_step = "jack_first_player"
			ui_ref.set_instruction("Select First Player")
			ui_ref.show_player_selection()

		"Q":
			flow_step = "queen_player"
			ui_ref.set_instruction("Select Player")
			ui_ref.show_player_selection()

		"K":
			flow_step = "king_player"
			ui_ref.set_instruction("Select Player")
			ui_ref.show_player_selection()

		"JOKER":
			flow_step = "joker_player"
			ui_ref.set_instruction("Select Player To Shuffle")
			ui_ref.show_player_selection()

		_:
			ui_ref.close_modal()
			ui_ref.close_drawn_card_modal()

func on_player_selected(player_index: int):
	print("Player selected:", player_index, "step:", flow_step)

	if game_ref == null:
		print("game_ref is null")
		return

	match flow_step:
		"jack_first_player":
			first_player_index = player_index
			if first_player_index:
				game_ref.apply_command({
				"type": "select_player",
				"player_index": first_player_index
				})
			flow_step = "jack_first_slot"
			ui_ref.set_instruction("Select First Slot")
			ui_ref.show_slot_selection()

		"jack_second_player":
			second_player_index = player_index
			if second_player_index:
				game_ref.apply_command({
					"type": "select_player",
					"player_index": second_player_index
				})
			flow_step = "jack_second_slot"
			ui_ref.set_instruction("Select Second Slot")
			ui_ref.show_slot_selection()

		"queen_player":
			game_ref.apply_command({
				"type": "select_player",
				"player_index": player_index
			})
			ui_ref.close_modal()
			ui_ref.close_drawn_card_modal()

		"king_player":
			selected_player_index = player_index
			game_ref.apply_command({
				"type": "select_player",
				"player_index": player_index
			})
			flow_step = "king_slot"
			ui_ref.set_instruction("Select Slot To Lock")
			ui_ref.show_slot_selection()

		"joker_player":
			game_ref.apply_command({
				"type": "select_player",
				"player_index": player_index
			})
			ui_ref.close_modal()
			ui_ref.close_drawn_card_modal()

func on_slot_selected(slot_index: int):
	print("Slot selected:", slot_index, "step:", flow_step)

	if game_ref == null:
		print("game_ref is null")
		return

	match flow_step:
		"jack_first_slot":
			first_slot_index = slot_index
			game_ref.apply_command({
				"type": "select_slot",
				"slot_index": first_slot_index
			})
			flow_step = "jack_second_player"
			ui_ref.set_instruction("Select Second Player")
			ui_ref.show_player_selection()

		"jack_second_slot":
			second_slot_index = slot_index
			game_ref.apply_command({
				"type": "select_slot",
				"slot_index": second_slot_index
			})
			ui_ref.close_modal()
			ui_ref.close_drawn_card_modal()

		"king_slot":
			game_ref.apply_command({
				"type": "select_slot",
				"slot_index": slot_index
			})
			ui_ref.close_modal()
			ui_ref.close_drawn_card_modal()
