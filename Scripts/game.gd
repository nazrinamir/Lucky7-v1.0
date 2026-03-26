extends Node2D

var deck_manager := DeckManager.new()

func _ready() -> void:
	deck_manager.create_deck()
	deck_manager.shuffle_deck()
	print("Deck count: ", deck_manager.get_deck_count())
	print(deck_manager.deck)
