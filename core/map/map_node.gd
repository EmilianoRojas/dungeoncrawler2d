class_name MapNode
extends Resource

enum Type {
	SAFE,
	ENEMY,
	EVENT,
	BOSS
}

@export var type: Type = Type.SAFE
@export var coordinates: Vector2i
@export var visited: bool = false
# Generic data dictionary for flexibility (e.g. specific Enemy resource, Event ID, Item)
@export var data: Dictionary = {}

func _init(p_coords: Vector2i = Vector2i.ZERO, p_type: Type = Type.SAFE) -> void:
	coordinates = p_coords
	type = p_type
