extends Area2D

signal deck_clicked

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		print("DECK CLICKED (Area2D)")
		emit_signal("deck_clicked")
