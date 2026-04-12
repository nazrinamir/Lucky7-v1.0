extends Node2D
class_name ChoosePlayerManager

var game_ref
var ui_ref
var command_router: CommandRouter = null
var queen_reveal_ui: Node = null
var input_manager_ref: Node = null

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

func set_command_router(value: CommandRouter) -> void:
	command_router = value


func set_queen_reveal_ui(value: Node) -> void:
	queen_reveal_ui = value


func set_input_manager(value: Node) -> void:
	input_manager_ref = value

func _execute(command: Dictionary) -> Dictionary:
	if command_router == null:
		print("command_router is null")
		return {"ok": false, "error": "Command router missing"}
	return command_router.execute(command)

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
			ui_ref.set_instruction("Select player A")
			ui_ref.show_player_selection()

		"Q":
			flow_step = "queen_player"
			ui_ref.set_instruction("Select player to reveal (all slots)")
			ui_ref.show_player_selection()

		"K":
			flow_step = "king_player"
			ui_ref.set_instruction("Select player to lock a card")
			ui_ref.show_player_selection()

		"JOKER":
			flow_step = "joker_player"
			ui_ref.set_instruction("Select player to shuffle their hand")
			ui_ref.show_player_selection()

		_:
			ui_ref.close_modal()
			_close_power_action_panel()

func on_player_selected(player_index: int) -> void:
	print("Player selected:", player_index, "step:", flow_step)

	if game_ref == null:
		print("game_ref is null")
		return

	match flow_step:
		"jack_first_player":
			first_player_index = player_index
			var r_j1 = _execute({"type": "select_player", "player_index": first_player_index})
			if not r_j1.get("ok", false):
				print(r_j1.get("error", "Jack first player failed"))
				return
			flow_step = "jack_first_slot"
			ui_ref.set_instruction("Select a slot for player A")
			ui_ref.show_slot_selection()

		"jack_second_player":
			second_player_index = player_index
			var r_j2 = _execute({"type": "select_player", "player_index": second_player_index})
			if not r_j2.get("ok", false):
				print(r_j2.get("error", "Jack second player failed"))
				return
			flow_step = "jack_second_slot"
			ui_ref.set_instruction("Select a slot for player B")
			ui_ref.show_slot_selection()

		"queen_player":
			var r_q = _execute({"type": "select_player", "player_index": player_index})
			if not r_q.get("ok", false):
				print(r_q.get("error", "Queen selection failed"))
				return
			ui_ref.close_modal()
			_close_power_action_panel()
			var pname: String = str(game_ref.players[player_index].get("name", "Player"))
			var hand_snapshot: Array = game_ref.players[player_index]["hand"].duplicate(true)
			if queen_reveal_ui != null and queen_reveal_ui.has_method("run_show_and_wait"):
				await queen_reveal_ui.run_show_and_wait(pname, hand_snapshot)
			if input_manager_ref != null and input_manager_ref.has_method("refresh_ui"):
				input_manager_ref.refresh_ui()

		"king_player":
			selected_player_index = player_index
			var r_kp = _execute({"type": "select_player", "player_index": player_index})
			if not r_kp.get("ok", false):
				print(r_kp.get("error", "King player selection failed"))
				return
			flow_step = "king_slot"
			ui_ref.set_instruction("Select slot to lock on that player")
			ui_ref.show_slot_selection()

		"joker_player":
			var r_jk = _execute({"type": "select_player", "player_index": player_index})
			if not r_jk.get("ok", false):
				print(r_jk.get("error", "Joker selection failed"))
				return
			ui_ref.close_modal()
			_close_power_action_panel()

func on_slot_selected(slot_index: int):
	print("Slot selected:", slot_index, "step:", flow_step)

	if game_ref == null:
		print("game_ref is null")
		return

	match flow_step:
		"jack_first_slot":
			first_slot_index = slot_index
			var r_s1 = _execute({"type": "select_slot", "slot_index": first_slot_index})
			if not r_s1.get("ok", false):
				print(r_s1.get("error", "Jack first slot failed"))
				return
			flow_step = "jack_second_player"
			ui_ref.set_instruction("Select player B")
			ui_ref.show_player_selection()

		"jack_second_slot":
			second_slot_index = slot_index
			var r_s2 = _execute({"type": "select_slot", "slot_index": second_slot_index})
			if not r_s2.get("ok", false):
				print(r_s2.get("error", "Jack second slot failed"))
				return
			ui_ref.close_modal()
			_close_power_action_panel()

		"king_slot":
			var r_ks = _execute({"type": "select_slot", "slot_index": slot_index})
			if not r_ks.get("ok", false):
				print(r_ks.get("error", "King slot failed"))
				return
			ui_ref.close_modal()
			_close_power_action_panel()

func update_discard_card():
	var top_card = game_ref.get_top_discard()
	ui_ref.update_d_card(top_card)


func _close_power_action_panel() -> void:
	ui_ref.close_drawn_card_modal()
	update_discard_card()
	if input_manager_ref != null and input_manager_ref.has_method("refresh_ui"):
		input_manager_ref.refresh_ui()
