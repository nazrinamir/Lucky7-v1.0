extends Node

@onready var game_ref = $"../"

@onready var deck = $"../Deck/Area2D"
@onready var deck_button = $"../Deck"
@onready var discard_button = get_node_or_null("../DiscardButton")
@onready var drawn_card_display = $"../CardCanvasLayer/UICard/DrawnCard"

@onready var hand_slots :=[$"../CardSlot", $"../CardSlot2", $"../CardSlot3", $"../CardSlot4"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Parent:", get_parent().name)
	print("Children of Game:", get_parent().get_children())
	print("Trying path:", $"../CardCanvasLayer/UICard/DrawnCard")
	deck.deck_clicked.connect(_on_deck_pressed)
	
	if discard_button:
		for i in range(hand_slots.size()):
			hand_slots[i].pressed.connect (func():_on_slot_pressed(i))

func _on_deck_pressed():
	print("InputManager received deck click")
	game_ref.draw_from_deck()
	update_drawn_card_ui()

func _on_discard_pressed():
	print("Discard pressed")
	game_ref.draw_from_discard()

func _on_slot_pressed(index: int):
	game_ref.draw_from_deck()
	

func update_drawn_card_ui():
	if drawn_card_display == null:
		print("DrawnCard is NULL → wrong path")
		return

	var card = game_ref.current_drawn_card
	
	if card.is_empty():
		drawn_card_display.texture = null
		return

	drawn_card_display.texture = card["texture"]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
