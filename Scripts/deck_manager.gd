#extends Node2D
extends RefCounted
class_name DeckManager

const SHAPES := ["Clubs", "Diamonds", "Hearts", "Spades"]
const RANKS := ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

const CARD_VALUES := {
	"A": 1,
	"2": 2,
	"3": 3,
	"4": 4,
	"5": 5,
	"6": 6,
	"7": 0,   # Lucky 7 
	"8": 8,
	"9": 9,
	"10": 10,
	"J": -1,
	"Q": -1,
	"K": -1,
	"JOKER": -1
}

var deck: Array = []

# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#create_deck()
	#deck.shuffle()
	#print(deck)


#func create_deck():
	#deck.clear()
	#
##	Normal Cards
	#for s in SHAPES:
		#for r in RANKS:
			#var path = "res://Assets/%s/%s-%s.png" % [s, r, s]
			#var card = {
				#"id" : r + "_" + s,
				#"shape" : s,
				#"rank" : r, 
				#"value" : CARD_VALUES[r],
				#"texture" : load(path)
				#}
			#deck.append(card)
			#
	#var card_joker_black = {
			#"id" : "Black_Joker",
			#"shape" : "Joker",
			#"rank" : "Black", 
			#"value" : -1,
			#"texture" : load("res://Assets/Black-Joker.png")
		#}
	#var card_joker_red = {
			#"id" : "Red_Joker",
			#"shape" : "Joker",
			#"rank" : "Red", 
			#"value" : -1,
			#"texture" : load("res://Assets/Red-Joker.png")
		#}
	#
##	Jokers (2 Blue and 2 Red)
	#for i in range (2):
		#deck.append(card_joker_black)
		#deck.append(card_joker_red)

func create_deck() -> Array:
	deck.clear()

	for suit in SHAPES:
		for rank in RANKS:
			var path = "res://Assets/%s/%s-%s.png" % [suit, rank, suit]
			var card = {
				"id": "%s_%s" % [rank, suit],
				"shape": suit,
				"rank": rank,
				"value": CARD_VALUES[rank],
				"is_joker": false,
				"texture": load(path)
			}
			deck.append(card)

	for i in range(2):
		deck.append({
			"id": "Black_Joker_%d" % i,
			"shape": "Joker",
			"rank": "JOKER",
			"value": CARD_VALUES["JOKER"],
			"is_joker": true,
			"texture": load("res://Assets/Black-Joker.png")
		})
		deck.append({
			"id": "Red_Joker_%d" % i,
			"shape": "Joker",
			"rank": "JOKER",
			"value": CARD_VALUES["JOKER"],
			"is_joker": true,
			"texture": load("res://Assets/Red-Joker.png")
		})

	return deck
	
func shuffle_deck() -> void:
	deck.shuffle()

func draw_card() -> Dictionary:
	if deck.is_empty():
		return {}
	return deck.pop_back()
	
func get_deck_count() -> int:
	return deck.size()
	
func is_power_card(card: Dictionary) -> bool:
	if card.is_empty():
		return false
	return card.get("is_joker", false) or card["rank"] in ["J", "Q", "K"]	
	
func format_card(card: Dictionary) -> String:
	if card.is_empty():
		return "No card"
	if card.get("is_joker", false):
		return card["id"]
	return "%s of %s" % [card["rank"], card["shape"]]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
