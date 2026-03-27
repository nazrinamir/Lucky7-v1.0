extends Node2D
class_name TweenManager

func slide_card_down(node: Node):
	if node == null:
		return

	var tween = create_tween()
	tween.tween_property(node, "position:y", node.position.y + -600, 0.3)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
