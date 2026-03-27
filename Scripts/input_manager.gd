extends Node
class_name InputManager

@onready var deck = $"../Deck/Area2D"
@onready var deck_button = $"../Deck"
@onready var discard_button =  $"../CardCanvasLayer/UICard/DiscardButton"
@onready var swap_button = $"../CardCanvasLayer/UICard/SwapButton"
@onready var drawn_card_display = $"../CardCanvasLayer/UICard/DrawnCard"
@onready var discard_card_display = $"../CardCanvasLayer/UICard/DiscardCard"
@onready var hand_slots := [$"../CardSlot", $"../CardSlot2", $"../CardSlot3", $"../CardSlot4"]

var game_ref = null

func set_game_ref(value) -> void:
	game_ref = value
	print("game_ref assigned =", game_ref)
	
func _ready():
	print("game_ref =", game_ref)
	update_discard_card_ui()
	discard_button.visible = false
	swap_button.visible = false

	if deck:
		deck.deck_clicked.connect(_on_deck_pressed)

	if discard_button:
		discard_button.pressed.connect(_on_discard_pressed)
	
	if swap_button:
		swap_button.pressed.connect(_on_swap_pressed)
	
	for i in range(hand_slots.size()):
		hand_slots[i].pressed.connect(func(): _on_slot_pressed(i))

func _on_deck_pressed():
	if game_ref == null:
		print("game_ref is null")
		return
	game_ref.draw_from_deck()
	update_drawn_card_ui()

func _on_discard_pressed():
	if game_ref == null:
		print("game_ref is null")
		return
	game_ref.discard_current_card()
	update_drawn_card_ui()
	update_discard_card_ui()
	get_discard_pile()

func _on_slot_pressed(index: int):
	if game_ref == null:
		print("game_ref is null")
		return
	print("slot pressed:", index)
	

func _on_swap_pressed():
	print("Swap button pressed")

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
		return

	drawn_card_display.texture = card["texture"]
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
		discard_card_display.texture = null
		return

	discard_card_display.texture_normal = top_card_discard["card"]["texture"]

func get_discard_pile():
	if game_ref == null:
		print("game_ref is null (discard)")
		return
	
	var top_card_discard = game_ref.get_top_discard()
	if top_card_discard.is_empty():
		print("No discard card")
	else:
		print("Top discard asdasd:", top_card_discard)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
