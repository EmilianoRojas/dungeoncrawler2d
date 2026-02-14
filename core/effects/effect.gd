class_name Effect
extends Resource

@export var priority: int = 0 # Higher = executed earlier

# Called when an event is dispatched to the owner of this effect
# event_name: The name of the event (e.g. "before_damage", "turn_start")
# data: A Dictionary with context data (e.g. { "damage": 10, "target": ... })
func on_event(event_name: String, data: Dictionary) -> void:
	pass
