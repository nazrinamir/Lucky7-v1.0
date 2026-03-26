extends Node2D

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
	"K": -1
}

var deck: Array = []

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index ==  MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			raycast_check_for_deck()
		else:
			print("Release")
			

func raycast_check_for_deck():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = 1
	var result = space_state.intersect_point(parameters)
	print("Click " + str(result[0].collider))



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_deck()
	deck.shuffle()
	print(deck)


func create_deck():
	deck.clear()
	
#	Normal Cards
	for s in SHAPES:
		for r in RANKS:
			var path = "res://Assets/%s/%s-%s.png" % [s, r, s]
			var card = {
				"id" : r + "_" + s,
				"shape" : s,
				"rank" : r, 
				"value" : CARD_VALUES[r],
				"texture" : load(path)
				}
			deck.append(card)
			
	var card_joker_black = {
			"id" : "Black_Joker",
			"shape" : "Joker",
			"rank" : "Black", 
			"value" : -1,
			"texture" : load("res://Assets/Black-Joker.png")
		}
	var card_joker_red = {
			"id" : "Red_Joker",
			"shape" : "Joker",
			"rank" : "Red", 
			"value" : -1,
			"texture" : load("res://Assets/Red-Joker.png")
		}
	
#	Jokers (2 Blue and 2 Red)
	for i in range (2):
		deck.append(card_joker_black)
		deck.append(card_joker_red)
		



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
