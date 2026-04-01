extends Control

@onready var play_button = $CenterContainer/VBoxContainer/PlayButton
@onready var host_button = $CenterContainer/VBoxContainer/HostButton
@onready var join_button = $CenterContainer/VBoxContainer/JoinButton
@onready var start_button = $CenterContainer/VBoxContainer/StartButton
@onready var settings_button = $CenterContainer/VBoxContainer/SettingButton
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton
@onready var address_input: LineEdit = $CenterContainer/VBoxContainer/AddressInput
@onready var port_input: LineEdit = $CenterContainer/VBoxContainer/PortInput

var current_room_id: String = ""
var lobby_manager: LobbyManager
var heartbeat_timer: Timer

func _ready():
	printerr("MAIN_MENU _ready reached")

	lobby_manager = LobbyManager.new()
	add_child(lobby_manager)

	heartbeat_timer = Timer.new()
	heartbeat_timer.wait_time = 10.0
	heartbeat_timer.one_shot = false
	heartbeat_timer.timeout.connect(_on_heartbeat_timeout)
	add_child(heartbeat_timer)

	play_button.pressed.connect(_on_play_pressed)
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	start_button.pressed.connect(_on_start_button_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	var unique_id = str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000)
	MPManager.set_local_player(unique_id, "Player " + unique_id)

	MPManager.room_created.connect(_on_room_created)
	MPManager.room_joined.connect(_on_room_joined)
	MPManager.game_started.connect(_on_game_started)
	MPManager.room_updated.connect(_on_room_updated)

	MPManager.connected_to_server.connect(_on_connected_to_server)
	MPManager.connection_failed.connect(_on_connection_failed)
	MPManager.peer_connected.connect(_on_peer_connected)
	MPManager.peer_disconnected.connect(_on_peer_disconnected)


func _on_play_pressed():
	get_tree().change_scene_to_file("res://Scenes/game_selection.tscn")


func _on_host_pressed():
	var port := get_port_value()

	var host_result = MPManager.host_game(port)
	if not host_result["ok"]:
		printerr(host_result["error"])
		return

	var room_result = MPManager.create_room(4)
	if not room_result["ok"]:
		printerr(room_result["error"])
		return

	current_room_id = room_result["room"]["room_id"]

	var register_result = await lobby_manager.register_room({
		"room_id": current_room_id,
		"host_player_id": MPManager.local_player_id,
		"host_player_name": MPManager.local_player_name,
		"host_port": port,
		"max_players": 4,
		"player_count": 1,
		"status": "waiting"
	})

	if not register_result["ok"]:
		printerr(register_result["error"])
		return

	address_input.text = current_room_id
	heartbeat_timer.start()
	printerr("Room registered in lobby:", current_room_id)

func _on_start_button_pressed():
	if current_room_id == "":
		printerr("No room to start")
		return

	var result = MPManager.host_start_game(current_room_id)
	printerr("start_result = ", result)

	if not result["ok"]:
		printerr(result["error"])


func _on_join_pressed():
	var room_id := address_input.text.strip_edges()
	if room_id == "":
		printerr("Room ID is empty")
		return

	var lookup_result = await lobby_manager.get_room(room_id)
	if not lookup_result["ok"]:
		printerr(lookup_result["error"])
		return

	var room_data = lookup_result["data"]
	var host_ip = room_data.get("host_ip", "")
	# TEMP TEST
	host_ip = "192.168.1.129"
	var host_port = int(room_data.get("host_port", 7777))

	if host_ip == "":
		printerr("Room has no host IP")
		return

	var join_result = MPManager.join_game(host_ip, host_port)
	if not join_result["ok"]:
		printerr(join_result["error"])
		return

	print("Joining via lobby:", host_ip, "port:", host_port)


func _on_heartbeat_timeout():
	if current_room_id == "":
		return

	await lobby_manager.send_heartbeat(current_room_id, {
		"status": "waiting"
	})


func _on_settings_pressed():
	get_tree().change_scene_to_file("res://Scenes/setting.tscn")


func _on_quit_pressed():
	if current_room_id != "":
		await lobby_manager.remove_room(current_room_id)

	get_tree().quit()


func _on_room_created(room_data: Dictionary) -> void:
	current_room_id = room_data["room_id"]
	print("Created room:", current_room_id)


func _on_room_joined(room_data: Dictionary) -> void:
	current_room_id = room_data["room_id"]
	print("Joined room:", current_room_id)


func _on_room_updated(room_data: Dictionary) -> void:
	pass


func _on_game_started(room_data: Dictionary) -> void:
	current_room_id = room_data["room_id"]
	print("Opening game scene for room:", current_room_id)

	var game_scene = load("res://Scenes/game.tscn").instantiate()
	game_scene.room_id = current_room_id

	get_tree().current_scene.queue_free()
	get_tree().root.add_child(game_scene)
	get_tree().current_scene = game_scene


func _on_connected_to_server() -> void:
	print("Connected to host/server")


func _on_connection_failed() -> void:
	print("Connection failed")


func _on_peer_connected(peer_id: int) -> void:
	print("Peer connected:", peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer disconnected:", peer_id)


func get_port_value() -> int:
	var raw = port_input.text.strip_edges()
	if raw == "":
		return 7777

	if raw.is_valid_int():
		return int(raw)

	return 7777
