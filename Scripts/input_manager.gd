extends Node
class_name InputManager

const BACK_CARD = preload("res://Assets/Red-Cover.png")

@onready var tween_manager = $"../TweenManager"
@onready var slot_manager = $"../SlotManager"
@onready var choose_player_manager = $"../ChoosePlayerManager"

@onready var deck = $"../Deck/Area2D"
@onready var deck_button = $"../Deck"
@onready var discard_button = $"../CardCanvasLayer/UICard/DiscardButton"
@onready var discard_card_button = $"../CardCanvasLayer/UICard/DiscardCard"
@onready var swap_button = $"../CardCanvasLayer/UICard/SwapButton"
@onready var power_button = $"../CardCanvasLayer/UICard/PowerButton"
@onready var drawn_card_display = $"../CardCanvasLayer/UICard/DrawnCard"
@onready var discard_card_display = $"../CardCanvasLayer/UICard/DiscardCard"
@onready var hand_slots := [
	$"../PlayerCanvasLayer/UI/CurrentPlayerHand/HBoxContainer/CardSlot",
	$"../PlayerCanvasLayer/UI/CurrentPlayerHand/HBoxContainer/CardSlot2",
	$"../PlayerCanvasLayer/UI/CurrentPlayerHand/HBoxContainer/CardSlot3",
	$"../PlayerCanvasLayer/UI/CurrentPlayerHand/HBoxContainer/CardSlot4"
]

@onready var CPCanvas = $"../CPCanvasLayer"

var game_ref: GameManager = null
var command_router: CommandRouter = null
var drawn_card_start_position: Vector2

func set_slot_manager(value):
	slot_manager = value

func set_game_ref(value) -> void:
	game_ref = value

func set_command_router(value: CommandRouter) -> void:
	command_router = value

func _execute(command: Dictionary) -> Dictionary:
	if command_router == null:
		print("command_router is null")
		return {"ok": false, "error": "Command router missing"}

	return command_router.execute(command)

func _ready():
	#print("game_ref =", game_ref)
	drawn_card_start_position = drawn_card_display.position
	discard_button.visible = false
	swap_button.visible = false
	power_button.visible = false
	CPCanvas.visible = false

	if deck:
		deck.deck_clicked.connect(_on_deck_pressed)

	if discard_button:
		discard_button.pressed.connect(_on_discard_pressed)
	
	if swap_button:
		swap_button.pressed.connect(_on_swap_pressed)
		
	
	if power_button:
		power_button.pressed.connect(_on_power_pressed)
	
	if discard_card_button:
		discard_card_button.pressed.connect(_on_take_discard_card_pressed)
	
	for i in range(hand_slots.size()):
		hand_slots[i].pressed.connect(func(): _on_slot_pressed(i))
	
	update_discard_card_ui()
	update_player_hand_ui()
	


func _on_deck_pressed():
	if game_ref == null:
		print("game_ref is null")
		return

	var result = _execute({"type": "draw_card"})
	if not result.get("ok", false):
		print(result.get("error", "Draw failed"))
		return

	drawn_card_display.position = drawn_card_start_position
	tween_manager.slide_card_down(drawn_card_display)
	update_drawn_card_ui()

func _on_discard_pressed():
	if game_ref == null:
		print("game_ref is null")
		return

	var result = _execute({"type": "discard_card"})
	if not result.get("ok", false):
		print(result.get("error", "Discard failed"))
		return

	update_drawn_card_ui()
	update_discard_card_ui()
	get_discard_pile()

func _on_slot_pressed(index: int):
	if game_ref == null:
		print("game_ref is null")
		return
	#print("slot pressed:", index)
	drawn_card_display.texture = null
	discard_button.visible = false
	swap_button.visible = false
	
	#update_discard_card_ui()

func _on_swap_pressed():
	if game_ref == null:
		print("game_ref is null")
		return
	
	slot_manager.begin_swap_mode()

func _on_power_pressed():
	if game_ref == null:
		print("game_ref is null")
		return

	choose_player_manager.open_modal()

	var result = _execute({"type": "play_power_card"})
	if not result.get("ok", false):
		print(result.get("error", "Power failed"))

func _on_take_discard_card_pressed():
	if game_ref == null:
		print("game_ref is null")
		return

	var result = _execute({"type": "take_discard"})
	if not result.get("ok", false):
		print(result.get("error", "Take discard failed"))
		return

	drawn_card_display.position = drawn_card_start_position
	tween_manager.slide_card_down(drawn_card_display)
	refresh_ui()

func update_drawn_card_ui():
	if drawn_card_display == null:
		print("DrawnCard is NULL → wrong path")
		return

	if game_ref == null:
		print("game_ref is null")
		return

	var card = game_ref.current_drawn_card
	if card.is_empty():
		drawn_card_display.texture = null
		discard_button.visible = false
		swap_button.visible = false
		power_button.visible = false
		return

	power_button.visible = int(card.get("value", 0)) == -1
	drawn_card_display.texture = _resolve_texture(card.get("texture", null))
	discard_button.visible = true
	swap_button.visible = true

func update_discard_card_ui():
	if discard_card_display == null:
		print("Discard display is NULL")
		return

	if game_ref == null:
		print("game_ref is null")
		return

	var top_card_discard = game_ref.get_top_discard()

	if top_card_discard.is_empty():
		discard_card_display.texture_normal = null
		return

	var card_data = top_card_discard.get("card", {})
	discard_card_display.texture_normal = _resolve_texture(card_data.get("texture", null))
	#discard_card_display.custom_minimum_size = Vector2(515, 282)
	discard_card_display.ignore_texture_size = true
	discard_card_display.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

func update_player_hand_ui():
	if game_ref == null:
		print("game_ref is null")
		return
		
	var player_index = game_ref.current_player_index
	
	for i in range(hand_slots.size()):
		var slot_data = game_ref.get_player_slot(player_index, i)
		if slot_data.is_empty():
			hand_slots[i].texture_normal = null
			continue
		hand_slots[i].texture_normal = BACK_CARD
		
	print(hand_slots)

func get_discard_pile():
	if game_ref == null:
		print("game_ref is null (discard)")
		return
	
	var top_card_discard = game_ref.get_top_discard()
	if top_card_discard.is_empty():
		print("No discard card")
	else:
		print("Top discard asdasd:", top_card_discard)
	
func _resolve_texture(value) -> Texture2D:
	if value == null:
		return null

	if value is Texture2D:
		return value

	if value is String and value != "":
		var tex = load(value)
		if tex is Texture2D:
			return tex

	return null
	
func refresh_ui():
	update_player_hand_ui()
	update_discard_card_ui()
	update_drawn_card_ui()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
