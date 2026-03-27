extends RefCounted
class_name MatchHistory

var events: Array = []


func add_event(event: Dictionary) -> void:
	events.append(event)


func clear() -> void:
	events.clear()


func get_events() -> Array:
	return events.duplicate(true)
