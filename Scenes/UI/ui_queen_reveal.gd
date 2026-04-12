extends Control
class_name UIQueenReveal

signal reveal_closed

@onready var modal: Control = $modal
@onready var title_label: Label = $modal/TitleLabel
@onready var close_button: Button = $modal/CloseButton
@onready var card_wrappers: Array[Node] = [
	$"modal/Panel/CardContainer/Card1",
	$"modal/Panel/CardContainer/Card2",
	$"modal/Panel/CardContainer/Card3",
	$"modal/Panel/CardContainer/Card4",
]


func _ready() -> void:
	visible = false
	modal.visible = false
	close_button.pressed.connect(_on_close_pressed)


func _on_close_pressed() -> void:
	modal.visible = false
	visible = false
	reveal_closed.emit()


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


func show_for_player(player_name: String, hand: Array) -> void:
	title_label.text = "%s's cards" % player_name
	for i in range(card_wrappers.size()):
		var tex: Texture2D = null
		if i < hand.size():
			var slot = hand[i]
			if slot is Dictionary:
				var card: Dictionary = slot.get("card", {})
				tex = _resolve_texture(card.get("texture", null))
		var cw: Node = card_wrappers[i]
		if cw.has_method("set_face_texture"):
			cw.call("set_face_texture", tex)
		if cw.has_method("play_flip"):
			cw.call("play_flip")
	modal.visible = true
	visible = true


func run_show_and_wait(player_name: String, hand: Array) -> void:
	show_for_player(player_name, hand)
	await reveal_closed
