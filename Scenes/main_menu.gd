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

func _ready():
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
	get_tree().change_scene_to_file("res://Scenes/game.tscn")


func _on_host_pressed():
	var port := get_port_value()

	var host_result = MPManager.host_game(port)
	if not host_result["ok"]:
		print(host_result["error"])
		return

	print("Hosting on port:", port)

	var create_result = MPManager.create_room(4)
	if not create_result["ok"]:
		print(create_result["error"])
		return

	current_room_id = create_result["room"]["room_id"]
	print("Waiting for players before starting game")


func _on_start_button_pressed():
	if current_room_id == "":
		print("No room to start")
		return

	var result = MPManager.host_start_game(current_room_id)
	if not result["ok"]:
		print(result["error"])


func _on_join_pressed():
	var address := address_input.text.strip_edges()
	if address == "":
		address = "127.0.0.1"

	var port := get_port_value()

	var join_result = MPManager.join_game(address, port)
	if not join_result["ok"]:
		print(join_result["error"])
		return

	print("Joining:", address, "port:", port)


func _on_settings_pressed():
	get_tree().change_scene_to_file("res://Scenes/setting.tscn")


func _on_quit_pressed():
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
