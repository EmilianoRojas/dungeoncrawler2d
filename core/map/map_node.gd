class_name MapNode
extends Resource

# GameSpec §2: Room types
enum Type {
	ENEMY,
	CHEST,
	EVENT,
	CAMP,
	BOSS,
	ELITE
}

# GameSpec §2: Floor-level modifiers (affect room behavior)
enum Modifier {
	NONE,
	TRACE, # Boss appears earlier than usual
	SUBMERGED, # Boss appears later than usual
	CATACOMB # Increased enemy spawn rate
}

@export var type: Type = Type.ENEMY
@export var depth: int = 0
@export var visited: bool = false
@export var completed: bool = false

# Up to 4 icons/modifiers per room (GameSpec §2)
@export var icons: Array[Modifier] = []

# Visibility control — sometimes icons are hidden (GameSpec §1)
@export var icons_hidden: bool = false

# Node tree connections
@export var connected_nodes: Array[MapNode] = []

# Generic data for room content (enemy template, event ID, loot table, etc.)
@export var data: Dictionary = {}

func _init(p_type: Type = Type.ENEMY, p_depth: int = 0) -> void:
	type = p_type
	depth = p_depth

func add_modifier(mod: Modifier) -> void:
	if icons.size() < 4 and not icons.has(mod):
		icons.append(mod)

func has_modifier(mod: Modifier) -> bool:
	return icons.has(mod)

func get_type_name() -> String:
	return Type.keys()[type].capitalize()
