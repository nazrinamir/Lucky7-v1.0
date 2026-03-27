extends Control

@onready var start_button = $CenterContainer/VBoxContainer/PlayButton
@onready var settings_button = $CenterContainer/VBoxContainer/SettingButton
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton
@onready var multiplayer_manager: MultiplayerManager = $MultiplayerManager

var current_room_id: String = ""

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	multiplayer_manager.set_local_player("p1", "Player One")

	multiplayer_manager.room_created.connect(_on_room_created)
	multiplayer_manager.room_joined.connect(_on_room_joined)
	multiplayer_manager.game_started.connect(_on_game_started)
	multiplayer_manager.room_updated.connect(_on_room_updated)

func _on_start_pressed():
	var create_result = multiplayer_manager.create_room(4)
	if not create_result["ok"]:
		print(create_result["error"])
		return

	current_room_id = create_result["room"]["room_id"]

	var start_result = multiplayer_manager.host_start_game(current_room_id)
	if not start_result["ok"]:
		print(start_result["error"])

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://Scenes/settings.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _on_create_room_pressed() -> void:
	var result = multiplayer_manager.create_room(4)
	if not result["ok"]:
		print(result["error"])


func _on_join_room_pressed(room_id: String) -> void:
	var result = multiplayer_manager.join_room(room_id)
	if not result["ok"]:
		print(result["error"])


func _on_start_game_pressed() -> void:
	if current_room_id == "":
		print("No room selected.")
		return

	var result = multiplayer_manager.host_start_game(current_room_id)
	if not result["ok"]:
		print(result["error"])


func _on_room_created(room_data: Dictionary) -> void:
	current_room_id = room_data["room_id"]
	print("Created room:", current_room_id)


func _on_room_joined(room_data: Dictionary) -> void:
	current_room_id = room_data["room_id"]
	print("Joined room:", current_room_id)


func _on_room_updated(room_data: Dictionary) -> void:
	print("Room updated:", room_data)


func _on_game_started(room_data: Dictionary) -> void:
	current_room_id = room_data["room_id"]

	var game_scene = load("res://Scenes/game.tscn").instantiate()
	game_scene.room_id = current_room_id
	game_scene.multiplayer_manager = multiplayer_manager
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(game_scene)
	get_tree().current_scene = game_scene
