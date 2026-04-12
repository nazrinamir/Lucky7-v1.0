extends Node2D
class_name DeckVisualFx

const CARD_BACK := preload("res://Assets/Red-Cover.png")

@export var slide_seconds: float = 0.75
@export var slide_distance: float = 780.0

@onready var _card: Sprite2D = $FxCard
@onready var _deck_sprite: Sprite2D = $"../../Deck/DeckImage"

var _tween: Tween
var _last_play_msec: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _card:
		_card.texture = CARD_BACK
		_card.visible = false
		_card.z_index = 100
	if _deck_sprite == null:
		push_warning("DeckVisualFx: Deck/DeckImage not found — deal animation disabled.")


func _deck_start_screen_pos() -> Vector2:
	if _deck_sprite == null:
		return Vector2.ZERO
	return _deck_sprite.get_global_transform_with_canvas().origin


func play_deal_fx() -> Tween:
	if _card == null or _deck_sprite == null:
		return null

	var now := Time.get_ticks_msec()
	if now - _last_play_msec < 120:
		return null
	_last_play_msec = now

	if _tween != null and _tween.is_valid():
		_tween.kill()

	var start := _deck_start_screen_pos()
	_card.visible = true
	_card.modulate = Color(1, 1, 1, 1)
	_card.global_position = start

	var target := start + Vector2(0, slide_distance)
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(_card, "global_position", target, slide_seconds)
	_tween.tween_callback(_reset_card)
	return _tween


func _reset_card() -> void:
	if _card:
		_card.visible = false
