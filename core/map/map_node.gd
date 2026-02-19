class_name MapNode
extends Resource

enum Type {
	SAFE,
	ENEMY,
	ELITE,
	TREASURE,
	EVENT,
	BOSS
}

@export var type: Type = Type.SAFE
@export var coordinates: Vector2i # Kept for compatibility, but might be less relevant now
@export var visited: bool = false
@export var completed: bool = false

# New: For node connections
@export var connected_nodes: Array[MapNode] = []
@export var depth: int = 0

# Generic data dictionary for flexibility (e.g. specific Enemy resource, Event ID, Item)
@export var data: Dictionary = {}

func _init(p_type: Type = Type.SAFE, p_depth: int = 0) -> void:
	type = p_type
	depth = p_depth
